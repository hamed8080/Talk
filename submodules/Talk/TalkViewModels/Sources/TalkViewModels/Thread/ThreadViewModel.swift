//
//  ThreadViewswift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import TalkModels
import Logger

@MainActor
public final class ThreadViewModel: ObservableObject {
    public static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.id == lhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: Stored Properties
    public var thread: Conversation
    public var replyMessage: Message?
    public var exportMessagesViewModel: ExportMessagesViewModel = .init()
    public var unsentMessagesViewModel: ThreadUnsentMessagesViewModel = .init()
    public var searchedMessagesViewModel: ThreadSearchMessagesViewModel = .init()
    public var selectedMessagesViewModel: ThreadSelectedMessagesViewModel = .init()
    public var unreadMentionsViewModel: ThreadUnreadMentionsViewModel = .init()
    public var participantsViewModel: ParticipantsViewModel = .init()
    public var attachmentsViewModel: AttachmentsViewModel = .init()
    public var mentionListPickerViewModel: MentionListPickerViewModel = .init()
    public var sendContainerViewModel: SendContainerViewModel = .init()
    public var audioRecoderVM: AudioRecordingViewModel = .init()
    public var scrollVM: ThreadScrollingViewModel = .init()
    public lazy var historyVM: ThreadHistoryViewModel = { .init(thread: thread) }()
    public var sendMessageViewModel: ThreadSendMessageViewModel = .init()
    public var participantsColorVM: ParticipantsColorViewModel = .init()
    public var threadPinMessageViewModel: ThreadPinMessageViewModel = .init()
    public var reactionViewModel: ThreadReactionViewModel = .init()
    public var seenVM: HistorySeenViewModel = .init()
    public var avatarManager: ThreadAvatarManager = .init()
    public var conversationSubtitle: ConversationSubtitleViewModel = .init()
    private lazy var signalEmitter: ThreadSystemEventEmiter = { ThreadSystemEventEmiter(threadId: thread.id ?? -1) }()
    public var readOnly = false
    private var cancelable: Set<AnyCancellable> = []
    public var signalMessageText: String?
    public var model: AppSettingsModel = .init()
    public var canDownloadImages: Bool = false
    public var canDownloadFiles: Bool = false

    public weak var delegate: ThreadViewDelegate?
    
    /// Save P2P participant unless destroy the thread
    public var participant: Participant?

    // MARK: Computed Properties
    public var id: Int
    public var isActiveThread: Bool { AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.threadId == id }
    public var isSimulatedThared: Bool {
        AppState.shared.objectsContainer.navVM.navigationProperties.userToCreateThread != nil && thread.id == LocalId.emptyThread.rawValue
    }
    nonisolated(unsafe) public static var maxAllowedWidth: CGFloat = ThreadViewModel.threadWidth
    nonisolated(unsafe) public static var maxAllowedWidthIsMe: CGFloat = ThreadViewModel.threadWidth
    nonisolated(unsafe) public static var threadWidth: CGFloat = 0 {
        didSet {
            setMaxAllowedWidth()
            setMaxAllowedWidthIsMe()
        }
    }
    
    nonisolated static func setMaxAllowedWidth() {
        
        let paddingsAndAvatar = (ConstantSizes.beforeContainerLeading
        + ConstantSizes.messageAvatarBeforeLeading
        + ConstantSizes.messageAvatarViewSize
        + ConstantSizes.messageAvatarAfterTrailing
        + ConstantSizes.messageContainerStackViewMargin
        + ConstantSizes.messageContainerStackViewMargin
        + ConstantSizes.messagebaseCellTrailingSpaceForShowingMoveToBottom
        + ConstantSizes.vStackButtonsLeadingMargin
        )
        
        maxAllowedWidth = min(400, ThreadViewModel.threadWidth - paddingsAndAvatar)
    }
    
    nonisolated static func setMaxAllowedWidthIsMe() {
        
        let paddingsAndAvatar = (ConstantSizes.beforeContainerLeading
        + ConstantSizes.messageContainerStackViewMargin
        + ConstantSizes.messageContainerStackViewMargin
        + ConstantSizes.messagebaseCellTrailingSpaceForShowingMoveToBottom
        + ConstantSizes.vStackButtonsLeadingMargin
        )
        
        maxAllowedWidthIsMe = min(400, ThreadViewModel.threadWidth - paddingsAndAvatar)
    }

