//
//  ThreadViewswift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import MapKit
import Photos
import ChatModels
import TalkModels
import ChatCore
import ChatDTO
import SwiftUI
import OSLog

public struct MessageSection: Identifiable, Hashable, Equatable {
    public var id: Date { date }
    public let date: Date
    public var messages: ContiguousArray<Message>

    public init(date: Date, messages: ContiguousArray<Message>) {
        self.date = date
        self.messages = messages
    }
}

public final class ThreadViewModel: ObservableObject, Identifiable, Hashable {
    public static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    public var thread: Conversation
    public var centerLoading = false    
    public var replyMessage: Message?
    @Published public var isInEditMode: Bool = false
    @Published public var dismiss = false
    public var sheetType: ThreadSheetType?
    public var selectedLocation: MKCoordinateRegion = .init()    
    public var exportMessagesVM: ExportMessagesViewModelProtocol?
    public var unssetMessagesViewModel: ThreadUnsentMessagesViewModel
    public var uploadMessagesViewModel: ThreadUploadMessagesViewModel
    public var searchedMessagesViewModel: ThreadSearchMessagesViewModel
    public var selectedMessagesViewModel: ThreadSelectedMessagesViewModel
    public var unreadMentionsViewModel: ThreadUnreadMentionsViewModel
    public var participantsViewModel: ParticipantsViewModel
    public var attachmentsViewModel: AttachmentsViewModel = .init()
    public var mentionListPickerViewModel: MentionListPickerViewModel
    public var sendContainerViewModel: SendContainerViewModel
    public var audioRecoderVM: AudioRecordingViewModel = .init()
    public var scrollVM: ThreadScrollingViewModel
    public var historyVM: ThreadHistoryViewModel
    public weak var threadsViewModel: ThreadsViewModel?
    public var participantsColorVM: ParticipantsColorViewModel = .init()
    public var readOnly = false
    private var cancelable: Set<AnyCancellable> = []
    private var typingTimerStarted = false
    public var threadId: Int { thread.id ?? 0 }
    public var signalMessageText: String?
    public var isActiveThread: Bool { AppState.shared.navViewModel?.presentedThreadViewModel?.threadId == threadId }    
    public weak var forwardMessage: Message?
    public var seenPublisher = PassthroughSubject<Message, Never>()
    var createThreadCompletion: (()-> Void)?    
    public static var threadWidth: CGFloat = 0 {
        didSet {
            // 38 = Avatar width + tail width + leading padding + trailing padding
            maxAllowedWidth = min(400, ThreadViewModel.threadWidth - (38 + MessageRowViewModel.avatarSize))
        }
    }

    public static var maxAllowedWidth: CGFloat = ThreadViewModel.threadWidth - (38 + MessageRowViewModel.avatarSize)
    var model: AppSettingsModel = .init()
    public var canDownloadImages: Bool = false
    public var canDownloadFiles: Bool = false

