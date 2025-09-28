//
//  ArchiveThreadsViewModel.swift
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

@MainActor
public final class ArchiveThreadsViewModel: ObservableObject {
    public private(set) var cancelable: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public private(set) var lazyList = LazyListViewModel()
    public var shimmerViewModel = ShimmerViewModel(delayToHide: 0, repeatInterval: 0.5)
    public private(set) var archives: ContiguousArray<CalculatedConversation> = []
    private var threadsVM: ThreadsViewModel { AppState.shared.objectsContainer.threadsVM }
    private var wasDisconnected = false
    private var cache: Bool = true
    public weak var delegate: UIThreadsViewControllerDelegate?
    
    @Published public var scrollToId: Int?
    
    // MARK: Computed properties
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }
    private var myId: Int { AppState.shared.user?.id ?? -1 }
    
    public init() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onThreadEvent(event)
                }
            }
            .store(in: &cancelable)
        
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)
        
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    self?.onCancelTimer(key: key)
                }
            }
            .store(in: &cancelable)
        
        NotificationCenter.system.publisher(for: .system)
            .compactMap { $0.object as? SystemEventTypes }
            .sink { [weak self] systemMessageEvent in
                Task { [weak self] in
                    await self?.onThreadSystemEvent(systemMessageEvent)
                }
            }
            .store(in: &cancelable)
        
        AppState.shared.$connectionStatus
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onConnectionStatusChanged(event)
                }
            }
            .store(in: &cancelable)
    }

    public func loadMore(id: Int?) async {
        if !lazyList.canLoadMore(id: id) { return }
        lazyList.prepareForLoadMore()
        await getArchivedThreads()
    }

    private func onThreadEvent(_ event: ThreadEventTypes?) async {
        switch event {
        case .archive(let response):
            await onArchive(response)
        case .unArchive(let response):
            await onUNArchive(response)
        case let .lastMessageDeleted(response), let .lastMessageEdited(response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
            
        case .lastSeenMessageUpdated(let response):
            await onLastSeenMessageUpdated(response)
        case .left(let response):
            onLeave(response)
        case .closed(let response):
            onClosed(response)
        case .updatedInfo(let response):
            onUpdateThreadInfo(response)
        case .deleted(let response):
            onDeleteThread(response)
        case .unreadCount(let response):
            await onUnreadCounts(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .new(let chatResponse):
            onNewMessage(chatResponse)
        case .seen(let response):
            onSeen(response)
        case .deleted(let response):
            await onMessageDeleted(response)
        case .pin(let response):
            onPinMessage(response)
        case .unpin(let response):
            onUNPinMessage(response)
        default:
            break
        }
    }

    public func toggleArchive(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.isArchive == false {
            archive(threadId)
        } else {
            unarchive(threadId)
        }
    }

    public func archive(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.archive(.init(subjectId: threadId))
        }
    }

    public func unarchive(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.unarchive(.init(subjectId: threadId))
        }
    }
    
    public func getArchivedThreads(withQueue: Bool = false, keepOrder: Bool = false) async {
        /// Check if user didn't logged out
        if !TokenManager.shared.isLoggedIn { return }
        if !firstSuccessResponse {
            shimmerViewModel.show()
        }
        lazyList.setLoading(true)
        do {
            
            let req = ThreadsRequest(count: lazyList.count, offset: lazyList.offset, archived: true, cache: cache)
            let conversations = try await GetThreadsReuqester().getCalculated(req: req,
                                                                              withCache: false,
                                                                              queueable: withQueue,
                                                                              myId: myId,
                                                                              navSelectedId: navVM.selectedId,
                                                                              keepOrder: keepOrder)
            if wasDisconnected {
                /// Clear and remove all threads
                archives.removeAll()
            }
                        
            await onArchives(conversations)
            
            moveToTopIfWasDisconnected(topItemId: archives.first?.id)
            
            wasDisconnected = false
        } catch {
            log("Failed to get threads with error: \(error.localizedDescription)")
        }
    }
    
    private func onArchives(_ conversations: [CalculatedConversation]) async {
        let hasAnyResults = conversations.count ?? 0 > 0
        
        let navSelectedId = navVM.selectedId
        let newThreads = await appendThreads(
            newThreads: conversations,
            oldThreads: wasDisconnected ? [] : archives
        )
        let sorted = await sort(threads: newThreads)
        let threshold = await splitThreshold(sorted)
      
        self.archives = sorted
        delegate?.updateUI(animation: false, reloadSections: false)
        for conversation in archives {
            addImageLoader(conversation)
        }
        updatePresentedViewModels(archives)
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
    }
    
    private func moveToTopIfWasDisconnected(topItemId: Int?) {
        if wasDisconnected {
            /// scroll To first if we were way down in the list to show correct row
            scrollToId = topItemId
        }
    }

    private func onArchive(_ response: ChatResponse<Int>) async {
        if response.result != nil, response.error == nil, let index = threadsVM.threads.firstIndex(where: {$0.id == response.result}) {
            var conversation = threadsVM.threads[index]
            conversation.isArchive = true
            conversation.mute = true
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.reCalculate(conversation, myId, navVM.selectedId)
            archives.append(calThreads)
            
            /// Sort archives after appending.
            self.archives = await sort(threads: archives)
        
            threadsVM.removeThread(threadsVM.threads[index])
            /// threadsVM.threads.removeAll(where: {$0.id == response.result}) /// Do not remove this line and do not use remove(at:) it will cause 'Precondition failed Orderedset'
            await threadsVM.sortInPlace()
            threadsVM.animateObjectWillChange()
            delegate?.updateUI(animation: true, reloadSections: false)
            animateObjectWillChange()
        } else if
            let conversationId = response.result,
            let conversation = try? await GetThreadsReuqester().get(.init(threadIds: [conversationId])).first {
            /// New conversation has been archived by another device so we have to fetch the conversation
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.calculate(conversation, myId)
            archives.append(calThreads)
            delegate?.updateUI(animation: false, reloadSections: false)
        }
    }

    public func onUNArchive(_ response: ChatResponse<Int>) async {
        if response.result != nil, response.error == nil, let index = archives.firstIndex(where: {$0.id == response.result}) {
            var conversation = archives[index]
            conversation.isArchive = false
            conversation.mute = false
            archives.remove(at: index)
            delegate?.updateUI(animation: true, reloadSections: false)
            animateObjectWillChange()
           
            await threadsVM.append(conversation)
        }
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
    public func sort(threads: ContiguousArray<CalculatedConversation>) async -> ContiguousArray<CalculatedConversation> {
        var threads = threads
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && ($1.pin == false || $1.pin == nil) })
        return threads
    }
    
    private func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if status == .connected {
            // After connecting again
            // We should call this method because if the token expire all the data inside InMemory Cache of the SDK is invalid
            wasDisconnected = true
            /// We sleep for 1 second to prevent getting banned by the server after reconnecting.
            try? await Task.sleep(for: .seconds(1))
            deselectActiveThread()
            await refresh()
        } else if status == .disconnected && !firstSuccessResponse {
            // To get the cached version of the threads in SQLITE.
            await getArchivedThreads()
        }
    }

    private func onCancelTimer(key: String) {
        if lazyList.isLoading {
            lazyList.setLoading(false)
        }
    }
    
    public func refresh() async {
        cache = false
        lazyList.reset()
        await getArchivedThreads(withQueue: true, keepOrder: true)
        cache = true
    }

    private func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = archives.firstIndex(where: {$0.id == message.conversation?.id}) {
            let reference = archives[index]
            let old = reference.toStruct()
            let updated = reference.updateOnNewMessage(response.result ?? .init(), meId: myId)
            archives[index] = updated
            archives[index].animateObjectWillChange()
            delegate?.unreadCountChanged(conversation: archives[index])
            recalculateAndAnimate(updated)
            updateActiveConversationOnNewMessage([message], updated.toStruct(), old)
            delegate?.reloadCellWith(conversation: archives[index])
            animateObjectWillChange()
            delegate?.updateUI(animation: false, reloadSections: false)
        }
    }
    
    private func updateActiveConversationOnNewMessage(_ messages: [Message], _ updatedConversation: Conversation, _ oldConversation: Conversation?) {
        let activeVM = navVM.presentedThreadViewModel?.viewModel
        if updatedConversation.id == activeVM?.id {
            Task { [weak self] in
                guard let self = self else { return }
                await activeVM?.historyVM.onNewMessage(messages, oldConversation, updatedConversation)
            }
        }
    }
    
    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = firstIndex(thread.id) {
            archives[index].lastMessage = thread.lastMessage
            archives[index].lastMessageVO = thread.lastMessageVO
            archives[index].animateObjectWillChange()
            recalculateAndAnimate(archives[index])
            delegate?.reloadCellWith(conversation: archives[index])
            animateObjectWillChange()
        }
    }
    
    private func onLeave(_ response: ChatResponse<User>) {
        if response.result?.id == myId {
            deselectActiveThread()
            archives.removeAll(where: {$0.id == response.subjectId})
            delegate?.updateUI(animation: true, reloadSections: true)
            animateObjectWillChange()
        }
    }
    
    private func onClosed(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = archives.firstIndex(where: { $0.id == id }) {
            archives[index].closed = true
            let activeThread = navVM.viewModel(for: id)
            activeThread?.thread = archives[index].toStruct()
            activeThread?.delegate?.onConversationClosed()
            delegate?.reloadCellWith(conversation: archives[index])
            animateObjectWillChange()
        }
    }
    
    private func onUpdateThreadInfo(_ response: ChatResponse<Conversation>) {
        if let thread = response.result,
           let threadId = thread.id,
           let index = archives.firstIndex(where: {$0.id == threadId}) {
            
            let replacedEmoji = thread.titleRTLString.stringToScalarEmoji()
            /// In the update thread info, the image property is nil and the metadata link is been filled by the server.
            /// So to update the UI properly we have to set it to link.
            var arrItem = archives[index]
            if let metadatImagelink = thread.metaData?.file?.link {
                arrItem.image = metadatImagelink
            }
            arrItem.title = replacedEmoji
            arrItem.titleRTLString = ThreadCalculators.calculateTitleRTLString(replacedEmoji, thread)
            arrItem.closed = thread.closed
            arrItem.time = thread.time ?? arrItem.time
            arrItem.userGroupHash = thread.userGroupHash ?? arrItem.userGroupHash
            arrItem.description = thread.description

            let calculated = ThreadCalculators.calculate(arrItem.toStruct(), myId)
            
            archives[index] = calculated
            archives[index].animateObjectWillChange()

            // Update active thread if it is open
            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = calculated.toStruct()
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            activeThread?.delegate?.refetchImageOnUpdateInfo()

            // Update active thread detail view if it is open
            if let detailVM = navVM.detailViewModel(threadId: threadId) {
                detailVM.updateThreadInfo(calculated.toStruct())
            }
            delegate?.reloadCellWith(conversation: archives[index])
            animateObjectWillChange()
        }
    }
    
    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if let threadId = response.subjectId, let index = archives.firstIndex(where: {$0.id == threadId }) {
            deselectActiveThread()
            archives.remove(at: index)
            delegate?.updateUI(animation: true, reloadSections: true)
            animateObjectWillChange()
            
            if AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.threadId == threadId {
                AppState.shared.objectsContainer.navVM.remove(threadId: threadId)
            }
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
    
    func onUnreadCounts(_ response: ChatResponse<[String : Int]>) async {
        response.result?.forEach { key, value in
            if let index = firstIndex(Int(key)) {
                archives[index].unreadCount = value
                Task { [weak self] in
                    guard let self = self else { return }
                    await ThreadCalculators.reCalculateUnreadCount(archives[index])
                    delegate?.reloadCellWith(conversation: archives[index])
                    archives[index].animateObjectWillChange()
                }
            }
        }
        log("SERVER unreadCount: \(response.result)")
    }
    
    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) async {
        if let index = firstIndex(response.subjectId) {
            var thread = archives[index]
            if response.result?.unreadCount == 0, thread.mentioned == true {
                thread.mentioned = false
            }
            if response.result?.lastSeenMessageTime ?? 0 > thread.lastSeenMessageTime ?? 0 {
                thread.lastSeenMessageTime = response.result?.lastSeenMessageTime
                thread.lastSeenMessageId = response.result?.lastSeenMessageId
                thread.lastSeenMessageNanos = response.result?.lastSeenMessageNanos
                let newCount = response.result?.unreadCount ?? response.contentCount ?? 0
                if newCount <= archives[index].unreadCount ?? 0 {
                    thread.unreadCount = newCount
                    await ThreadCalculators.reCalculateUnreadCount(archives[index])
                    
                    /// If the user open up the same thread on two devices at the same time,
                    /// and on of them is at the bottom of the thread and one is at top,
                    /// the one at bottom will send seen and respectively when we send seen unread count will be reduced,
                    /// so on another thread we should catch this new unread count and update the thread.
                    let activeVM = navVM.viewModel(for: response.subjectId ?? -1)
                    activeVM?.delegate?.onUnreadCountChanged()
                }
            }
            archives[index] = thread
            delegate?.reloadCellWith(conversation: thread)
            archives[index].animateObjectWillChange()
            animateObjectWillChange()
        }
    }
   
    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        /// Update the status bar in ThreadRow when a receiver seen a message, and in the sender side we have to update the UI.
        let isMe = myId == response.result?.participantId
        if !isMe, let index = archives.firstIndex(where: {$0.lastMessageVO?.id == response.result?.messageId}) {
            archives[index].lastMessageVO?.delivered = true
            archives[index].lastMessageVO?.seen = true
            archives[index].partnerLastSeenMessageId = response.result?.messageId
            recalculateAndAnimate(archives[index])
        }
        log("SERVER OnSeen: \(response.result)")
    }
    
    /// This method only reduce the unread count if the deleted message has sent after lastSeenMessageTime.
    public func onMessageDeleted(_ response: ChatResponse<Message>) async {
        guard let index = archives.firstIndex(where: { $0.id == response.subjectId }) else { return }
        var thread = archives[index]
        if response.result?.time ?? 0 > thread.lastSeenMessageTime ?? 0, thread.unreadCount ?? 0 >= 1 {
            thread.unreadCount = (thread.unreadCount ?? 0) - 1
            await ThreadCalculators.reCalculateUnreadCount(archives[index])
            archives[index] = thread
            archives[index].animateObjectWillChange()
            recalculateAndAnimate(thread)
        }
    }

    public func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            archives[threadIndex].pinMessage = response.result
            archives[threadIndex].animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    public func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            archives[threadIndex].pinMessage = nil
            archives[threadIndex].animateObjectWillChange()
            animateObjectWillChange()
        }
    }
    
    public func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        archives.firstIndex(where: { $0.id == threadId ?? -1 })
    }
    
    public func calculateAppendSortAnimate(_ thread: Conversation) async {
        let calThreads = await ThreadCalculators.calculate(conversations: [thread], myId: myId, navSelectedId: navVM.selectedId, nonArchives: false)
        let appendedThreads = await appendThreads(newThreads: calThreads, oldThreads: archives)
        let sorted = await sort(threads: appendedThreads)
        archives = sorted
        animateObjectWillChange()
    }
    
    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = self.firstIndex(id) {
            deselectActiveThread()
            archives[index].animateObjectWillChange()
            recalculateAndAnimate(archives[index])
            
            archives.remove(at: index)
            delegate?.updateUI(animation: true, reloadSections: false)
            animateObjectWillChange()
        }
    }
    
    public func onNewForwardMessage(conversationId: Int, forwardMessage: Message) async {
        if let index = firstIndex(conversationId) {
            let reference = archives[index]
            let old = reference.toStruct()
            let updated = reference.updateOnNewMessage(forwardMessage, meId: myId)
            archives[index] = updated
            archives[index].animateObjectWillChange()
            if updated.pin == false {
                let sorted = await sort(threads: archives)
                self.archives = sorted
            }
            recalculateAndAnimate(updated)
            animateObjectWillChange() /// We should update the ThreadList view because after receiving a message, sorting has been changed.
        }
    }
    
    /// Deselect a selected thread will force the SwiftUI to
    /// remove the selected color before removing the row reference.
    private func deselectActiveThread() {
        if let index = archives.firstIndex(where: {$0.isSelected}) {
            archives[index].isSelected = false
            archives[index].animateObjectWillChange()
        }
    }
    
    public func onTapped(conversation: CalculatedConversation) {
        /// Ignore opening the same thread on iPad/MacOS, if so it will lead to a bug.
        if conversation.id == AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.threadId { return }
        
        if AppState.shared.objectsContainer.navVM.canNavigateToConversation() {
            /// to update isSeleted for bar and background color
            setSelected(for: conversation.id ?? -1, selected: true)
            
            /// We just push when we are in archives list, beacause the archive list itself has been pushed
            /// So if we use switch version it will pop all and archive list will be popped out which is wrong.
            AppState.shared.objectsContainer.navVM.append(thread: conversation.toStruct())
        }
    }
    
    public func setSelected(for conversationId: Int, selected: Bool) {
        if let thread = archives.first(where: {$0.id == conversationId}) {
            /// Select / Deselect a thread to remove/add bar and selected background color
            thread.isSelected = selected
            delegate?.selectionChanged(conversation: thread)
            thread.animateObjectWillChange()
        }
    }
    
    private func addImageLoader(_ conversation: CalculatedConversation) {
        if let id = conversation.id, conversation.imageLoader == nil, let image = conversation.image {
            let httpsImage = image.replacingOccurrences(of: "http://", with: "https://")
            let name = conversation.computedTitle
            let config = ImageLoaderConfig(
                url: httpsImage,
                metaData: conversation.metadata,
                userName: String.splitedCharacter(name ?? ""),
                forceToDownloadFromServer: true
            )
            let viewModel = ImageLoaderViewModel(config: config)
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
        archives.first(where: { $0.id == id })?.imageLoader as? ImageLoaderViewModel
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
    
    private func updateActiveThreadAfterDisconnect() {
        if wasDisconnected,
           let activeVM = navVM.presentedThreadViewModel?.viewModel,
           let updatedThread = archives.first(where: {($0.id ?? 0) as Int == activeVM.id as Int}) {
            activeVM.thread = updatedThread.toStruct()
            activeVM.delegate?.onUnreadCountChanged()
        }
    }
    
    func onThreadSystemEvent(_ event: SystemEventTypes) async {
        switch event {
        case .systemMessage(let chatResponse):
            guard let result = chatResponse.result else { return }
            if let conversation = archives.first(where: { $0.id == chatResponse.subjectId }) {
                delegate?.setEvent(smt: result.smt, conversation: conversation)
            }
        default:
            break
        }
    }
}

private extension ArchiveThreadsViewModel {
    func log(_ string: String) {
        Logger.log(title: "ArchiveThreadsViewModel", message: string)
    }
}
