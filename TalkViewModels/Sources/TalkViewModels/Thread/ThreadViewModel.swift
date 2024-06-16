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
import ChatCore
import ChatDTO
import OSLog

public final class ThreadViewModel: Identifiable, Hashable {
    public static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    // MARK: Stored Properties
    public var thread: Conversation
    public var replyMessage: Message?
    @Published public var dismiss = false
    public var exportMessagesViewModel: ExportMessagesViewModel = .init()
    public var unsentMessagesViewModel: ThreadUnsentMessagesViewModel = .init()
    public var uploadMessagesViewModel: ThreadUploadMessagesViewModel = .init()
    public var searchedMessagesViewModel: ThreadSearchMessagesViewModel = .init()
    public var selectedMessagesViewModel: ThreadSelectedMessagesViewModel = .init()
    public var unreadMentionsViewModel: ThreadUnreadMentionsViewModel = .init()
    public var participantsViewModel: ParticipantsViewModel = .init()
    public var attachmentsViewModel: AttachmentsViewModel = .init()
    public var mentionListPickerViewModel: MentionListPickerViewModel = .init()
    public var sendContainerViewModel: SendContainerViewModel = .init()
    public var audioRecoderVM: AudioRecordingViewModel = .init()
    public var scrollVM: ThreadScrollingViewModel = .init()
    public var historyVM: ThreadHistoryViewModel = .init()
    public var sendMessageViewModel: ThreadSendMessageViewModel = .init()
    public var participantsColorVM: ParticipantsColorViewModel = .init()
    public var threadPinMessageViewModel: ThreadPinMessageViewModel = .init()
    public var reactionViewModel: ThreadReactionViewModel = .init()
    public var seenVM: HistorySeenViewModel = .init()
    public var downloadFileManager: DownloadFileManager = .init()
    public var uploadFileManager: UploadFileManager = .init()
    public var avatarManager: ThreadAvatarManager = .init()
    public weak var threadsViewModel: ThreadsViewModel?
    public var readOnly = false
    private var cancelable: Set<AnyCancellable> = []
    public var signalMessageText: String?
    public var forwardMessage: Message?
    var model: AppSettingsModel = .init()
    public var canDownloadImages: Bool = false
    public var canDownloadFiles: Bool = false

    public weak var delegate: ThreadViewDelegate?

    // MARK: Computed Properties
    public var id: Int { threadId }
    public var threadId: Int { thread.id ?? 0 }
    public var isActiveThread: Bool { AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel.threadId == threadId }
    public var isSimulatedThared: Bool {
        AppState.shared.appStateNavigationModel.userToCreateThread != nil && thread.id == LocalId.emptyThread.rawValue
    }
    public static var maxAllowedWidth: CGFloat = ThreadViewModel.threadWidth - (38 + MessageRowSizes.avatarSize)
    public static var threadWidth: CGFloat = 0 {
        didSet {
            // 38 = Avatar width + tail width + leading padding + trailing padding
            maxAllowedWidth = min(400, ThreadViewModel.threadWidth - (38 + MessageRowSizes.avatarSize))
        }
    }

