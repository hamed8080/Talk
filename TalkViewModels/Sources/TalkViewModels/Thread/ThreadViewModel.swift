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
    public var topLoading = false
    public var bottomLoading = false
    public var canLoadMoreTop: Bool { hasNextTop && !topLoading }
    public var canLoadMoreBottom: Bool { !bottomLoading && sections.last?.messages.last?.id != thread.lastMessageVO?.id && hasNextBottom }
    public var sections: ContiguousArray<MessageSection> = .init()
    public var replyMessage: Message?
    @Published public var isInEditMode: Bool = false
    @Published public var dismiss = false

    public var sheetType: ThreadSheetType?
    public var selectedLocation: MKCoordinateRegion = .init()
    public var isFetchedServerFirstResponse: Bool = false
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
    public weak var threadsViewModel: ThreadsViewModel?
    public var readOnly = false
    public var canScrollToBottomOfTheList: Bool = false
    private var cancelable: Set<AnyCancellable> = []
    private var typingTimerStarted = false
    public var hasNextTop = true
    public var hasNextBottom = true
    public let count: Int = 50
    public var threadId: Int { thread.id ?? 0 }
    public var signalMessageText: String?
    public var isActiveThread: Bool { AppState.shared.navViewModel?.presentedThreadViewModel?.threadId == threadId }
    public var isAtBottomOfTheList: Bool = false    
    public var isProgramaticallyScroll: Bool = false
    public var scrollProxy: ScrollViewProxy?
    public var scrollingUP = false
    public weak var forwardMessage: Message?
    public var seenPublisher = PassthroughSubject<Message, Never>()
    var hasSentHistoryRequest = false
    var createThreadCompletion: (()-> Void)?
    private var topSliceId: Int = 0
    private var bottomSliceId: Int = 0
    public static var threadWidth: CGFloat = 0 {
        didSet {
            // 38 = Avatar width + tail width + leading padding + trailing padding
            maxAllowedWidth = min(600, ThreadViewModel.threadWidth - (38 + MessageRowViewModel.avatarSize))
        }
    }

    public static var maxAllowedWidth: CGFloat = ThreadViewModel.threadWidth - (38 + MessageRowViewModel.avatarSize)

    public var messageViewModels: ContiguousArray<MessageRowViewModel> = .init()
    var model: AppSettingsModel
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
        self.readOnly = readOnly
        self.thread = thread
        self.threadsViewModel = threadsViewModel
        self.participantsViewModel = ParticipantsViewModel(thread: thread)
        model = AppSettingsModel.restore()
        setupNotificationObservers()
        self.canDownloadImages = canDownloadImagesInConversation()
        self.canDownloadFiles = canDownloadFilesInConversation()
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
                if let self {
                    self.model = AppSettingsModel.restore()
                    self.canDownloadImages = self.canDownloadImagesInConversation()
                    self.canDownloadFiles = self.canDownloadFilesInConversation()
                }
            }
            .store(in: &cancelable)

        RequestsManager.shared.$cancelRequest
            .sink { [weak self] newValue in
                if let newValue {
                    self?.onCancelTimer(key: newValue)
                }
            }
            .store(in: &cancelable)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected, isFetchedServerFirstResponse == true, isActiveThread {
            // After connecting again get latest messages.
            tryFifthScenario(status: status)
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            startFetchingHistory()
        }

        if status == .connected {
            unreadMentionsViewModel.fetchAllUnreadMentions()
        }
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if threadId == response.subjectId, let message = response.result {
            thread.unreadCount = (thread.unreadCount ?? 0) + 1
            thread.time = response.result?.conversation?.time
            thread.lastMessageVO = response.result
            thread.lastSeenMessageId = response.result?.conversation?.lastSeenMessageId
            thread.lastSeenMessageTime = response.result?.conversation?.lastSeenMessageTime
            thread.lastSeenMessageNanos = response.result?.conversation?.lastSeenMessageNanos
            thread.lastMessage = response.result?.message

            appendMessagesAndSort([message])
            animateObjectWillChange()
            scrollToLastMessageIfLastMessageIsVisible(message)
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            setUnreadCount(thread.unreadCount)
            if let lastMessage = thread.lastMessageVO,
               let messageId = lastMessage.id,
               let sectionIndex = sectionIndexByMessageId(messageId),
               let index = messageIndex(messageId, in: sectionIndex) {
                sections[sectionIndex].messages[index] = lastMessage
            }
            animateObjectWillChange()
        }
    }

    public func onMessageAppear(_ message: Message) {
        if message.id == thread.lastMessageVO?.id, !isAtBottomOfTheList {
            isAtBottomOfTheList = true
            animateObjectWillChange()
        }
        /// We get next item in the list because when we are scrolling up the message is beneth NavigationView so we should get the next item to ensure we are in right position
        guard
            let sectionIndex = sectionIndexByMessageId(message),
            let messageIndex = messageIndex(message.id ?? -1, in: sectionIndex)
        else { return }
        let section = sections[sectionIndex]
        if scrollingUP, section.messages.indices.contains(messageIndex + 1) == true {
            let message = section.messages[messageIndex + 1]
            log("Scrolling Up with id:\(message.id ?? 0) uniqueId:\(message.uniqueId ?? "") text:\(message.message ?? "")")
        } else if !scrollingUP, section.messages.indices.contains(messageIndex - 1), section.messages.last?.id != message.id {
            let message = section.messages[messageIndex - 1]
            log("Scroling Down with id:\(message.id ?? 0) uniqueId:\(message.uniqueId ?? "") text:\(message.message ?? "")")
            reduceUnreadCountLocaly(message)
            seenPublisher.send(message)
        } else {
            // Last Item
            log("Last Item with id:\(message.id ?? 0) uniqueId:\(message.uniqueId ?? "") text:\(message.message ?? "")")
            reduceUnreadCountLocaly(message)
            seenPublisher.send(message)
        }

        if !isProgramaticallyScroll, isInTopSlice(message) {
            moreTop(sections.first?.messages.first?.time)
        }

        if !isProgramaticallyScroll, isInBottomSlice(message) {
            moreBottom(sections.last?.messages.last?.time?.advanced(by: 1))
        }
    }

    private func isInTopSlice(_ message: Message) -> Bool {
        return message.id ?? 0 <= topSliceId
    }

    private func isInBottomSlice(_ message: Message) -> Bool {
        return message.id ?? 0 >= bottomSliceId
    }

    public func onMessegeDisappear(_ message: Message) {
        if message.id == thread.lastMessageVO?.id, isAtBottomOfTheList {
            isAtBottomOfTheList = false
            animateObjectWillChange()
        }
    }

    public func onEditedMessage(_ response: ChatResponse<Message>) {
        guard
            let indices = indicesByMessageId(response.result?.id ?? -1),
            let editedMessage = response.result,
            sections.indices.contains(indices.sectionIndex),
            sections[indices.sectionIndex].messages.indices.contains(indices.messageIndex)
        else { return }
        let oldMessage = sections[indices.sectionIndex].messages[indices.messageIndex]
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

    public func appendMessagesAndSort(_ messages: [Message], isToTime: Bool = false) {
        guard messages.count > 0 else { return }
        messages.forEach { message in
            insertOrUpdate(message)
        }
        sort()
        topSliceId = sections.flatMap{$0.messages}.prefix(15).compactMap{$0.id}.last ?? 0
        bottomSliceId = sections.flatMap{$0.messages}.suffix(15).compactMap{$0.id}.first ?? 0
    }

    func insertOrUpdate(_ message: Message) {
        let indices = findIncicesBy(uniqueId: message.uniqueId ?? "", message.id ?? -1)
        if let indices = indices {
            sections[indices.sectionIndex].messages[indices.messageIndex].updateMessage(message: message)
        } else if message.threadId == threadId || message.conversation?.id == threadId {
            if let sectionIndex = sectionIndexByDate(message.time?.date ?? Date()) {
                sections[sectionIndex].messages.append(message)
            } else {
                sections.append(.init(date: message.time?.date ?? Date(), messages: [message]))
            }
        }
        /// Create if there is no viewModel inside messageViewModels array. It is essential for highlighting and more
        messageViewModel(for: message)
    }

    func indicesByMessageId(_ id: Int) -> (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        return (sectionIndex: sectionIndex, messageIndex: messageIndex)
    }

    func indicesByMessageUniqueId(_ uniqueId: String) -> (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let sectionIndex = sectionIndexByUniqueId(uniqueId),
            let messageIndex = messageIndex(uniqueId, in: sectionIndex)
        else { return nil }
        return (sectionIndex: sectionIndex, messageIndex: messageIndex)
    }

    func findIncicesBy(uniqueId: String?, _ id: Int?) -> (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let sectionIndex = sections.firstIndex(where: { $0.messages.contains(where: { $0.uniqueId == uniqueId || $0.id == id }) }),
            let messageIndex = sections[sectionIndex].messages.firstIndex(where: { $0.uniqueId == uniqueId || $0.id == id })
        else { return nil }
        return (sectionIndex: sectionIndex, messageIndex: messageIndex)
    }

    func sectionIndexByUniqueId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByUniqueId(message.uniqueId ?? "")
    }

    func sectionIndexByUniqueId(_ uniqueId: String) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.messages.contains(where: {$0.uniqueId == uniqueId }) })
    }

    func sectionIndexByMessageId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByMessageId(message.id ?? 0)
    }

    func sectionIndexByMessageId(_ id: Int) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.messages.contains(where: {$0.id == id }) })
    }

    func sectionIndexByDate(_ date: Date) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { Calendar.current.isDate(date, inSameDayAs: $0.date)})
    }

    public func messageIndex(_ messageId: Int, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].messages.firstIndex(where: { $0.id == messageId })
    }

    public func messageIndex(_ uniqueId: String, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].messages.firstIndex(where: { $0.uniqueId == uniqueId })
    }

    public func removeById(_ id: Int?) {
        guard let id = id, let indices = indicesByMessageId(id) else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
    }

    public func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
    }

    private func lastMessageSeenIndicies(isToTime: Bool) -> (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard isToTime, let lastSeenMessageId = thread.lastSeenMessageId else { return nil }
        return indicesByMessageId(lastSeenMessageId)
    }

    public func deleteMessages(_ messages: [Message], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        selectedMessagesViewModel.clearSelection()
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    public func onDeleteMessage(_ response: ChatResponse<Message>) {
        guard let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id,
              threadId == responseThreadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId, response.result?.id)
        else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
        if sections[indices.sectionIndex].messages.count == 0 {
            sections.remove(at: indices.sectionIndex)
        }
        animateObjectWillChange()
    }

    public func sort() {
        sections.indices.forEach { sectionIndex in
            sections[sectionIndex].messages.sort { m1, m2 in
                if m1 is UnreadMessageProtocol {
                    return false
                }
                if let t1 = m1.time, let t2 = m2.time {
                    return t1 < t2
                } else {
                    return false
                }
            }
        }
        sections.sort(by: {$0.date < $1.date})
    }

    public func isNextSameUser(message: Message) -> Bool {
        guard let indices = indicesByMessageId(message.id ?? -1) else { return false }
        let sectionIndex = indices.sectionIndex
        let currentMessage = sections[sectionIndex].messages[indices.messageIndex]
        let nextMessageInedex = indices.messageIndex + 1
        let isNextIndexExist = sections[sectionIndex].messages.indices.contains(nextMessageInedex)
        if isNextIndexExist {
            let nextMessage = sections[sectionIndex].messages[nextMessageInedex]
            return currentMessage.participant?.id ?? 0 == nextMessage.participant?.id ?? -1
        }
        return false
    }

    public func clearCacheFile(message: Message) {
        if let metadata = message.metadata?.data(using: .utf8), let fileHashCode = try? JSONDecoder().decode(FileMetaData.self, from: metadata).fileHash {
            let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(Routes.files.rawValue)/\(fileHashCode)"
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

    @discardableResult
    public func messageViewModel(for message: Message) -> MessageRowViewModel {
        /// For unsent messages, uniqueId has value but message.id is always nil, so we have to check both to make sure we get the right viewModel, unless it will lead to an overwrite on a message and it will break down all the things.
        if let viewModel = messageViewModels.first(where: {  $0.message.uniqueId == message.uniqueId && $0.message.id == message.id }){
            return viewModel
        } else {
            let newViewModel = MessageRowViewModel(message: message, viewModel: self)
            messageViewModels.append(newViewModel)
            return newViewModel
        }
    }

    private func onCancelTimer(key: String) {
        if topLoading || bottomLoading {
            topLoading = false
            bottomLoading = false
            animateObjectWillChange()
        }
    }

    /// We reduce it locally to keep the UI Sync and user feels it really read the message.
    /// However, we only send seen request with debouncing
    private func reduceUnreadCountLocaly(_ message: Message?) {
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

    public func disableExcessiveLoading() {
        isProgramaticallyScroll = true
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.isProgramaticallyScroll = false
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == threadId {
            dismiss = true
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