    // MARK: Initializer
    public init(thread: Conversation, readOnly: Bool = false) {
        self.id = thread.id ?? -1
        self.thread = thread
        self.readOnly = readOnly
        setup()
        print("created class ThreadViewModel: \(thread.computedTitle)")
    }

    private func setup() {
        participant = AppState.shared.objectsContainer.navVM.navigationProperties.userToCreateThread
        seenVM.setup(viewModel: self)
        unreadMentionsViewModel.setup(viewModel: self)
        mentionListPickerViewModel.setup(viewModel: self)
        sendContainerViewModel.setup(viewModel: self)
        searchedMessagesViewModel.setup(viewModel: self)
        threadPinMessageViewModel.setup(viewModel: self)
        participantsViewModel.setup(viewModel: self)
        historyVM.viewModel = self
        sendMessageViewModel.setup(viewModel: self)
        scrollVM.setup(viewModel: self)
        unsentMessagesViewModel.setup(viewModel: self)
        selectedMessagesViewModel.setup(viewModel: self)
        exportMessagesViewModel.setup(viewModel: self)
        reactionViewModel.setup(viewModel: self)
        attachmentsViewModel.setup(viewModel: self)
        avatarManager.setup(viewModel: self)
        conversationSubtitle.setup(viewModel: self)
        registerNotifications()
        setAppSettingsModel()
    }

    public func updateConversation(_ conversation: Conversation) {
        self.thread.updateValues(conversation)
//        self.thread.animateObjectWillChange()
    }

    // MARK: Actions

    public func clearCacheFile(message: Message) {
        if let fileHashCode = message.fileMetaData?.fileHash {
            let spec = AppState.shared.spec
            let fileServer = spec.server.file
            let address = "\(spec.server.sso)/\(spec.paths.sso.token)"
            Task { @ChatGlobalActor in
                let path = message.isImage ? spec.paths.podspace.download.images : spec.paths.podspace.download.files
                let url = "\(fileServer)\(path)/\(fileHashCode)"
                ChatManager.activeInstance?.file.deleteCacheFile(URL(string: url)!)
                try? ChatManager.activeInstance?.file.deleteResumableFile(hashCode: fileHashCode)
            }
            NotificationCenter.message.post(.init(name: .message, object: message))
        }
    }

    public func storeDropItems(_ items: [NSItemProvider]) {
        items.forEach { item in
            let name = item.suggestedName ?? ""
            let ext = item.registeredContentTypes.first?.preferredFilenameExtension ?? ""
            let iconName = ext.systemImageNameForFileExtension
            _ = item.loadDataRepresentation(for: .item) { data, _ in
                DispatchQueue.main.async { [weak self] in
                    let item = DropItem(data: data, name: name, iconName: iconName, ext: ext)
                    self?.attachmentsViewModel.append(attachments: [.init(type: .drop, request: item)])
                }
            }
        }
    }

    public func setupRecording() {
        audioRecoderVM.threadViewModel = self
        audioRecoderVM.toggle()
    }

    public func setupExportMessage(startDate: Date, endDate: Date) {
        exportMessagesViewModel.exportChats(startDate: startDate, endDate: endDate)
    }

    /// It will be called only by updateUnreadCount
    public func updateUnreadCount(_ newCount: Int?) {
        thread.unreadCount = newCount
        delegate?.onUnreadCountChanged()
    }

    /// This method prevents to update unread count if the local unread count is smaller than server unread count.
    private func setUnreadCount(_ newCount: Int?) {
        if newCount ?? 0 <= thread.unreadCount ?? 0 {
            thread.unreadCount = newCount
        }
    }

    public func moveToFirstUnreadMessage() async {
        if let unreadMessage = unreadMentionsViewModel.unreadMentions.first, let time = unreadMessage.time {
            await historyVM.moveToTime(time, unreadMessage.id ?? -1, highlight: true, moveToBottom: true)
            unreadMentionsViewModel.setAsRead(id: unreadMessage.id)
        }
    }

    private func updateIfIsPinMessage(editedMessage: Message) {
        if editedMessage.id == thread.pinMessage?.id {
            thread.pinMessage = PinMessage(message: editedMessage)
        }
    }

