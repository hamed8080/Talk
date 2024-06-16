//
//  ThreadsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import TalkModels
import TalkExtensions
import OSLog
import Logger

public final class ThreadsViewModel: ObservableObject {
    public var threads: ContiguousArray<Conversation> = []
    @Published private(set) var tagViewModel = TagsViewModel()
    @Published public var activeCallThreads: [CallToJoin] = []
    @Published public var sheetType: ThreadsSheetType?
    public var cancelable: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public var selectedThraed: Conversation?
    private var avatarsVM: [String :ImageLoaderViewModel] = [:]
    public var serverSortedPins: [Int] = []
    public var shimmerViewModel = ShimmerViewModel(delayToHide: 0, repeatInterval: 0.5)
    public var threadEventModels: [ThreadEventViewModel] = []
    private var cache: Bool = true
    var isInCacheMode = false
    private var isSilentClear = false
    @MainActor public private(set) var lazyList = LazyListViewModel()
    private let participantsCountManager = ParticipantsCountManager()

    internal var objectId = UUID().uuidString
    internal let GET_THREADS_KEY: String
    internal let CHANNEL_TO_KEY: String
    internal let GET_NOT_ACTIVE_THREADS_KEY: String
    internal let LEAVE_KEY: String

    public init() {
        GET_THREADS_KEY = "GET-THREADS-\(objectId)"
        CHANNEL_TO_KEY = "CHANGE-TO-PUBLIC-\(objectId)"
        GET_NOT_ACTIVE_THREADS_KEY = "GET-NOT-ACTIVE-THREADS-\(objectId)"
        LEAVE_KEY = "LEAVE"
        Task {
            await setupObservers()
        }
    }

    @MainActor
    func onCreate(_ response: ChatResponse<Conversation>) async {
        lazyList.setLoading(false)
        if let thread = response.result {
            await appendThreads(threads: [thread])
            await asyncAnimateObjectWillChange()
        }
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = firstIndex(message.conversation?.id) {
            var thread = threads[index]
            let isMe = response.result?.participant?.id == AppState.shared.user?.id
            if !isMe {
                thread.unreadCount = (threads[index].unreadCount ?? 0) + 1
            } else if isMe {
                thread.unreadCount = 0
            }
            thread.time = message.time
            thread.lastMessageVO = message.toLastMessageVO

            /*
             We have to set it, because in server chat response when we send a message Message.Conversation.lastSeenMessageId / Message.Conversation.lastSeenMessageTime / Message.Conversation.lastSeenMessageNanos are wrong.
             Although in message object Message.id / Message.time / Message.timeNanos are right.
             We only do this for ourselves, because the only person who can change these values is ourselves.
            */
            if isMe {
                thread.lastSeenMessageId = message.id
                thread.lastSeenMessageTime = message.time
                thread.lastSeenMessageNanos = message.timeNanos
            }
            thread.lastMessage = response.result?.message
            /* We only set the mentioned to "true" because if the user sends multiple
             messages inside a thread but one message has been mentioned.
             The list will set it to false which is wrong.
             */
            if response.result?.mentioned == true {
                thread.mentioned = true
            }
            threads[index] = thread
            if thread.pin == false {
                sort()
            }
            animateObjectWillChange()
        }
        getNotActiveThreads(response.result?.conversation)
    }

    func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = firstIndex(response.result?.id)  {
            threads[index].type = .publicGroup
            animateObjectWillChange()
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if firstSuccessResponse == false, status == .connected {
           await refresh()
        } else if status == .connected, firstSuccessResponse == true {
            // After connecting again
            // We should call this method because if the token expire all the data inside InMemory Cache of the SDK is invalid
            await refresh()
        } else if status == .disconnected && !firstSuccessResponse {
            // To get the cached version of the threads in SQLITE.
            await getThreads()
        }
    }

