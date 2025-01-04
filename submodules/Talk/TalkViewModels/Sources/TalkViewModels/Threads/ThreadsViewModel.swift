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

@MainActor
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

    // MARK: Computed properties
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }

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
            var thread = thread
            thread.reactionStatus = thread.reactionStatus ?? .enable
            await appendThreads(threads: [thread])
            await asyncAnimateObjectWillChange()
        }
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = firstIndex(message.conversation?.id) {
            let old = threads[index]
            let updated = old.updateOnNewMessage(response, meId: AppState.shared.user?.id)
            threads[index] = updated

            if updated.pin == false {
                sort()
            }
            animateObjectWillChange()
            updateActiveConversationOnNewMessage(response, updated, old)
        }
        getNotActiveThreads(response.result?.conversation)
    }

    private func updateActiveConversationOnNewMessage(_ response: ChatResponse<Message>, _ updatedConversation: Conversation, _ oldConversation: Conversation?) {
        let activeVM = navVM.presentedThreadViewModel?.viewModel
        let newMSG = response.result
        let isMeJoinedPublic = newMSG?.messageType == .participantJoin && newMSG?.participant?.id == AppState.shared.user?.id
        if response.subjectId == activeVM?.threadId, let message = newMSG, !isMeJoinedPublic {
            activeVM?.updateUnreadCount(updatedConversation.unreadCount)
            Task {
                await activeVM?.historyVM.onNewMessage(message, oldConversation, updatedConversation)
            }
        }
    }

    func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = firstIndex(response.result?.id)  {
            threads[index].type = .publicGroup
            animateObjectWillChange()
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if status == .connected {
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
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
    }

    @MainActor
    public func loadMore(id: Int?) async {
        if await !lazyList.canLoadMore(id: id) { return }
        lazyList.prepareForLoadMore()
        await getThreads()
    }

    public func onThreads(_ response: ChatResponse<[Conversation]>) async {
        let wasSilentClear = isSilentClear
        if isSilentClear {
            threads.removeAll()
            isSilentClear = false
            // We have got to wait to update the UI with removed items then append and refresh the UI with new elements, unless we will end up with wrong scroll position after update
            animateObjectWillChange()
            try? await Task.sleep(for: .milliseconds(200))
        }
        var threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil}) ?? []
        threads.enumerated().forEach { index, thread in
            threads[index].title = thread.title?.stringToScalarEmoji()
            threads[index].reactionStatus = thread.reactionStatus ?? .enable
        }
        let pinThreads = response.result?.filter({$0.pin == true})
        let hasAnyResults = response.result?.count ?? 0 > 0

        /// It only sets sorted pins once because if we have 5 pins, they are in the first response. So when the user scrolls down the list will not be destroyed every time.
        if !response.cache, let serverSortedPinIds = pinThreads?.compactMap({$0.id}), serverSortedPins.isEmpty || wasSilentClear {
            serverSortedPins.removeAll()
            serverSortedPins.append(contentsOf: serverSortedPinIds)
            userDefaultSortedPins = serverSortedPins
        } else if response.cache {
            serverSortedPins.removeAll()
            serverSortedPins.append(contentsOf: userDefaultSortedPins)
        }
        appendThreads(threads: threads)
        updatePresentedViewModels(threads)
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
            navVM.updateConversationInViewModel(conversation)
        }
    }

    public func onNotActiveThreads(_ response: ChatResponse<[Conversation]>) async {
        if let threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil}) {
            var threads = threads
            threads.enumerated().forEach { (index, thread) in
                threads[index].reactionStatus = thread.reactionStatus ?? .enable
            }

            let presendtedId = navVM.presentedThreadViewModel?.viewModel.thread.id
            if let thread = response.result?.first(where: {$0.id == presendtedId}) {
                navVM.presentedThreadViewModel?.viewModel.thread = thread
            }
            await appendThreads(threads: threads)
            await asyncAnimateObjectWillChange()
        }
    }

    public func refresh() async {
        cache = false
        await silentClear()
        await getThreads()
        cache = true
    }

    /// Create a thread and send a message without adding a contact.
    @MainActor
    public func fastMessage(_ invitee: Invitee, _ message: String) async {
        let messageREQ = CreateThreadMessage(text: message, messageType: .text)
        let req = CreateThreadWithMessage(invitees: [invitee], title: "", type: StrictThreadTypeCreation.p2p.threadType, message: messageREQ)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.create(req)
        }
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
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.changeType(req)
        }
    }

    public func makeThreadPrivate(_ thread: Conversation) {
        guard let threadId = thread.id, let type = thread.type else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.changeType(.init(threadId: threadId, type: type.privateType))
        }
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
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.participant.add(req)
        }
        lazyList.setLoading(true)
    }

    func onAddPrticipant(_ response: ChatResponse<Conversation>) async {
        if response.result?.participants?.first(where: {$0.id == AppState.shared.user?.id}) != nil, let newConversation = response.result {
            /// It means an admin added a user to the conversation, and if the added user is in the app at the moment, should see this new conversation in its conversation list.
            var newConversation = newConversation
            newConversation.reactionStatus = newConversation.reactionStatus ?? .enable
            await appendThreads(threads: [newConversation])
        }
        await insertIntoParticipantViewModel(response)
        lazyList.setLoading(false)
    }

    @MainActor
    private func insertIntoParticipantViewModel(_ response: ChatResponse<Conversation>) async {
        if let threadVM = navVM.viewModel(for: response.result?.id ?? -1) {
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
    public func appendThreads(threads: [Conversation]) {
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
    public func silentClear() async {
        if firstSuccessResponse {
            isSilentClear = true
        }
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
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.conversation.delete(.init(subjectId: threadId))
            }
        } else {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.conversation.leave(.init(threadId: threadId, clearHistory: true))
            }
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
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.leave(req)
        }
    }

    public func close(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.close(req)
        }
    }

    public func clearHistory(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.clear(.init(subjectId: threadId))
        }
    }

    func onClear(_ response: ChatResponse<Int>) {
        if let threadId = response.result, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func spamPV(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.spam(.init(subjectId: threadId))
        }
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
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.unreadCount(.init(threadIds: threadsIds))
        }
    }

    @MainActor
    func onUnreadCounts(_ response: ChatResponse<[String : Int]>) async {
        response.result?.forEach { key, value in
            if let index = firstIndex(Int(key)) {
                threads[index].unreadCount = value
            }
        }
        lazyList.setLoading(false)
        logUnreadCount("SERVER unreadCount: \(response.result)")
    }

    public func updateThreadInfo(_ thread: Conversation) {
        if let threadId = thread.id, let index = firstIndex(threadId) {
            let replacedEmoji = thread.titleRTLString.stringToScalarEmoji()
            /// In the update thread info, the image property is nil and the metadata link is been filled by the server.
            /// So to update the UI properly we have to set it to link.
            var arrItem = threads[index]
            if let metadatImagelink = thread.metaData?.file?.link {
                arrItem.image = metadatImagelink
            }
            arrItem.title = replacedEmoji
            arrItem.closed = thread.closed
            arrItem.time = thread.time ?? arrItem.time
            arrItem.userGroupHash = thread.userGroupHash ?? arrItem.userGroupHash
            arrItem.description = thread.description

            threads[index] = arrItem

            // Update active thread if it is open
            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = arrItem
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            activeThread?.delegate?.refetchImageOnUpdateInfo()

            // Update active thread detail view if it is open
            if AppState.shared.objectsContainer.threadDetailVM.thread?.id == threadId {
                AppState.shared.objectsContainer.threadDetailVM.updateThreadInfo(arrItem)
            }
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
                let newCount = response.result?.unreadCount ?? response.contentCount ?? 0
                if newCount <= threads[index].unreadCount ?? 0 {
                    thread.unreadCount = newCount
                }
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

    /// There is a chance another user join to this public group, so we have to check if the thread is already exists.
    public func onJoinedToPublicConversation(_ response: ChatResponse<Conversation>) {
        if let conversation = response.result {
            var conversaiton = conversation
            conversaiton.title = conversaiton.title?.stringToScalarEmoji()
            if !threads.contains(where: {$0.id == conversation.id}) {
                threads.append(conversation)
                if conversation.participants?.first?.id == AppState.shared.user?.id {
                    AppState.shared.showThread(conversation)
                }
            }
            sort()
            animateObjectWillChange()
        }
    }

    func onLeftThread(_ response: ChatResponse<User>) {
        let isMe = response.result?.id == AppState.shared.user?.id
        let threadVM = navVM.viewModel(for: response.subjectId ?? -1)
        let deletedUserId = response.result?.id
        let participant = threadVM?.participantsViewModel.participants.first(where: {$0.id == deletedUserId})
        if isMe, let conversationId = response.subjectId {
            removeThread(.init(id: conversationId))
        } else if let participant = participant {
            threadVM?.participantsViewModel.removeParticipant(participant)
        }
    }

    func onClosed(_ response: ChatResponse<Int>) {
        guard let threadId = response.result else { return }
        if let index = threads.firstIndex(where: { $0.id == threadId}) {
            threads[index].closed = true
            animateObjectWillChange()

            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = threads[index]
            activeThread?.delegate?.onConversationClosed()
        }
    }

    public func joinPublicGroup(_ publicName: String) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.join(.init(threadName: publicName))
        }
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
        logUnreadCount("SERVER OnSeen: \(response.result)")
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
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.conversation.get(req)
            }
        }
    }

    public func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            threads[threadIndex].pinMessage = response.result
            animateObjectWillChange()
        }
    }

    public func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            threads[threadIndex].pinMessage = nil
            animateObjectWillChange()
        }
    }

    private var userDefaultSortedPins: [Int] {
        get {
            UserDefaults.standard.value(forKey: "SERVER_PINS") as? [Int] ?? []
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "SERVER_PINS")
        }
    }

    func log(_ string: String) {
#if DEBUG
        let log = Log(prefix: "TALK_APP", time: .now, message: string, level: .warning, type: .internalLog, userInfo: nil)
        NotificationCenter.logs.post(name: .logs, object: log)
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
    
    private func logUnreadCount(_ string: String) {
#if DEBUG
        Logger.viewModels.info("UNREADCOUNT: \(string, privacy: .sensitive)")
#endif
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