    public init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.unssetMessagesViewModel = .init(thread: thread)
        self.uploadMessagesViewModel = .init(thread: thread)
        self.unreadMentionsViewModel = .init(thread: thread)
        self.mentionListPickerViewModel = .init(thread: thread)
        self.sendContainerViewModel = .init(thread: thread)
        self.searchedMessagesViewModel = .init(threadId: thread.id ?? -1)
        self.selectedMessagesViewModel = .init()
        self.scrollVM = .init()
        self.historyVM = .init()
        self.readOnly = readOnly
        self.thread = thread
        self.threadsViewModel = threadsViewModel
        self.participantsViewModel = ParticipantsViewModel(thread: thread)
        scrollVM.threadVM = self
        historyVM.threadViewModel = self
        setupNotificationObservers()
        setAppSettingsModel()
        selectedMessagesViewModel.threadVM = self
        sendContainerViewModel.threadVM = self
    }

    private func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink { [weak self] event in
                self?.onChatEvent(event)
            }
            .store(in: &cancelable)
        seenPublisher
            .filter{ [weak self] in $0.id ?? -1 >= self?.thread.lastSeenMessageId ?? 0 }
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.sendSeen(for: newValue)
            }
            .store(in: &cancelable)

        NotificationCenter.default.publisher(for: .appSettingsModel)
            .sink { [weak self] _ in
                self?.setAppSettingsModel()
            }
            .store(in: &cancelable)
    }

    private func setAppSettingsModel() {
        Task {
            model = AppSettingsModel.restore()
            canDownloadImages = canDownloadImagesInConversation()
            canDownloadFiles = canDownloadFilesInConversation()
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected {
            unreadMentionsViewModel.fetchAllUnreadMentions()
        }
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if threadId == response.subjectId, let message = response.result {
            historyVM.appendMessagesAndSort([message])
            historyVM.animateObjectWillChange()
            scrollVM.scrollToLastMessageIfLastMessageIsVisible(message)
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            setUnreadCount(thread.unreadCount)
            animateObjectWillChange()
        }
    }

    public func onEditedMessage(_ response: ChatResponse<Message>) {
        guard
            let editedMessage = response.result,
            let oldMessage = historyVM.message(for: response.result?.id)?.message
        else { return }
        oldMessage.updateMessage(message: editedMessage)
        updateIfIsPinMessage(editedMessage: editedMessage)
    }

    func updateIfIsPinMessage(editedMessage: Message) {
        if editedMessage.id == thread.pinMessage?.id {
            thread.pinMessage = PinMessage(message: editedMessage)
        }
    }

    public func sendStartTyping(_ newValue: String) {
        if threadId == LocalId.emptyThread.rawValue { return }
        if newValue.isEmpty == false {
            ChatManager.activeInstance?.system.snedStartTyping(threadId: threadId)
        } else {
            ChatManager.activeInstance?.system.sendStopTyping()
        }
    }

    public func sendSeen(for message: Message) {
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        if let messageId = message.id, let lastMsgId = thread.lastSeenMessageId, messageId > lastMsgId, !isMe {
            thread.lastSeenMessageId = messageId
            log("send seen for message:\(message.messageTitle) with id:\(messageId)")
            ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
        }
    }

    public func sendSignal(_ signalMessage: SignalMessageType) {
        ChatManager.activeInstance?.system.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    public func isNextSameUser(message: Message) async -> Bool {
        guard let tuples = historyVM.message(for: message.id) else { return false }
        let sectionIndex = tuples.sectionIndex
        let currentMessage = tuples.message
        let nextMessageInedex = tuples.messageIndex + 1
        let isNextIndexExist = historyVM.sections[sectionIndex].messages.indices.contains(nextMessageInedex)
        if isNextIndexExist == true {
            let nextMessage = historyVM.sections[sectionIndex].messages[nextMessageInedex]
            return currentMessage.participant?.id ?? 0 == nextMessage.participant?.id ?? -1
        }
        return false
    }

    public func isFirstMessageOfTheUser(_ message: Message) async -> Bool {
        guard let tuples = historyVM.message(for: message.id) else { return false }
        let sectionIndex = tuples.sectionIndex
        let previousIndex = tuples.messageIndex - 1
        let isPreviousIndexExist = historyVM.sections[sectionIndex].messages.indices.contains(previousIndex)
        if isPreviousIndexExist {
            let prevMessage = historyVM.sections[sectionIndex].messages[previousIndex]
            return prevMessage.participant?.id != message.participant?.id
        }
        return true
    }

    public func clearCacheFile(message: Message) {
        if let fileHashCode = message.fileMetaData?.fileHash {
            let path = message.isImage ? Routes.images.rawValue : Routes.files.rawValue
            let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(path)/\(fileHashCode)"
            ChatManager.activeInstance?.file.deleteCacheFile(URL(string: url)!)
            NotificationCenter.default.post(.init(name: .message, object: message))
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
                    self?.animateObjectWillChange()
                }
            }
        }
    }

    public func onUnreadCount(_ response: ChatResponse<UnreadCount>) {
        if threadId == response.result?.threadId {
            setUnreadCount(response.result?.unreadCount)
            animateObjectWillChange()
        }
    }

    public func setupRecording() {
        audioRecoderVM.threadViewModel = self
        audioRecoderVM.toggle()
        animateObjectWillChange()
    }

    public func setupExportMessage(startDate: Date, endDate: Date) {
        if exportMessagesVM == nil {
            exportMessagesVM = ExportMessagesViewModel()
            exportMessagesVM?.thread = thread
            (exportMessagesVM as? ExportMessagesViewModel)?.objectWillChange
                .sink { [weak self] in
                    self?.sheetType = .exportMessagesFile
                    self?.animateObjectWillChange()
                }
                .store(in: &cancelable)
        }
        exportMessagesVM?.exportChats(startDate: startDate, endDate: endDate)
        animateObjectWillChange()
    }

    /// We reduce it locally to keep the UI Sync and user feels it really read the message.
    /// However, we only send seen request with debouncing
    func reduceUnreadCountLocaly(_ message: Message?) {
        let messageId = message?.id ?? -1
        let beforeUnreadCount = thread.unreadCount ?? -1
        if beforeUnreadCount > 0, messageId > thread.lastSeenMessageId ?? 0 {
            log("Reduced unread count before is: \(beforeUnreadCount) locally with id:\(messageId) uniqueId:\(message?.uniqueId ?? "") text:\(message?.message ?? "")")
            let newUnreadCount = beforeUnreadCount - 1
            thread.unreadCount = newUnreadCount
            log("Reduced unread count after in thread object is: \(thread.unreadCount ?? 0) locally with id:\(messageId) uniqueId:\(message?.uniqueId ?? "") text:\(message?.message ?? "")")
            if let index = threadsViewModel?.threads.firstIndex(where: {$0.id == threadId}) {
                log("Reduced unread count before in threadsViewModel object is: \(threadsViewModel?.threads[index].unreadCount ?? 0) locally with id:\(messageId) uniqueId:\(message?.uniqueId ?? "") text:\(message?.message ?? "")")
                threadsViewModel?.threads[index].unreadCount = newUnreadCount
                log("Reduced unread count after in threadsViewModel object is: \(threadsViewModel?.threads[index].unreadCount ?? 0) locally with id:\(messageId) uniqueId:\(message?.uniqueId ?? "") text:\(message?.message ?? "")")
            }
            threadsViewModel?.animateObjectWillChange()
            animateObjectWillChange()
            log("Reduced unread count is: \(newUnreadCount) locally with id:\(messageId) uniqueId:\(message?.uniqueId ?? "") text:\(message?.message ?? "")")
        }

        /// We do this to remove number 1 as fast as the user scrolls to the last Message in the thread
        /// If we remove these lines it will work, however, we should wait for the server's response to remove the number 1 unread count when the user scrolls fast.
        if thread.unreadCount == 1, messageId == thread.lastMessageVO?.id {
            if let index = threadsViewModel?.threads.firstIndex(where: {$0.id == threadId}) {
                log("Reduced unread count before in threadsViewModel object is: \(threadsViewModel?.threads[index].unreadCount ?? 0) locally with id:\(messageId) uniqueId:\(message?.uniqueId ?? "") text:\(message?.message ?? "")")
                threadsViewModel?.threads[index].unreadCount = 0
                threadsViewModel?.animateObjectWillChange()
            }
            animateObjectWillChange()
        }
    }

    /// This method prevents to update unread count if the local unread count is smaller than server unread count.
    public func setUnreadCount(_ newCount: Int?) {
        if newCount ?? 0 <= thread.unreadCount ?? 0 {
            thread.unreadCount = newCount
            animateObjectWillChange()
        }
    }

    func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == threadId {
            dismiss = true
        }
    }

    func onLeftThread(_ response: ChatResponse<User>) {
        if response.subjectId == threadId, response.result?.id == AppState.shared.user?.id {
            dismiss = true
        } else {
            thread.participantCount = (thread.participantCount ?? 0) - 1
            animateObjectWillChange()
        }
    }
    
    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == threadId {
            dismiss = true
        }
    }

   public func moveToFirstUnreadMessage() {
        if let unreadMessage = unreadMentionsViewModel.unreadMentions.first, let time = unreadMessage.time {
            historyVM.moveToTime(time, unreadMessage.id ?? -1, highlight: true)
            unreadMentionsViewModel.setAsRead(id: unreadMessage.id)
            if unreadMentionsViewModel.unreadMentions.count == 0 {
                thread.mentioned = false
                thread.animateObjectWillChange()
                animateObjectWillChange()
            }
        }
    }

    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }

    deinit {
        log("deinit called in class ThreadViewModel: \(self.thread.title ?? "")")
    }
}
