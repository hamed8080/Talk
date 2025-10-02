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
import Logger

public enum ThreadsListSection: Sendable {
    case main
}

@MainActor
public protocol UIThreadsViewControllerDelegate: AnyObject, ContextMenuDelegate {
    func updateUI(animation: Bool, reloadSections: Bool)
    func updateImage(image: UIImage?, id: Int)
    func reloadCellWith(conversation: CalculatedConversation)
    func selectionChanged(conversation: CalculatedConversation)
    func unreadCountChanged(conversation: CalculatedConversation)
    func setEvent(smt: SMT?, conversation: CalculatedConversation)
    func indexPath<T: UITableViewCell>(for: T) -> IndexPath?
    func dataSourceItem(for indexPath: IndexPath) -> CalculatedConversation?
    func scrollToTop()
    var contextMenuContainer: ContextMenuContainerView? { get set }
}

@MainActor
public final class ThreadsViewModel: ObservableObject {
    public private(set) var threads: ContiguousArray<CalculatedConversation> = []
    @Published public var activeCallThreads: [CallToJoin] = []
    @Published public var sheetType: ThreadsSheetType?
    public var cancelable: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public var selectedThraed: Conversation?
    public var calculatedSearchedThreads: [CalculatedConversation] = []
    public var serverSortedPins: [Int] = []
    public var shimmerViewModel = ShimmerViewModel(delayToHide: 0, repeatInterval: 0.5)
    private var cache: Bool = true
    public private(set) var lazyList = LazyListViewModel()
    private let participantsCountManager = ParticipantsCountManager()
    private var wasDisconnected = false
    internal let incForwardQueue = IncommingForwardMessagesQueue()
    internal let incNewQueue = IncommingNewMessagesQueue()
    public var saveScrollPositionVM = ThreadsSaveScrollPositionViewModel()
    public weak var delegate: UIThreadsViewControllerDelegate?

    internal var objectId = UUID().uuidString
    internal let CHANNEL_TO_KEY: String
    internal let JOIN_TO_PUBLIC_GROUP_KEY: String
    internal let LEAVE_KEY: String