    @MainActor
    public func getThreads() async {
        if !firstSuccessResponse {
            shimmerViewModel.show()
        }
        lazyList.setLoading(true)
        let req = ThreadsRequest(count: lazyList.count, offset: lazyList.offset, cache: cache)
        RequestsManager.shared.append(prepend: GET_THREADS_KEY, value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    @MainActor
    public func loadMore(id: Int?) async {
        if await !lazyList.canLoadMore(id: id) { return }
        lazyList.prepareForLoadMore()
        await getThreads()
    }

    public func onThreads(_ response: ChatResponse<[Conversation]>) async {
        if isSilentClear {
            threads.removeAll()
            isSilentClear = false
        }
        let threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil})
        let pinThreads = response.result?.filter({$0.pin == true})
        let hasAnyResults = response.result?.count ?? 0 > 0

        /// It only sets sorted pins once because if we have 5 pins, they are in the first response. So when the user scrolls down the list will not be destroyed every time.
        if let serverSortedPinIds = pinThreads?.compactMap({$0.id}), serverSortedPins.isEmpty {
            serverSortedPins.removeAll()
            serverSortedPins.append(contentsOf: serverSortedPinIds)
        }
        await appendThreads(threads: threads ?? [])
        updatePresentedViewModels(response.result ?? [])
        await MainActor.run {
            if hasAnyResults {
                lazyList.setHasNext(response.hasNext)
                firstSuccessResponse = true
            }
            lazyList.setLoading(false)

            if firstSuccessResponse {
                shimmerViewModel.hide()
            }
            lazyList.setThreasholdIds(ids: self.threads.suffix(5).compactMap{$0.id})
            objectWillChange.send()
        }
    }

    /// After connect and reconnect all the threads will be removed from the array
    /// So the ThreadViewModel which contains this thread object have different refrence than what's inside the array
    private func updatePresentedViewModels(_ conversations: [Conversation]) {
        conversations.forEach { conversation in
            AppState.shared.objectsContainer.navVM.updateConversationInViewModel(conversation)
        }
    }

