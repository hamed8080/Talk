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
    public var threads: ContiguousArray<CalculatedConversation> = []
    @Published public var activeCallThreads: [CallToJoin] = []
    @Published public var sheetType: ThreadsSheetType?
    public var cancelable: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public var selectedThraed: Conversation?
    private var avatarsVM: [String :ImageLoaderViewModel] = [:]
    public var serverSortedPins: [Int] = []
    public var shimmerViewModel = ShimmerViewModel(delayToHide: 0, repeatInterval: 0.5)
    private var cache: Bool = true
    var isInCacheMode = false
    private var isSilentClear = false
    @MainActor public private(set) var lazyList = LazyListViewModel()
    private let participantsCountManager = ParticipantsCountManager()
    private var wasDisconnected = false
    internal let incQueue = IncommingMessagesQueue()
    internal lazy var threadFinder: GetSpecificConversationViewModel = { GetSpecificConversationViewModel(archive: false) }()

    internal var objectId = UUID().uuidString
    internal let GET_THREADS_KEY: String
    internal let CHANNEL_TO_KEY: String
    internal let JOIN_TO_PUBLIC_GROUP_KEY: String
    internal let LEAVE_KEY: String

    // MARK: Computed properties
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }

    public init() {
        GET_THREADS_KEY = "GET-THREADS-\(objectId)"
        CHANNEL_TO_KEY = "CHANGE-TO-PUBLIC-\(objectId)"
        JOIN_TO_PUBLIC_GROUP_KEY = "JOIN-TO-PUBLIC-GROUP-\(objectId)"
        LEAVE_KEY = "LEAVE"
        Task {
            await setupObservers()
        }
        incQueue.viewModel = self
    }

    @MainActor
    func onCreate(_ response: ChatResponse<Conversation>) async {
        lazyList.setLoading(false)
        if let thread = response.result {
            var thread = thread
            thread.reactionStatus = thread.reactionStatus ?? .enable
            await calculateAppendSortAnimate(thread)
        }
    }

    public func onNewMessage(_ messages: [Message], conversationId: Int) async {
        if let index = firstIndex(conversationId) {
            let reference = threads[index]
            let old = reference.toStruct()
            let updated = reference.updateOnNewMessage(messages.last ?? .init(), meId: myId)
            threads[index] = updated
            threads[index].animateObjectWillChange()
            if updated.pin == false {
                await sortInPlace()
            }
            recalculateAndAnimate(updated)
            updateActiveConversationOnNewMessage(messages, updated.toStruct(), old)
            animateObjectWillChange() /// We should update the ThreadList view because after receiving a message, sorting has been changed.
        } else if let conversation = await threadFinder.getNotActiveThreads(conversationId) {
            await calculateAppendSortAnimate(conversation)
        }
    }

    private func updateActiveConversationOnNewMessage(_ messages: [Message], _ updatedConversation: Conversation, _ oldConversation: Conversation?) {
        let activeVM = navVM.presentedThreadViewModel?.viewModel
        if updatedConversation.id == activeVM?.threadId {
            Task {
                await activeVM?.historyVM.onNewMessage(messages, oldConversation, updatedConversation)
            }
        }
    }

    func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = firstIndex(response.result?.id)  {
            threads[index].type = .publicGroup
            threads[index].animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if status == .connected {
            // After connecting again
            // We should call this method because if the token expire all the data inside InMemory Cache of the SDK is invalid
            wasDisconnected = true
            await refresh()
        } else if status == .disconnected && !firstSuccessResponse {
            // To get the cached version of the threads in SQLITE.
            await getThreads()
        }
    }

    @MainActor
    public func getThreads(withQueue: Bool = false) async {
        if !firstSuccessResponse {
            shimmerViewModel.show()
        }
        lazyList.setLoading(true)
        let req = ThreadsRequest(count: lazyList.count, offset: lazyList.offset, cache: cache)
        RequestsManager.shared.append(prepend: GET_THREADS_KEY, value: req)
        if withQueue {
            AppState.shared.objectsContainer.chatRequestQueue.enqueue(.getConversations(req: req))
        } else {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.conversation.get(req)
            }
        }
    }

    @MainActor
    public func loadMore(id: Int?) async {
        if !lazyList.canLoadMore(id: id) { return }
        lazyList.prepareForLoadMore()
        await getThreads()
    }

    @MainActor
    public func onThreads(_ response: ChatResponse<[Conversation]>) async {
        let wasSilentClear = isSilentClear
        if isSilentClear {
            threads.removeAll()
            isSilentClear = false
            // We have got to wait to update the UI with removed items then append and refresh the UI with new elements, unless we will end up with wrong scroll position after update
            animateObjectWillChange()
            try? await Task.sleep(for: .milliseconds(200))
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
        let navSelectedId = AppState.shared.objectsContainer.navVM.selectedId
        let calculatedThreads = await ThreadCalculators.calculate(response.result ?? [], myId, navSelectedId)
        let newThreads = await appendThreads(newThreads: calculatedThreads, oldThreads: threads)
        let sorted = await sort(threads: newThreads, serverSortedPins: serverSortedPins)
        let threshold = await splitThreshold(sorted)
       
        await MainActor.run {
            self.threads = sorted
            updatePresentedViewModels(threads)
            lazyList.setHasNext(hasAnyResults)
            lazyList.setLoading(false)
            lazyList.setThreasholdIds(ids: threshold)
            if hasAnyResults {
                firstSuccessResponse = true
            }
            if firstSuccessResponse {
                shimmerViewModel.hide()
            }
            objectWillChange.send()
        }
        
        await updateActiveThreadAfterDisconnect()
    }
    
    private func updateActiveThreadAfterDisconnect() async {
        if wasDisconnected,
           let activeVM = navVM.presentedThreadViewModel?.viewModel,
           let updatedThread = threads.first(where: {$0.id == activeVM.threadId}) {
            activeVM.thread = updatedThread.toStruct()
            activeVM.delegate?.onUnreadCountChanged()
            wasDisconnected = false
        }
    }
    
    @AppBackgroundActor
    private func splitThreshold(_ sorted: ContiguousArray<CalculatedConversation>) -> [Int] {
        sorted.suffix(2).compactMap{$0.id}
    }

    /// After connect and reconnect all the threads will be removed from the array
    /// So the ThreadViewModel which contains this thread object have different refrence than what's inside the array
    private func updatePresentedViewModels(_ conversations: ContiguousArray<CalculatedConversation>) {
        conversations.forEach { conversation in
            navVM.updateConversationInViewModel(conversation)
        }
    }

    public func refresh() async {
        cache = false
        await silentClear()
        await getThreads(withQueue: true)
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
        if response.result?.participants?.first(where: {$0.id == myId}) != nil, let newConversation = response.result {
            /// It means an admin added a user to the conversation, and if the added user is in the app at the moment, should see this new conversation in its conversation list.
            var newConversation = newConversation
            newConversation.reactionStatus = newConversation.reactionStatus ?? .enable
            await calculateAppendSortAnimate(newConversation)
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
    public func appendThreads(newThreads: [CalculatedConversation], oldThreads: ContiguousArray<CalculatedConversation>)
    async -> ContiguousArray<CalculatedConversation> {
        var arr = oldThreads
        for thread in newThreads {
            if var oldThread = oldThreads.first(where: { $0.id == thread.id }) {
                await oldThread.updateValues(thread)
            } else {
                arr.append(thread)
            }
        }
        return arr
    }

    @AppBackgroundActor
    public func sort(threads: ContiguousArray<CalculatedConversation>, serverSortedPins: [Int]) async -> ContiguousArray<CalculatedConversation> {
        var threads = threads
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && ($1.pin == false || $1.pin == nil) })
        threads.sort(by: { (firstItem, secondItem) in
            guard let firstIndex = serverSortedPins.firstIndex(where: {$0 == firstItem.id}),
                  let secondIndex = serverSortedPins.firstIndex(where: {$0 == secondItem.id}) else {
                return false // Handle the case when an element is not found in the server-sorted array
            }
            return firstIndex < secondIndex
        })
        return threads
    }
    
    public func sortInPlace() async {
        let sorted = await sort(threads: threads, serverSortedPins: serverSortedPins)
        threads = sorted
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

    public func removeThread(_ thread: CalculatedConversation) {
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
                Task {
                    await ThreadCalculators.reCalculateUnreadCount(threads[index])
                    threads[index].animateObjectWillChange()
                }
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
            if let metadata = thread.metaData {
                arrItem.image = metadata.file?.link
                arrItem.computedImageURL = ThreadCalculators.calculateImageURL( arrItem.image, metadata)
            }
            arrItem.title = replacedEmoji
            arrItem.closed = thread.closed
            arrItem.time = thread.time ?? arrItem.time
            arrItem.userGroupHash = thread.userGroupHash ?? arrItem.userGroupHash
            arrItem.description = thread.description

            threads[index] = arrItem
            threads[index].animateObjectWillChange()

            // Update active thread if it is open
            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = arrItem.toStruct()
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            activeThread?.delegate?.refetchImageOnUpdateInfo()

            // Update active thread detail view if it is open
            if let detailVM = AppState.shared.objectsContainer.navVM.detailViewModel(threadId: threadId) {
                detailVM.updateThreadInfo(arrItem.toStruct())
            }
            animateObjectWillChange()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = firstIndex(thread.id) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            threads[index].animateObjectWillChange()
            recalculateAndAnimate(threads[index])
            animateObjectWillChange()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = self.firstIndex(id) {
            threads.remove(at: index)
            threads[index].animateObjectWillChange()
            recalculateAndAnimate(threads[index])
            animateObjectWillChange()
        }
    }

    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) async {
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
                    await ThreadCalculators.reCalculateUnreadCount(threads[index])
                    
                    /// If the user open up the same thread on two devices at the same time,
                    /// and on of them is at the bottom of the thread and one is at top,
                    /// the one at bottom will send seen and respectively when we send seen unread count will be reduced,
                    /// so on another thread we should catch this new unread count and update the thread.
                    let activeVM = AppState.shared.objectsContainer.navVM.viewModel(for: response.subjectId ?? -1)
                    activeVM?.delegate?.onUnreadCountChanged()
                }
            }
            threads[index] = thread
            threads[index].animateObjectWillChange()
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
        if let avatarVM = avatarsVM[imageURL], !imageURL.isEmpty {
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
    public func onJoinedToPublicConversation(_ response: ChatResponse<Conversation>) async {
        if let conversation = response.result {
            if conversation.participants?.first?.id == myId, response.pop(prepend: JOIN_TO_PUBLIC_GROUP_KEY) != nil {
                AppState.shared.showThread(conversation)
            }
            
            if let id = conversation.id, let conversation = await threadFinder.getNotActiveThreads(id) {
                await calculateAppendSortAnimate(conversation)
            }
        }
    }

    func onLeftThread(_ response: ChatResponse<User>) {
        let isMe = response.result?.id == myId
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
            threads[index].animateObjectWillChange()
            animateObjectWillChange()

            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = threads[index].toStruct()
            activeThread?.delegate?.onConversationClosed()
        }
    }

    public func joinPublicGroup(_ publicName: String) {
        let req = JoinPublicThreadRequest(threadName: publicName)
        RequestsManager.shared.append(prepend: JOIN_TO_PUBLIC_GROUP_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.join(req)
        }
    }

    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        /// Update the status bar in ThreadRow when a receiver seen a message, and in the sender side we have to update the UI.
        let isMe = myId == response.result?.participantId
        if !isMe, let index = threads.firstIndex(where: {$0.lastMessageVO?.id == response.result?.messageId}) {
            threads[index].lastMessageVO?.delivered = true
            threads[index].lastMessageVO?.seen = true
            threads[index].partnerLastSeenMessageId = response.result?.messageId
            recalculateAndAnimate(threads[index])
        }
        logUnreadCount("SERVER OnSeen: \(response.result)")
    }

    /// This method only reduce the unread count if the deleted message has sent after lastSeenMessageTime.
    public func onMessageDeleted(_ response: ChatResponse<Message>) async {
        guard let index = threads.firstIndex(where: { $0.id == response.subjectId }) else { return }
        var thread = threads[index]
        if response.result?.time ?? 0 > thread.lastSeenMessageTime ?? 0, thread.unreadCount ?? 0 >= 1 {
            thread.unreadCount = (thread.unreadCount ?? 0) - 1
            await ThreadCalculators.reCalculateUnreadCount(threads[index])
            threads[index] = thread
            threads[index].animateObjectWillChange()
            recalculateAndAnimate(thread)
        }
    }

    public func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            threads[threadIndex].pinMessage = response.result
            threads[threadIndex].animateObjectWillChange()            
            animateObjectWillChange()
        }
    }

    public func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            threads[threadIndex].pinMessage = nil
            threads[threadIndex].animateObjectWillChange()
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
    
    private func recalculateAndAnimate(_ thread: CalculatedConversation) {
        Task {
            await ThreadCalculators.reCalculate(thread, myId, AppState.shared.objectsContainer.navVM.selectedId)
            thread.animateObjectWillChange()
        }
    }
    
    public func calculateAppendSortAnimate(_ thread: Conversation) async {
        let calThreads = await ThreadCalculators.calculate([thread], myId)
        let appendedThreads = await appendThreads(newThreads: calThreads, oldThreads: threads)
        let sorted = await sort(threads: appendedThreads, serverSortedPins: serverSortedPins)
        threads = sorted
        animateObjectWillChange()
    }
    
    private var myId: Int {
        AppState.shared.user?.id ?? -1
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
    
    public func setSelected(for conversationId: Int, selected: Bool) {
        if let thread = threads.first(where: {$0.id == conversationId}) {
            /// Select / Deselect a thread to remove/add bar and selected background color
            thread.isSelected = selected
            thread.animateObjectWillChange()
        }
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