    // MARK: Computed properties
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }
    private var myId: Int { AppState.shared.user?.id ?? -1 }

    public init() {
        CHANNEL_TO_KEY = "CHANGE-TO-PUBLIC-\(objectId)"
        JOIN_TO_PUBLIC_GROUP_KEY = "JOIN-TO-PUBLIC-GROUP-\(objectId)"
        LEAVE_KEY = "LEAVE"
        
        setupObservers()
        
        incForwardQueue.viewModel = self
        incNewQueue.viewModel = self
    }

    func onCreate(_ response: ChatResponse<Conversation>) async {
        lazyList.setLoading(false)
        if let thread = response.result {
            var thread = thread
            thread.reactionStatus = thread.reactionStatus ?? .enable
            await calculateAppendSortAnimate(thread)
        }
    }

    public func onNewMessage(_ messages: [Message], conversationId: Int) async -> Bool {
        if let index = firstIndex(conversationId) {
            let reference = threads[index]
            let old = reference.toStruct()
            let updated = reference.updateOnNewMessage(messages.last ?? .init(), meId: myId)
            threads[index] = updated
            delegate?.unreadCountChanged(conversation: updated)
            threads[index].animateObjectWillChange()
            if updated.pin == false {
                await sortInPlace()
            }
            recalculateAndAnimate(updated)
            updateActiveConversationOnNewMessage(messages, updated.toStruct(), old)
            delegate?.updateUI(animation: false, reloadSections: false)
            animateObjectWillChange() /// We should update the ThreadList view because after receiving a message, sorting has been changed.
            return true
        } else if let conversation = await GetSpecificConversationViewModel().getNotActiveThreads(conversationId), conversation.isArchive != true {
            let oldConversation = navVM.viewModel(for: conversation.id ?? -1)?.thread
            await calculateAppendSortAnimate(conversation)
            updateActiveConversationOnNewMessage(messages, conversation, oldConversation)
            return false
        }
        return false
    }

    private func updateActiveConversationOnNewMessage(_ messages: [Message], _ updatedConversation: Conversation, _ oldConversation: Conversation?) {
        let activeVM = navVM.viewModel(for: updatedConversation.id ?? -1)
        if updatedConversation.id == activeVM?.id {
            Task { [weak self] in
                guard let self = self else { return }
                await activeVM?.historyVM.onNewMessage(messages, oldConversation, updatedConversation)
            }
        }
    }
    
    public func onNewForwardMessage(conversationId: Int, forwardMessage: Message) async {
        if let index = firstIndex(conversationId) {
            let reference = threads[index]
            let old = reference.toStruct()
            let updated = reference.updateOnNewMessage(forwardMessage, meId: myId)
            threads[index] = updated
            threads[index].animateObjectWillChange()
            if updated.pin == false {
                await sortInPlace()
            }
            recalculateAndAnimate(updated)
            /// We have to reload the table view data source because,
            /// when we send or recive forward messages the lower thread will be moved to the top
            /// and in the above line we sort them again so reload data source is a must.
            delegate?.updateUI(animation: true, reloadSections: false)
            animateObjectWillChange() /// We should update the ThreadList view because after receiving a message, sorting has been changed.
        } else if let conversation = await GetSpecificConversationViewModel().getNotActiveThreads(conversationId) {
            await calculateAppendSortAnimate(conversation)
        }
    }

    func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = firstIndex(response.result?.id)  {
            threads[index].type = .publicGroup
            threads[index].animateObjectWillChange()
            delegate?.reloadCellWith(conversation: threads[index])
            animateObjectWillChange()
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if status == .connected {
            saveScrollPositionVM.clear()
            // After connecting again
            // We should call this method because if the token expire all the data inside InMemory Cache of the SDK is invalid
            wasDisconnected = true
            deselectActiveThread()
            await refresh()
        } else if status == .disconnected && !firstSuccessResponse {
            // To get the cached version of the threads in SQLITE.
            await getCachedThreads()
        }
    }
    
    private func getCachedThreads() async {
        let req = ThreadsRequest(count: lazyList.count, offset: lazyList.offset, cache: cache)
        do {
            let conversations = try await GetThreadsReuqester().getCalculated(req: req, withCache: true, queueable: false, myId: myId, navSelectedId: navVM.selectedId)
            let filtered = conversations.filter({ $0.isArchive == false || $0.isArchive == nil })
            await onThreads(filtered)
        } catch {
            log("Failed to get cached threads with error: \(error.localizedDescription)")
        }
    }

    public func getThreads(withQueue: Bool = false, keepOrder: Bool = false) async {
        /// Check if user didn't logged out
        if !TokenManager.shared.isLoggedIn { return }
        if !firstSuccessResponse {
            shimmerViewModel.show()
        }
        lazyList.setLoading(true)
        do {
            
            let req = ThreadsRequest(count: lazyList.count, offset: lazyList.offset, cache: cache)
            let conversations = try await GetThreadsReuqester().getCalculated(req: req,
                                                                              withCache: false,
                                                                              queueable: withQueue,
                                                                              myId: myId,
                                                                              navSelectedId: navVM.selectedId,
                                                                              keepOrder: keepOrder)
            let filtered = conversations.filter({ $0.isArchive == false || $0.isArchive == nil })
            if wasDisconnected {
                /// Clear and remove all threads
                threads.removeAll()
                /// After a disconnect it is essential to reload the diffable,
                /// becuase if there is any new message it won't show up.
                delegate?.updateUI(animation: false, reloadSections: false)
            }
                        
            await onThreads(filtered)
            
            moveToTopIfWasDisconnected(topItemId: threads.first?.id)
            
            wasDisconnected = false
        } catch {
            log("Failed to get threads with error: \(error.localizedDescription)")
        }
    }

    public func loadMore(id: Int?) async {
        if !lazyList.canLoadMore(id: id) { return }
        lazyList.prepareForLoadMore()
        await getThreads()
    }
    
    public func append(_ conversation: CalculatedConversation) async {
        let calThreads = await ThreadCalculators.reCalculate(conversation, myId, navVM.selectedId)
        threads.append(calThreads)
        await sortInPlace()
        calThreads.animateObjectWillChange()
        delegate?.updateUI(animation: true, reloadSections: false)
        animateObjectWillChange()
    }

    private func onThreads(_ conversations: [CalculatedConversation]) async {
        let hasAnyResults = conversations.count ?? 0 > 0
       
        let beforeSortedPins = serverSortedPins
        storeServerPins(conversations)
        
        let navSelectedId = navVM.selectedId
        let newThreads = await appendThreads(newThreads: conversations, oldThreads:  wasDisconnected ? []
                                             : threads)
        let sorted = await sort(threads: newThreads, serverSortedPins: serverSortedPins)
        let threshold = await splitThreshold(sorted)
      
        self.threads = sorted
        delegate?.updateUI(animation: false, reloadSections: false)
        for conversation in threads {
            addImageLoader(conversation)
        }
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
        
        updateActiveThreadAfterDisconnect()
        
        if wasDisconnected {
            beforeSortedPins.forEach { id in
                updatePinAndSelectedAfterReconnect(oldThreadId: id)
            }
        }
    }
    
    private func moveToTopIfWasDisconnected(topItemId: Int?) {
        if wasDisconnected {
            /// scroll To first if we were way down in the list to show correct row
            delegate?.scrollToTop()
        }
    }
    
    private func storeServerPins(_ conversations: [CalculatedConversation]) {
        let pinThreads = conversations.filter({$0.pin == true}).compactMap({$0.id}) ?? []
        let isFirstPinsResponse = !wasDisconnected && !pinThreads.isEmpty
        let isFirstResponseAfterDisconnect = wasDisconnected && !pinThreads.isEmpty
        
        /// It only sets sorted pins once because if we have 5 pins, they are in the first response. So when the user scrolls down the list will not be destroyed every time.
        if isFirstPinsResponse || isFirstResponseAfterDisconnect {
            serverSortedPins.removeAll()
            serverSortedPins.append(contentsOf: pinThreads)
            userDefaultSortedPins = serverSortedPins
        }
    }
    
    private func updatePinAndSelectedAfterReconnect(oldThreadId: Int?) {
        if let thread = threads.first(where: {$0.id == oldThreadId}) {
            if thread.isSelected == false {
                thread.animateObjectWillChange()
            }
            if thread.pin == false || thread.pin == nil {
                /// Allow context menu to active by number of items
                serverSortedPins.removeAll(where: {$0 == oldThreadId})
                thread.animateObjectWillChange()
            }
        }
    }
    
    private func updateActiveThreadAfterDisconnect() {
        if wasDisconnected,
           let activeVM = navVM.presentedThreadViewModel?.viewModel,
           let updatedThread = threads.first(where: {($0.id ?? 0) as Int == activeVM.id as Int}) {
            activeVM.thread = updatedThread.toStruct()
            activeVM.delegate?.onUnreadCountChanged()
        }
    }
    
    @AppBackgroundActor
    private func splitThreshold(_ sorted: ContiguousArray<CalculatedConversation>) -> [Int] {
        sorted.suffix(10).compactMap{$0.id}
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
        lazyList.reset()
        await getThreads(withQueue: true, keepOrder: true)
        cache = true
    }

    /// Create a thread and send a message without adding a contact.
    public func fastMessage(_ invitee: Invitee, _ message: String) async {
        let messageREQ = CreateThreadMessage(text: message, messageType: .text)
        let req = CreateThreadWithMessage(invitees: [invitee], title: "", type: StrictThreadTypeCreation.p2p.threadType, message: messageREQ)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.create(req)
        }
        lazyList.setLoading(true)
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
        guard let threadId = response.result?.id,
        var conversation = await GetSpecificConversationViewModel().getNotActiveThreads(threadId)
        else { return }
        let isMyselfAdded = response.result?.participants?.first(where: {$0.id == myId}) != nil
        let isChannel = conversation.type?.isChannelType == true
        let isArchive = conversation.isArchive == true

        if isArchive {
            /// Append to ArchiveViewModels
            await AppState.shared.objectsContainer.archivesVM.calculateAppendSortAnimate(conversation)
        } else if isMyselfAdded || isChannel {
            /*
             * Append to ThreadsViewModel itself
             *
             * It means an admin added a user to the conversation,
             * and if the added user is in the app at the moment, should see this new conversation in its conversation list.
             */
            await calculateAppendSortAnimate(conversation)
        }
        await insertIntoParticipantViewModel(response)
        lazyList.setLoading(false)
    }

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

    public func clear() {
        deselectActiveThread()
        lazyList.reset()
        threads = []
        firstSuccessResponse = false
        delegate?.updateUI(animation: false, reloadSections: false)
        animateObjectWillChange()
    }

    public func muteUnMuteThread(_ threadId: Int?, isMute: Bool) {
        if let threadId = threadId, let index = firstIndex(threadId) {
            threads[index].mute = isMute
            delegate?.reloadCellWith(conversation: threads[index])
            animateObjectWillChange()
        }
    }

    public func removeThread(_ thread: CalculatedConversation) {
        guard let index = firstIndex(thread.id) else { return }
        deselectActiveThread()
        _ = threads.remove(at: index)
        delegate?.updateUI(animation: true, reloadSections: false)
        animateObjectWillChange()
    }

    public func delete(_ threadId: Int?) {
        guard let threadId = threadId else { return }
        let conversation = threads.first(where: { $0.id == threadId}) ?? AppState.shared.objectsContainer.archivesVM.archives.first(where: { $0.id == threadId })
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
            
            if AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.threadId == threadId {
                AppState.shared.objectsContainer.navVM.remove(threadId: threadId)
            }
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
                Task { [weak self] in
                    guard let self = self else { return }
                    await ThreadCalculators.reCalculateUnreadCount(threads[index])
                    if let index = firstIndex(Int(key)) {
                        self.delegate?.unreadCountChanged(conversation: threads[index])
                    }
                    threads[index].animateObjectWillChange()
                }
            }
        }
        lazyList.setLoading(false)
        log("SERVER unreadCount: \(response.result)")
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
            arrItem.metadata = thread.metadata
            arrItem.title = replacedEmoji
            arrItem.titleRTLString = ThreadCalculators.calculateTitleRTLString(replacedEmoji, thread)
            arrItem.closed = thread.closed
            arrItem.time = thread.time ?? arrItem.time
            arrItem.userGroupHash = thread.userGroupHash ?? arrItem.userGroupHash
            arrItem.description = thread.description

            /// Check if the index still exist to prevent a crash.
            if threads.indices.contains(index) {
                threads[index] = arrItem
                delegate?.reloadCellWith(conversation: threads[index])
                threads[index].animateObjectWillChange()
            }

            // Update active thread if it is open
            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = arrItem.toStruct()
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            activeThread?.delegate?.refetchImageOnUpdateInfo()

            // Update active thread detail view if it is open
            if let detailVM = navVM.detailViewModel(threadId: threadId) {
                detailVM.updateThreadInfo(arrItem.toStruct())
            }
            animateObjectWillChange()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) async {
        if let index = firstIndex(thread.id) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            threads[index].time = thread.lastMessageVO?.time ?? thread.time
            threads[index].animateObjectWillChange()
            recalculateAndAnimate(threads[index])
            animateObjectWillChange()

            /// Sort is essential after deleting the last message of the thread.
            /// It will cause to move down by sorting if the previous message is older another thread
            await sortInPlace()
            delegate?.updateUI(animation: true, reloadSections: false)
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = self.firstIndex(id) {
            deselectActiveThread()
            threads[index].animateObjectWillChange()
            recalculateAndAnimate(threads[index])
            
            threads.remove(at: index)
            delegate?.updateUI(animation: true, reloadSections: false)
            animateObjectWillChange()
            AppState.shared.objectsContainer.navVM.remove(threadId: id)
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
                    let activeVM = navVM.viewModel(for: response.subjectId ?? -1)
                    activeVM?.delegate?.onUnreadCountChanged()
                }
            }
            threads[index] = thread
            delegate?.reloadCellWith(conversation: thread)
            threads[index].animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    func onCancelTimer(key: String) {
        if lazyList.isLoading {
            lazyList.setLoading(false)
        }
    }

    /// There is a chance another user join to this public group, so we have to check if the thread is already exists.
    public func onJoinedToPublicConversation(_ response: ChatResponse<Conversation>) async {
        if let conversation = response.result {
            if conversation.participants?.first?.id == myId, response.pop(prepend: JOIN_TO_PUBLIC_GROUP_KEY) != nil {
                AppState.shared.objectsContainer.navVM.append(thread: conversation)
            }
            
            if let id = conversation.id, let conversation = await GetSpecificConversationViewModel().getNotActiveThreads(id) {
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
            
            /// Pop detail view and thread view at the same time
            if navVM.detailsStack.last?.threadVM?.id == conversationId {
                navVM.detailsStack.last?.dismissBothDetailAndThreadProgramatically()
            } else if navVM.presentedThreadViewModel?.threadId == conversationId {
                /// Pop only the thread view if the presented is the thread.
                navVM.remove(threadId: conversationId)
            }
        } else if let participant = participant {
            threadVM?.participantsViewModel.removeParticipant(participant)
        }
    }

    func onClosed(_ response: ChatResponse<Int>) {
        guard let threadId = response.result else { return }
        if let index = threads.firstIndex(where: { $0.id == threadId}) {
            threads[index].closed = true
            delegate?.reloadCellWith(conversation: threads[index])
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
        log("SERVER OnSeen: \(response.result)")
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
            delegate?.reloadCellWith(conversation: threads[threadIndex])
            animateObjectWillChange()
        }
    }

    public func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            threads[threadIndex].pinMessage = nil
            delegate?.reloadCellWith(conversation: threads[threadIndex])
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
    
    func recalculateAndAnimate(_ thread: CalculatedConversation) {
        Task { [weak self] in
            guard let self = self else { return }
            await ThreadCalculators.reCalculate(thread, myId, navVM.selectedId)
            self.delegate?.reloadCellWith(conversation: thread)
            thread.animateObjectWillChange()
        }
    }
    
    public func calculateAppendSortAnimate(_ thread: Conversation) async {
        let calThreads = await ThreadCalculators.calculate(conversations: [thread], myId: myId)
        let appendedThreads = await appendThreads(newThreads: calThreads, oldThreads: threads)
        let sorted = await sort(threads: appendedThreads, serverSortedPins: serverSortedPins)
        threads = sorted
        delegate?.updateUI(animation: false, reloadSections: false)
        for conversation in threads {
            addImageLoader(conversation)
        }
        animateObjectWillChange()
    }

    func log(_ string: String) {
        Logger.log(title: "ThreadsViewModel", message: string)
    }
    
    public func setSelected(for conversationId: Int, selected: Bool) {
        if let thread = threads.first(where: {$0.id == conversationId}) {
            /// Select / Deselect a thread to remove/add bar and selected background color
            thread.isSelected = selected
            delegate?.selectionChanged(conversation: thread)
            thread.animateObjectWillChange()
        }
    }
    
    /// Deselect a selected thread will force the SwiftUI to
    /// remove the selected color before removing the row reference.
    private func deselectActiveThread() {
        if let index = threads.firstIndex(where: {$0.isSelected}) {
            threads[index].isSelected = false
            delegate?.reloadCellWith(conversation: threads[index])
            threads[index].animateObjectWillChange()
        }
    }
    
    private func addImageLoader(_ conversation: CalculatedConversation) {
        if let id = conversation.id, conversation.imageLoader == nil, let image = conversation.image {
            let viewModel = ImageLoaderViewModel(conversation: conversation)
            conversation.imageLoader = viewModel
            viewModel.onImage = { [weak self] image in
                Task { @MainActor [weak self] in
                    self?.delegate?.updateImage(image: image, id: id)
                }
            }
            viewModel.fetch()
        }
    }
    
    public func imageLoader(for id: Int) -> ImageLoaderViewModel? {
        threads.first(where: { $0.id == id })?.imageLoader as? ImageLoaderViewModel
    }
    
    public func toggleArchive(_ conversation: Conversation) { AppState.shared.objectsContainer.archivesVM.toggleArchive(conversation)
        if conversation.isArchive == false || conversation.isArchive == nil {
            let leadingView = Image(systemName: "tray.and.arrow.up")
            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: leadingView,
                                                                message: "ArchivedTab.guide".bundleLocalized(),
                                                                messageColor: Color("text_primary") ?? Color.white,
                                                                duration: .slow)
        }
    }
    
    public func onTapped(conversation: CalculatedConversation) {
        /// Ignore opening the same thread on iPad/MacOS, if so it will lead to a bug.
        if conversation.id == AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.threadId { return }
        
        if AppState.shared.objectsContainer.navVM.canNavigateToConversation() {
            /// to update isSeleted for bar and background color
            setSelected(for: conversation.id ?? -1, selected: true)
            AppState.shared.objectsContainer.navVM.switchFromThreadList(thread: conversation.toStruct())
        }
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