    // MARK: Events
    private func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .lastMessageDeleted(let response):
            if let thread = response.result {
                onLastMessageDeleted(thread)
            }
        case.lastMessageEdited(let response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }        
        case .deleted(let response):
            onDeleteThread(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .edited(let response):
            Task { [weak self] in
                await self?.onEditedMessage(response)
            }
        default:
            break
        }
    }

    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == id {
        }
    }

    private func onLeftThread(_ response: ChatResponse<User>) {
        if response.subjectId == id, response.result?.id == AppState.shared.user?.id {
        } else {
            thread.participantCount = (thread.participantCount ?? 0) - 1
        }
    }

    private func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == id {
        }
    }

    private func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected && !isSimulatedThared {
            unreadMentionsViewModel.fetchAllUnreadMentions()
        }
    }
    
    private func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == id {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            setUnreadCount(thread.unreadCount)
        }
    }
    
    private func onLastMessageDeleted(_ thread: Conversation) {
        if thread.id == id {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            setUnreadCount(thread.unreadCount)
        }
    }
    
    private func onEditedMessage(_ response: ChatResponse<Message>) async {
        guard
            let editedMessage = response.result,
            var oldMessage = await historyVM.sections.message(for: response.result?.id)?.message
        else { return }
        oldMessage.updateMessage(message: editedMessage)
        updateIfIsPinMessage(editedMessage: editedMessage)
    }

    // MARK: Logs
    private func log(_ string: String) {
        Logger.log(title: "ThreadViewModel", message: string)
    }

    // MARK: Observers
    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
        exportMessagesViewModel.cancelAllObservers()
        unsentMessagesViewModel.cancelAllObservers()
        searchedMessagesViewModel.cancelAllObservers()
        unreadMentionsViewModel.cancelAllObservers()
        participantsViewModel.cancelAllObservers()
        mentionListPickerViewModel.cancelAllObservers()
        historyVM.cancelAllObservers()
        threadPinMessageViewModel.cancelAllObservers()
//        scrollVM.cancelAllObservers()
    }

    private func registerNotifications() {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)

        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)

        NotificationCenter.appSettingsModel.publisher(for: .appSettingsModel)
            .sink { [weak self] _ in
                self?.setAppSettingsModel()
            }
            .store(in: &cancelable)

        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
    }

    // MARK: Setting Observer
    private func setAppSettingsModel() {
        model = AppSettingsModel.restore()
        canDownloadImages = canDownloadImagesInConversation()
        canDownloadFiles = canDownloadFilesInConversation()
    }

    private func canDownloadImagesInConversation() -> Bool {
        let type = thread.type
        let globalDownload = model.automaticDownloadSettings.downloadImages
        if type == .channel || type == .channelGroup, globalDownload && model.automaticDownloadSettings.channel.downloadImages {
            return true
        } else if (type == .ownerGroup || type == .publicGroup) && thread.group == true, globalDownload && model.automaticDownloadSettings.group.downloadImages {
            return true
        } else if type == .normal || (thread.group == false || thread.group == nil), globalDownload && model.automaticDownloadSettings.privateChat.downloadImages {
            return true
        } else {
            return false
        }
    }

    private func canDownloadFilesInConversation() -> Bool {
        let type = thread.type
        let globalDownload = model.automaticDownloadSettings.downloadFiles
        if type?.isChannelType == true, globalDownload && model.automaticDownloadSettings.channel.downloadFiles {
            return true
        } else if (type == .ownerGroup || type == .publicGroup) && thread.group == true, globalDownload && model.automaticDownloadSettings.group.downloadImages {
            return true
        } else if type == .normal || (thread.group == false || thread.group == nil), globalDownload && model.automaticDownloadSettings.privateChat.downloadFiles {
            return true
        } else {
            return false
        }
    }

    public func onConversationClosed() {
        delegate?.onConversationClosed()
    }
   
    deinit {
        let title = thread.title ?? ""
#if DEBUG
        print("deinit called in class ThreadViewModel: \(title)")
#endif
    }
}

// MARK: Signal messasges

public extension ThreadViewModel {
    
    func sendStartTyping(_ newValue: String) {
        if id == LocalId.emptyThread.rawValue || id == 0 || thread.group == true { return }
        if newValue.isEmpty == false {
            signalEmitter.sendTyping()
        } else {
            signalEmitter.stopTyping()
        }
    }
    
    func cancelTypingSignal() {
        signalEmitter.stopTyping()
    }
    
    func sendSignal(_ signalMessage: SignalMessageType) {
        if id == LocalId.emptyThread.rawValue || id == 0 || thread.group == true { return }
        signalEmitter.send(smt: signalMessage)
    }
    
    func cancelSignal() {
        signalEmitter.stopSignal()
    }
}