    // MARK: Initializer
    public init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.threadsViewModel = threadsViewModel
        self.thread = thread
        self.readOnly = readOnly
        setup()
    }

    public func setup() {
        seenVM.setup(viewModel: self)
        unreadMentionsViewModel.setup(viewModel: self)
        mentionListPickerViewModel.setup(viewModel: self)
        sendContainerViewModel.setup(viewModel: self)
        searchedMessagesViewModel.setup(viewModel: self)
        threadPinMessageViewModel.setup(viewModel: self)
        participantsViewModel.setup(viewModel: self)
        Task { @HistoryActor [weak self] in
            guard let self = self else { return }
            historyVM.setup(viewModel: self)
        }
        sendMessageViewModel.setup(viewModel: self)
        scrollVM.setup(viewModel: self)
        unsentMessagesViewModel.setup(viewModel: self)
        selectedMessagesViewModel.setup(viewModel: self)
        uploadMessagesViewModel.setup(viewModel: self)
        exportMessagesViewModel.setup(viewModel: self)
        reactionViewModel.setup(viewModel: self)
        attachmentsViewModel.setup(viewModel: self)
        downloadFileManager.setup(viewModel: self)
        uploadFileManager.setup(viewModel: self)
        avatarManager.setup(viewModel: self)
        registerNotifications()
        setAppSettingsModel()
    }

    public func updateConversation(_ conversation: Conversation) {
        self.thread.updateValues(conversation)
//        self.thread.animateObjectWillChange()
    }

    // MARK: Actions
    public func sendStartTyping(_ newValue: String) {
        if threadId == LocalId.emptyThread.rawValue { return }
        if newValue.isEmpty == false {
            ChatManager.activeInstance?.system.snedStartTyping(threadId: threadId)
        } else {
            ChatManager.activeInstance?.system.sendStopTyping()
        }
    }

    public func sendSignal(_ signalMessage: SignalMessageType) {
        ChatManager.activeInstance?.system.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    public func clearCacheFile(message: Message) {
        if let fileHashCode = message.fileMetaData?.fileHash {
            let path = message.isImage ? Routes.images.rawValue : Routes.files.rawValue
            let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(path)/\(fileHashCode)"
            ChatManager.activeInstance?.file.deleteCacheFile(URL(string: url)!)
            NotificationCenter.message.post(.init(name: .message, object: message))
        }
    }

    public func storeDropItems(_ items: [NSItemProvider]) {
        items.forEach { item in
            let name = item.suggestedName ?? ""
            let ext = item.registeredContentTypes.first?.preferredFilenameExtension ?? ""
            let iconName = ext.systemImageNameForFileExtension
            _ = item.loadDataRepresentation(for: .item) { data, _ in
                DispatchQueue.main.async {  [weak self] in
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
        case .lastMessageDeleted(let response), .lastMessageEdited(let response):
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
            Task {
                await onEditedMessage(response)
            }
        default:
            break
        }
    }

    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == threadId {
            dismiss = true
        }
    }

    private func onLeftThread(_ response: ChatResponse<User>) {
        if response.subjectId == threadId, response.result?.id == AppState.shared.user?.id {
            dismiss = true
        } else {
            thread.participantCount = (thread.participantCount ?? 0) - 1
        }
    }

    private func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == threadId {
            dismiss = true
        }
    }

    private func onUnreadCount(_ response: ChatResponse<UnreadCount>) {
        if threadId == response.result?.threadId {
            setUnreadCount(response.result?.unreadCount)
        }
    }

    private func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected && !isSimulatedThared {
            unreadMentionsViewModel.fetchAllUnreadMentions()
        }
    }

    private func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            setUnreadCount(thread.unreadCount)
        }
    }

    @HistoryActor
    private func onEditedMessage(_ response: ChatResponse<Message>) async {
        guard
            let editedMessage = response.result,
            var oldMessage = historyVM.sections.message(for: response.result?.id)?.message
        else { return }
        oldMessage.updateMessage(message: editedMessage)
        await MainActor.run {
            updateIfIsPinMessage(editedMessage: editedMessage)
        }
    }

    // MARK: Logs
    private func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }

    // MARK: Observers
    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
        exportMessagesViewModel.cancelAllObservers()
        unsentMessagesViewModel.cancelAllObservers()
        uploadMessagesViewModel.cancelAllObservers()
        searchedMessagesViewModel.cancelAllObservers()
        unreadMentionsViewModel.cancelAllObservers()
        participantsViewModel.cancelAllObservers()
        mentionListPickerViewModel.cancelAllObservers()
        sendContainerViewModel.cancelAllObservers()
        Task { @HistoryActor [weak self] in
            self?.historyVM.cancel()
        }
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
        Task { [weak self] in
            guard let self = self else { return }
            model = AppSettingsModel.restore()
            canDownloadImages = canDownloadImagesInConversation()
            canDownloadFiles = canDownloadFilesInConversation()
        }
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

    public func onDragged(translation: CGSize, startLocation: CGPoint) {
        scrollVM.cancelTask()
//        scrollVM.setProgramaticallyScrollingState(newState: false)
        scrollVM.scrollingUP = translation.height > 10
        let isSwipeEdge = Language.isRTL ? (startLocation.x > ThreadViewModel.threadWidth - 20) : startLocation.x < 20
        if isSwipeEdge, abs(translation.width) > 48 && translation.height < 12 {
            AppState.shared.objectsContainer.navVM.remove(threadId: threadId)
        }
    }

    public func getParticipantCount() -> String {
        let count = thread.participantCount ?? 0
        if thread.group == true, let participantsCount = count.localNumber(locale: Language.preferredLocale) {
            let localizedLabel = String(localized: "Thread.Toolbar.participants", bundle: Language.preferedBundle)
            return "\(participantsCount) \(localizedLabel)"
        } else {
            return ""
        }
    }

    deinit {
        log("deinit called in class ThreadViewModel: \(self.thread.title ?? "")")
    }
}