    public func onNotActiveThreads(_ response: ChatResponse<[Conversation]>) async {
        if let threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil}) {
            await appendThreads(threads: threads)
            await asyncAnimateObjectWillChange()
        }
    }

    public func refresh() async {
        cache = false
        await silenClear()
        await getThreads()
        cache = true
    }

    /// Create a thread and send a message without adding a contact.
    @MainActor
    public func fastMessage(_ invitee: Invitee, _ message: String) async {
        let messageREQ = CreateThreadMessage(text: message, messageType: .text)
        let req = CreateThreadWithMessage(invitees: [invitee], title: "", type: StrictThreadTypeCreation.p2p.threadType, message: messageREQ)
        ChatManager.activeInstance?.conversation.create(req)
        lazyList.setLoading(true)
    }

    public func searchInsideAllThreads(text _: String) {
        // not implemented yet
        //        ChatManager.activeInstance?.
    }

    public func makeThreadPublic(_ thread: Conversation) {
        guard let threadId = thread.id, let type = thread.type else { return }
        let req = ChangeThreadTypeRequest(threadId: threadId, type: type.publicType, uniqueName: UUID().uuidString)
        RequestsManager.shared.append(prepend: CHANNEL_TO_KEY, value: req)
        ChatManager.activeInstance?.conversation.changeType(req)
    }

    public func makeThreadPrivate(_ thread: Conversation) {
        guard let threadId = thread.id, let type = thread.type else { return }
        ChatManager.activeInstance?.conversation.changeType(.init(threadId: threadId, type: type.privateType))
    }

    public func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        sheetType = .addParticipant
    }

    @MainActor
    public func addParticipantsToThread(_ contacts: ContiguousArray<Contact>) async {
        guard let threadId = selectedThraed?.id else { return }
        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)
        ChatManager.activeInstance?.conversation.participant.add(req)
        lazyList.setLoading(true)
    }

    func onAddPrticipant(_ response: ChatResponse<Conversation>) async {
        if response.result?.participants?.first(where: {$0.id == AppState.shared.user?.id}) != nil, let newConversation = response.result {
            /// It means an admin added a user to the conversation, and if the added user is in the app at the moment, should see this new conversation in its conversation list.
            await appendThreads(threads: [newConversation])
        }
        await insertIntoParticipantViewModel(response)
        await lazyList.setLoading(false)
    }

    @MainActor
    private func insertIntoParticipantViewModel(_ response: ChatResponse<Conversation>) async {
        if let threadVM = AppState.shared.objectsContainer.navVM.viewModel(for: response.result?.id ?? -1) {
            let addedParticipants = response.result?.participants ?? []
            threadVM.participantsViewModel.onAdded(addedParticipants)
//            threadVM.animateObjectWillChange()
        }
    }

    public func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        sheetType = .tagManagement
    }

    @MainActor
    public func appendThreads(threads: [Conversation]) async {
        threads.forEach { thread in
            if var oldThread = self.threads.first(where: { $0.id == thread.id }) {
                oldThread.updateValues(thread)
            } else {
                self.threads.append(thread)
            }
            if !threadEventModels.contains(where: {$0.threadId == thread.id}) {
                let eventVM = ThreadEventViewModel(threadId: thread.id ?? 0)
                threadEventModels.append(eventVM)
            }
        }
        sort()
    }

    public func sort() {
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && ($1.pin == false || $1.pin == nil) })
        threads.sort(by: { (firstItem, secondItem) in
            guard let firstIndex = serverSortedPins.firstIndex(where: {$0 == firstItem.id}),
                  let secondIndex = serverSortedPins.firstIndex(where: {$0 == secondItem.id}) else {
                return false // Handle the case when an element is not found in the server-sorted array
            }
            return firstIndex < secondIndex
        })
    }

    @MainActor
    public func clear() async {
        isInCacheMode = false
        lazyList.reset()
        threads = []
        firstSuccessResponse = false
        animateObjectWillChange()
    }

    @MainActor
    public func silenClear() async {
        if firstSuccessResponse {
            isSilentClear = true
        }
        isInCacheMode = false
        lazyList.reset()
        animateObjectWillChange()
    }

    public func muteUnMuteThread(_ threadId: Int?, isMute: Bool) {
        if let threadId = threadId, let index = firstIndex(threadId) {
            threads[index].mute = isMute
            animateObjectWillChange()
        }
    }

    public func removeThread(_ thread: Conversation) {
        guard let index = firstIndex(thread.id) else { return }
        _ = threads.remove(at: index)
        animateObjectWillChange()
    }

    public func delete(_ threadId: Int?) {
        guard let threadId = threadId else { return }
        let conversation = threads.first(where: { $0.id == threadId})
        let isGroup = conversation?.group == true
        if isGroup {
            ChatManager.activeInstance?.conversation.delete(.init(subjectId: threadId))
        } else {
            ChatManager.activeInstance?.conversation.leave(.init(threadId: threadId, clearHistory: true))
        }
        sheetType = nil
    }

    func onDeleteThread(_ response: ChatResponse<Participant>) {
        if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func leave(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        let req = LeaveThreadRequest(threadId: threadId, clearHistory: true)
        RequestsManager.shared.append(prepend: LEAVE_KEY, value: req)
        ChatManager.activeInstance?.conversation.leave(req)
    }

    public func clearHistory(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.message.clear(.init(subjectId: threadId))
    }

    func onClear(_ response: ChatResponse<Int>) {
        if let threadId = response.result, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func spamPV(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.spam(.init(subjectId: threadId))
    }

    func onSpam(_ response: ChatResponse<Contact>) {
        if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        threads.firstIndex(where: { $0.id == threadId ?? -1 })
    }

    public func refreshThreadsUnreadCount() {
        let threadsIds = threads.compactMap(\.id)
        ChatManager.activeInstance?.conversation.unreadCount(.init(threadIds: threadsIds))
    }

    @MainActor
    func onUnreadCounts(_ response: ChatResponse<[String : Int]>) async {
        response.result?.forEach { key, value in
            if let index = firstIndex(Int(key)) {
                threads[index].unreadCount = value
            }
        }
        lazyList.setLoading(false)
    }

    public func updateThreadInfo(_ thread: Conversation) {
        if let threadId = thread.id, let index = firstIndex(threadId) {
            let title = thread.title ?? ""
            let replacedEmoji = title.replacingOccurrences(of: NSRegularExpression.emojiRegEx, with: "\\\\u{$1}", options: .regularExpression)
            /// In the update thread info, the image property is nil and the metadata link is been filled by the server.
            /// So to update the UI properly we have to set it to link.
            if let metadatImagelink = thread.metaData?.file?.link {
                threads[index].image = metadatImagelink
            }
            threads[index].title = replacedEmoji
            threads[index].updateValues(thread)
            let activeThread = AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
            activeThread?.thread = threads[index]
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            animateObjectWillChange()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = firstIndex(thread.id) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            animateObjectWillChange()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = self.firstIndex(id) {
            threads.remove(at: index)
            animateObjectWillChange()
        }
    }

    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) {
        if let index = firstIndex(response.subjectId) {
            var thread = threads[index]
            if response.result?.unreadCount == 0, thread.mentioned == true {
                thread.mentioned = false
            }
            if response.result?.lastSeenMessageTime ?? 0 > thread.lastSeenMessageTime ?? 0 {
                thread.lastSeenMessageTime = response.result?.lastSeenMessageTime
                thread.lastSeenMessageId = response.result?.lastSeenMessageId
                thread.lastSeenMessageNanos = response.result?.lastSeenMessageNanos
                setUnreadCount(response.result?.unreadCount ?? response.contentCount, threadId: response.subjectId)
            }
            threads[index] = thread
            animateObjectWillChange()
        }
    }

    func onCancelTimer(key: String) {
        Task { @MainActor in
            if lazyList.isLoading {
                lazyList.setLoading(false)
            }
        }
    }

    public func avatars(for imageURL: String, metaData: String?, userName: String?) -> ImageLoaderViewModel {
        if let avatarVM = avatarsVM[imageURL] {
            return avatarVM
        } else {
            let config = ImageLoaderConfig(url: imageURL, metaData: metaData, userName: userName)
            let newAvatarVM = ImageLoaderViewModel(config: config)
            avatarsVM[imageURL] = newAvatarVM
            return newAvatarVM
        }
    }

    @MainActor
    public func clearAvatarsOnSelectAnotherThread() async {
        var keysToRemove: [String] = []
        let allThreadImages = threads.compactMap({$0.computedImageURL})
        avatarsVM.forEach { (key: String, value: ImageLoaderViewModel) in
            if !allThreadImages.contains(where: {$0 == key }) {
                keysToRemove.append(key)
            }
        }
        keysToRemove.forEach { key in
            avatarsVM.removeValue(forKey: key)
        }
    }

    public func onJoinedToPublicConversatin(_ response: ChatResponse<Conversation>) {
        if let conversation = response.result {
            threads.append(conversation)
            sort()
            if conversation.participants?.first?.id == AppState.shared.user?.id {
                AppState.shared.showThread(conversation)
            }
            animateObjectWillChange()
        }
    }

    /// This method prevents to update unread count if the local unread count is smaller than server unread count.
    public func setUnreadCount(_ newCount: Int?, threadId: Int?) {
        guard let index = threads.firstIndex(where: {$0.id == threadId}) else { return }
        if newCount ?? 0 <= threads[index].unreadCount ?? 0 {
            threads[index].unreadCount = newCount
            animateObjectWillChange()
        }
    }

    func onLeftThread(_ response: ChatResponse<User>) {
        let isMe = response.result?.id == AppState.shared.user?.id
        let threadVM = AppState.shared.objectsContainer.navVM.viewModel(for: response.subjectId ?? -1)
        let deletedUserId = response.result?.id
        let participant = threadVM?.participantsViewModel.participants.first(where: {$0.id == deletedUserId})
        if isMe, let conversationId = response.subjectId {
            removeThread(.init(id: conversationId))
        } else if let participant = participant {
            threadVM?.participantsViewModel.removeParticipant(participant)
        }
    }

    public func joinPublicGroup(_ publicName: String) {
        ChatManager.activeInstance?.conversation.join(.init(threadName: publicName))
    }

    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        /// Update the status bar in ThreadRow when a receiver seen a message, and in the sender side we have to update the UI.
        let isMe = AppState.shared.user?.id == response.result?.participantId
        if !isMe, let index = threads.firstIndex(where: {$0.lastMessageVO?.id == response.result?.messageId}) {
            threads[index].lastMessageVO?.delivered = true
            threads[index].lastMessageVO?.seen = true
            threads[index].partnerLastSeenMessageId = response.result?.messageId
            animateObjectWillChange()
        }
    }

    /// This method only reduce the unread count if the deleted message has sent after lastSeenMessageTime.
    public func onMessageDeleted(_ response: ChatResponse<Message>) {
        guard let index = threads.firstIndex(where: { $0.id == response.subjectId }) else { return }
        var thread = threads[index]
        if response.result?.time ?? 0 > thread.lastSeenMessageTime ?? 0, thread.unreadCount ?? 0 >= 1 {
            thread.unreadCount = (thread.unreadCount ?? 0) - 1
            threads[index] = thread
            animateObjectWillChange()
        }
    }

    public func getNotActiveThreads(_ conversation: Conversation?) {
        if let conversationId = conversation?.id, !threads.contains(where: {$0.id == conversationId }) {
            let req = ThreadsRequest(threadIds: [conversationId])
            RequestsManager.shared.append(prepend: GET_NOT_ACTIVE_THREADS_KEY, value: req)
            ChatManager.activeInstance?.conversation.get(req)
        }
    }

    public func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            threads[threadIndex].pinMessage = response.result
        }
    }

    public func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            threads[threadIndex].pinMessage = nil
        }
    }

    func log(_ string: String) {
#if DEBUG
        let log = Log(prefix: "TALK_APP", time: .now, message: string, level: .warning, type: .internalLog, userInfo: nil)
        NotificationCenter.logs.post(name: .logs, object: log)
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
