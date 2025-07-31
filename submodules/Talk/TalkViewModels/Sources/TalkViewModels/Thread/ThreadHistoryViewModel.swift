//
//  ThreadHistoryViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Foundation
import Chat
import Logger
import TalkModels
import Combine
import UIKit
import CoreGraphics

@MainActor
public final class ThreadHistoryViewModel {
    // MARK: Stored Properties
    internal weak var viewModel: ThreadViewModel?
    public weak var delegate: HistoryScrollDelegate?
    public private(set) var sections: ContiguousArray<MessageSection> = .init()
    private var deleteQueue = DeleteMessagesQueue()

    private var threshold: CGFloat = 800
    private var topLoading = false
    private var centerLoading = false
    private var bottomLoading = false
    private var hasNextTop = true
    private var hasNextBottom = true
    private let count: Int = 25
    private var isFetchedServerFirstResponse: Bool = false
    
    private var cancelable: Set<AnyCancellable> = []
    private var hasSentHistoryRequest = false
    internal var seenVM: HistorySeenViewModel? { viewModel?.seenVM }
    @VisibleActor
    private var visibleTracker = VisibleMessagesTracker()
    private var highlightVM = ThreadHighlightViewModel()
    private var lastItemIdInSections = 0
    private let keys = RequestKeys()
    private var isReattachedUploads = false
    
    private var lastScrollTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.5 // 500 milliseconds

    // MARK: Computed Properties
    private var thread: Conversation = Conversation()
    private var threadId: Int = -1
    
    // MARK: Initializer
    nonisolated public init(thread: Conversation, readOnly: Bool = false) {
        self.thread = thread
        threadId = thread.id ?? -1
        Task { @MainActor in
            await setupVisible()
            highlightVM.setup(self)
            setupNotificationObservers()
            deleteQueue.viewModel = self
        }
    }
}

extension ThreadHistoryViewModel: StabledVisibleMessageDelegate {
    func onStableVisibleMessages(_ messages: [HistoryMessageType]) async {
        let invalidVisibleMessages = await getInvalidVisibleMessages().compactMap({$0 as? Message})
        if invalidVisibleMessages.count > 0 {
            viewModel?.reactionViewModel.fetchReactions(messages: invalidVisibleMessages, withQueue: false)
        }
    }
}

extension ThreadHistoryViewModel {
    internal func getInvalidVisibleMessages() async -> [HistoryMessageType] {
        var invalidMessages: [Message] =  []
        let list = await visibleTracker.visibleMessages.compactMap({$0 as? Message})
        for message in list {
            if let vm = sections.messageViewModel(for: message.id ?? -1), await vm.isInvalid {
                invalidMessages.append(message)
            }
        }
        return invalidMessages
    }
}

// MARK: Setup/Start
extension ThreadHistoryViewModel {
    @VisibleActor
    private func setupVisible() {
        visibleTracker.delegate = self
    }
    
    // MARK: Scenarios Common Functions
    public func start() {
        /// After deleting a thread it will again tries to call histroy,
        /// we should prevent it from calling it to not get any error.
        if isFetchedServerFirstResponse == false {
            startFetchingHistory()
            viewModel?.threadsViewModel?.clearAvatarsOnSelectAnotherThread()
        } else if isFetchedServerFirstResponse == true {
            /// try to open reply privately if user has tried to click on  reply privately and back button multiple times
            /// iOS has a bug where it tries to keep the object in the memory, so multiple back and forward doesn't lead to destroy the object.
            moveToMessageTimeOnOpenConversation()
        }
    }

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    private func startFetchingHistory() {
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let isSimulatedThread = viewModel?.isSimulatedThared == true
        let hasAnythingToLoadOnOpen = AppState.shared.appStateNavigationModel.moveToMessageId != nil
        moveToMessageTimeOnOpenConversation()
        showEmptyThread(show: false)
        if isSimulatedThread {
            showEmptyThread(show: true)
            showCenterLoading(false)
            return 
        }
        if sections.count > 0 || hasAnythingToLoadOnOpen { return }
        Task { @MainActor [weak self] in
            /// We won't set this variable to prevent duplicate call on connection status for the first time.
            /// If we don't sleep we will get a crash.
            try? await Task.sleep(for: .microseconds(500))
            self?.hasSentHistoryRequest = true
        }
        if let savedScrollModel = viewModel?.threadsViewModel?.saveScrollPositionVM.savedPosition(threadId) {
            Task {
                do {
                    try await tryScrollPositionScenario(savedScrollModel)
                } catch {
                    log("An exception happened during move to the saved scroll position!")
                }
            }
            return
        }
        tryFirstScenario()
        trySecondScenario()
        trySeventhScenario()
        tryEightScenario()
        tryNinthScenario()
        reattachUploads()
    }
}

// MARK: Scenarios
extension ThreadHistoryViewModel {

    private func tryFirstScenario() {
        guard
            hasUnreadMessage(),
            let time = viewModel?.thread.lastSeenMessageTime,
            let id = viewModel?.thread.lastSeenMessageId
        else { return }

        Task {
            await runFirstScenario(time: time, id: id)
        }
    }
    
    // MARK: Scenario 1
    private func runFirstScenario(time: UInt, id: Int) async {
        do {
            showCenterLoading(true)
            
            let topVMS = try await onTopToTime(toTime: (thread.lastSeenMessageTime ?? 0).advanced(by: 1))
            let bottomVMS = try await onBottomFromTime(fromTime: (thread.lastSeenMessageTime ?? 0).advanced(by: 1))
            let vm = await createUnreadBanner(time: time, id: id, viewModel: viewModel ?? .init(thread: thread))
            let vms = topVMS + [vm] + bottomVMS
            
            appendSort(vms)
            
            let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: 0, vms)
            
            if let indexPath = sections.viewModelAndIndexPath(for: LocalId.unreadMessageBanner.rawValue)?.indexPath {
                delegate?.inserted(tuple.sections, tuple.rows, indexPath, .top)
            }
            
            showCenterLoading(false)
            
            /// Fetch reactions
            fetchReactions(messages: vms.flatMap({$0.message as? Message}))
            
            await prepareAvatars(vms)
        } catch {
            showCenterLoading(false)
        }
    }
    
    private func trySecondScenario() {
        guard isLastMessageEqualToLastSeen(),
              thread.id != LocalId.emptyThread.rawValue
        else { return }
        Task {
            await runSecondScenario()
        }
    }
    
    // MARK: Scenario 2
    /// We have to fetch with offset not time, because we want to store them inside the cahce.
    /// The cache system will only work if and only if it can store the first request last message.
    /// With middle fetcher we can not store the last message with top request even we fetch it with
    /// by advance 1, in retriving it next time, the checking system will examaine it with exact time not advance time!
    /// Therefore the cache will always the request from the server.
    private func runSecondScenario() async {
        do {
            log("trySecondScenario")
            
            showCenterLoading(true)
            
            /// Appned to the list
            let vms = try await onMoreTopWithOffset()
            appendSort(vms)
            
            /// Update delegate insertion
            let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: 0, vms)
            viewModel?.scrollVM.disableExcessiveLoading()
            
            /// Insert and scroll to the last thread message.
            if let indexPath = lastMessageIndexPath {
                delegate?.inserted(tuple.sections, tuple.rows, indexPath, .bottom)
            }
            
            showCenterLoading(false)
            
            /// Fetch reactions
            fetchReactions(messages: vms.flatMap({$0.message as? Message}))
            
            await prepareAvatars(vms)
            
            /// In this scenario we do not have any unread messages,
            /// so there is no need to show bottom loading even once.
            setHasMoreBottom(false)
        } catch {
            showCenterLoading(false)
        }
    }
    
    // MARK: Scenario 3 or 4 more top/bottom.
    
    // MARK: Scenario 5
    private func tryFifthScenario(status: ConnectionStatus) async {
        do {
            /// Show bottom loading.
            showBottomLoading(true)
            
            /// Get new messages if there are any.
            let vms = try await onReconnectViewModels()
            
            /// If now new message is available so we need to return.
            if vms.isEmpty {
                showBottomLoading(false)
                return
            }
            
            /// Reorder the banner to new position.
            removeOldBanner()
            
            let oldMessage = sections.last?.vms.last?.message as? Message
            if let time = oldMessage?.time, let id = thread.lastSeenMessageId{
                let vm = await createUnreadBanner(time: time, id: id, viewModel: viewModel ?? .init(thread: thread))
                sections[sections.count - 1].vms.append(vm)
                delegate?.inserted(at: IndexPath(row: sections[sections.count - 1].vms.count, section: sections.count - 1))
            }
            
            let beforeSectionCount = sections.count
            let shouldUpdateOldBottomSection = StitchAvatarCalculator.forBottom(sections, vms)
            let beforeAppnedLastVM = sections.last?.vms.last
            /// Set isFirst message of the user befor join at bottom if the prev owner is different
            /// If the user reconnect less than 45 seconds there is a chance that chat server sent
            /// onNewMessage event, so in append message in onNewMessage
            /// we will take care of this situation there too.
            vms.first?.calMessage.isFirstMessageOfTheUser = vms.first?.message.ownerId != beforeAppnedLastVM?.message.ownerId
            
            /// Appned to the list.
            appendSort(vms)
            
            /// Disable excessive loading
            viewModel?.scrollVM.disableExcessiveLoading()
            
            /// Insert with no scroll.
            let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, vms)
            if let firstIndexPath = tuple.rows.first {
                delegate?.inserted(tuple.sections, tuple.rows, .bottom, nil)
            }
            
            /// Reload if sntitchi point has changed.
            if let row = shouldUpdateOldBottomSection, let indexPath = sections.indexPath(for: row) {
                delegate?.reloadData(at: indexPath)
            }
            
            /// Hide bottom loading and set hasNext
            showBottomLoading(false)
            setHasMoreBottom(vms.count >= count)
            
            /// Fetch reactions
            fetchReactions(messages: vms.flatMap({$0.message as? Message}))
            
            await prepareAvatars(vms)
        } catch {
            showBottomLoading(false)
        }
    }

    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true, moveToBottom: Bool = false) async {
        /// 1- Move to a message locally if it exists.
        if moveToBottom, !sections.isLastSeenMessageExist(thread: thread) {
            removeAllSections()
        } else if let uniqueId = canMoveToMessageLocally(messageId) {
            showCenterLoading(false) // To hide center loading if the uer click on reply privately header to jump back to the thread.
            moveToMessageLocally(uniqueId, messageId, moveToBottom, highlight, true)
            return
        }
        
        await doMoveToTime(time, messageId, highlight: highlight, moveToBottom: moveToBottom)
    }
    
    // MARK: Scenario 6
    private func doMoveToTime(_ time: UInt, _ messageId: Int, highlight: Bool, moveToBottom: Bool) async {
        do {
            viewModel?.scrollVM.isAtBottomOfTheList = false
            log("The message id to move to is not exist in the list")
            
            /// Remove all old sections
            removeAllSections()
            
            /// Show center loading.
            showCenterLoading(true)
            
            /// Fetch Top, Bottom and join them together.
            let topVMS = try await onTopToTime(toTime: time)
            let bottomVMS = try await onBottomFromTime(fromTime: time)
            let vms = topVMS + bottomVMS
            
            /// Append it to the sections array.
            appendSort(vms)
            
            /// Calculate appended sections and rows.
            let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: 0, vms)
            
            /// If the messageId paramter set to zero it we can not find the message,
            /// so we use time to move to first message of the day.
            let section = sections.sectionIndexByDate(time.date) ?? 0
            let message = messageId == 0 ? sections[section].vms.first?.message : vms.first(where: {$0.id == messageId})?.message
            
            /// Update UITableView and scroll to the disered indexPath.
            if let message = message, let indexPath = sections.viewModelAndIndexPath(for: message.id ?? -1)?.indexPath {
                delegate?.inserted(tuple.sections, tuple.rows, indexPath, .top)
            }
            
            /// Animate to show hightlight if is needed.
            let uniqueId = message?.uniqueId ?? ""
            highlightVM.showHighlighted(uniqueId, message?.id ?? -1, highlight: highlight, position: .middle)
            
            /// Force to show move to bottom button,
            /// because we know that we are not at the end of the thread.
            viewModel?.delegate?.showMoveToBottom(show: true)
            
            /// Show empty thread banner, if it's empty
            delegate?.emptyStateChanged(isEmpty: vms.isEmpty)
            
            /// Hide center loading.
            showCenterLoading(false)
            
            /// Set we have more top or bottom rows.
            setHasMoreTop(topVMS.count >= count)
            setHasMoreBottom(bottomVMS.count >= count)
            
            /// If requested messageId to move to is equal to last message of the thread
            /// it means that we don't have more bottom.
            if messageId == thread.lastMessageVO?.id {
                setHasMoreBottom(false)
            }
            
            /// Fetch reactions
            fetchReactions(messages: vms.flatMap({$0.message as? Message}))
            
            await prepareAvatars(vms)
            
        } catch {
            showCenterLoading(false)
        }
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    private func moveToMessageLocally(_ uniqueId: String, _ messageId: Int, _ moveToBottom: Bool, _ highlight: Bool, _ animate: Bool = false) {
        highlightVM.showHighlighted(uniqueId,
                                          messageId,
                                          highlight: highlight,
                                          position: moveToBottom ? .bottom : .top,
                                          animate: animate)
    }

    
    private func trySeventhScenario() {
        guard thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 else { return }
        Task {
            await runSeventhScenario()
        }
    }
    
    // MARK: Scenario 7
    /// When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug or when the conversation is empty.
    private func runSeventhScenario() async {
        do {
            showCenterLoading(true)
            let vms = try await onFetchByOffset()
    
            appendSort(vms)
            
            /// Update delegate insertion
            let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: 0, vms)
            viewModel?.scrollVM.disableExcessiveLoading()
            
            /// Insert and scroll to the last thread message.
            let uniqueId = sections.last?.vms.last?.message.uniqueId
            if let uniqueId = uniqueId, let indexPath = sections.indexPathBy(messageUniqueId: uniqueId) {
                delegate?.inserted(tuple.sections, tuple.rows, indexPath, .bottom)
            }
            
            showCenterLoading(false)
            /// Prevent fetch bottom loading
            /// becuase we get messages with offset so there is not message at bottom.
            setHasMoreBottom(false)
            
            /// Fetch reactions
            fetchReactions(messages: vms.flatMap({$0.message as? Message}))
            
            await prepareAvatars(vms)
            
            showCenterLoading(false)
        } catch {
            showCenterLoading(false)
        }
    }
    
    // MARK: Scenario 8
    /// When a new thread has been built and me is added by another person and this is our first time to visit the thread.
    private func tryEightScenario() {
        if let tuple = newThreadLastMessageTimeId() {
            Task {
                await moveToTime(tuple.time, tuple.lastMSGId, highlight: false)
            }
        }
    }

    // MARK: Scenario 9
    /// When a new thread has been built and there is no message inside the thread yet.
    private func tryNinthScenario() {
        if hasThreadNeverOpened() && thread.lastMessageVO == nil {
            showCenterLoading(false)
            showEmptyThread(show: true)
        }
    }

    // MARK: Scenario 10
    private func moveToMessageTimeOnOpenConversation() {
        let model = AppState.shared.appStateNavigationModel
        if let id = model.moveToMessageId, let time = model.moveToMessageTime {
            Task {
                await moveToTime(time, id, highlight: true)
            }
            AppState.shared.appStateNavigationModel = .init()
        }
    }

    // MARK: Scenario 11
    public func moveToTimeByDate(time: UInt) {
        if time > thread.lastMessageVO?.time ?? 0 { return }
        Task {
            await moveToTime(time, 0)
        }
    }
    
    // MARK: Scenario 12
    /// Move to a time if save scroll position was on.
    private func tryScrollPositionScenario(_ model: SaveScrollPositionModel) async throws {
        if let time = model.message.time, let messageId = model.message.id {
            viewModel?.scrollVM.isAtBottomOfTheList = false
            
            /// Show center loading
            showCenterLoading(true)
            
            /// Preserve state before join or append
            let beforeSectionCount = sections.count
            
            /// Appned to the list
            let vms = try await onTopWithFromTime(fromTime: time, prepend: keys.SAVE_SCROOL_POSITION_KEY)
            appendSort(vms)
            
            /// Disable excessive loading
            viewModel?.scrollVM.disableExcessiveLoading()
            
            /// Scroll to the saved offset
            let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: beforeSectionCount, vms)
            delegate?.inserted(tuple.sections, tuple.rows, IndexPath(row: 0, section: 0), .top)

            /// Hide center loading
            showCenterLoading(false)
            
            setHasMoreTop(true)
            
            /// Fetch reactions
            fetchReactions(messages: vms.flatMap({$0.message as? Message}))
            
            /// Fetch user avatars
            await prepareAvatars(vms)
        }
    }
    
    // MARK: Scenario 13
    public func handleJumpToButtom() {
        let isLastSeenExist = isLastSeenMessageIsInSections()
        let unreadCount = thread.unreadCount ?? 0
        if isLastSeenExist || unreadCount == 0 {
            /// Move to last seen message.
            viewModel?.scrollVM.scrollToBottom()
            
            /// Once user hit the jump to bottom Table view delegates like didEndDecelerating for scroll view won't be called
            /// So we have to make sure we are in a right state in the app and isAtBottomOfList is set to true.
            viewModel?.scrollVM.isAtBottomOfTheList = true
            viewModel?.delegate?.lastMessageAppeared(true)
        } else if unreadCount > 0, let time = thread.lastSeenMessageTime, let id = thread.lastSeenMessageId {
            /// Move to last seen message
            hasNextBottom = true
            removeAllSections()
            tryFirstScenario()
        }
    }

    private func moreTop(prepend: String, _ toTime: UInt) async {
        showTopLoading(true)
        log("SendMoreTopRequest")
        do {
            let vms = try await onMoreTopWithToTime(toTime: toTime, prepend: prepend)
            await onMoreTop(vms)
        } catch {
            showTopLoading(false)
        }
    }

    private func onMoreTop(_ viewModels: [MessageRowViewModel], isMiddleFetcher: Bool = false, moveToLastMessage: Bool = false) async {
        let selectedMessages = await viewModel?.selectedMessagesViewModel.getSelectedMessages() ?? []
        viewModels.forEach { vm in
            if selectedMessages.contains(where: {$0.message.id == vm.message.id}) {
                vm.calMessage.state.isSelected = true
            }
        }
        
        await waitingToFinishDecelerating()
        
        var viewModels = removeDuplicateMessagesBeforeAppend(viewModels)
        
        /// We have to store section count and last top message before appending them to the threads array
        let wasEmpty = sections.isEmpty
        let topVMBeforeJoin = sections.first?.vms.first
        let lastTopMessageVM = sections.first?.vms.first
        let beforeSectionCount = sections.count
        let shouldUpdateOldTopSection = StitchAvatarCalculator.forTop(sections, viewModels)
        
        appendSort(viewModels)
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        setHasMoreTop(viewModels.count >= count)
        let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: beforeSectionCount, viewModels)
        let closeToTop = viewModel?.scrollVM.lastContentOffsetY ?? 0 < 24
        var indexPathToScroll: IndexPath?
        if closeToTop, let lastTopMessageVM = lastTopMessageVM {
            indexPathToScroll = sections.indexPath(for: lastTopMessageVM)
        } else if moveToLastMessage, let vm = sections.last?.vms.last {
            indexPathToScroll = sections.indexPath(for: vm)
        }
        delegate?.inserted(tuple.sections, tuple.rows, .top, indexPathToScroll)
        
        if let row = shouldUpdateOldTopSection, let indexPath = sections.indexPath(for: row) {
            delegate?.reloadData(at: indexPath)
        }
                
        /// We should not detect last message deleted if we are going to fetch with middleFetcher
        /// because the list is empty before we move to time, so it will calculate it wrongly.
        /// And if we moveToTime, and start scrolling to top the list is not empty anymore,
        /// so the wasEmpty is false.
        if !isMiddleFetcher, wasEmpty {
            detectLastMessageDeleted(sortedMessages: viewModels.compactMap { $0.message })
        }
   
        topLoading = false

        viewModel?.delegate?.startTopAnimation(false)
        viewModel?.delegate?.startCenterAnimation(false)
        if !isMiddleFetcher {
            fetchReactions(messages: viewModels.compactMap({$0.message}))
        }
        
        await prepareAvatars(viewModels)
    }
    
    private func moreBottom(prepend: String, _ fromTime: UInt) async {
        if !canLoadMoreBottom() { return }
        showBottomLoading(true)
        log("SendMoreBottomRequest")
        do {
            let vms = try await onMoreBottomWithFromTime(fromTime: fromTime, prepend: prepend)
            await onMoreBottom(vms)
        } catch {
            showBottomLoading(false)
        }
    }

    private func onMoreBottom(_ viewModels: [MessageRowViewModel], isMiddleFetcher: Bool = false) async {
        let selectedMessages = await viewModel?.selectedMessagesViewModel.getSelectedMessages() ?? []
        viewModels.forEach { vm in
            if selectedMessages.contains(where: {$0.message.id == vm.message.id}) {
                vm.calMessage.state.isSelected = true
            }
        }

        await waitingToFinishDecelerating()
        var viewModels = removeDuplicateMessagesBeforeAppend(viewModels)
        
        /// We have to store section count  before appending them to the threads array
        let beforeSectionCount = sections.count
        let shouldUpdateOldBottomSection = StitchAvatarCalculator.forBottom(sections, viewModels)
        
        appendSort(viewModels)

        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        setHasMoreBottom(viewModels.count >= count)
        let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, viewModels)
        delegate?.inserted(tuple.sections, tuple.rows, .left, nil)

        if let row = shouldUpdateOldBottomSection, let indexPath = sections.indexPath(for: row) {
            delegate?.reloadData(at: indexPath)
        }

        isFetchedServerFirstResponse = true
        showBottomLoading(false)

        if !isMiddleFetcher {
            fetchReactions(messages: viewModels.compactMap({$0.message}))
        }
        await prepareAvatars(viewModels)
    }

    public func loadMoreTop(message: HistoryMessageType) {
        if let time = message.time, canLoadMoreTop() {
            Task {
                await moreTop(prepend: keys.MORE_TOP_KEY, time)
            }
        }
    }

    public func loadMoreBottom(message: HistoryMessageType) {
        if let time = message.time, canLoadMoreBottom() {
            // We add 1 milliseceond to prevent duplication and fetch the message itself.
            Task {
                await moreBottom(prepend: keys.MORE_BOTTOM_KEY, time.advanced(by: 1))
            }
        }
    }
}

// MARK: Requests
extension ThreadHistoryViewModel {

    private func makeRequest(fromTime: UInt? = nil, toTime: UInt? = nil, offset: Int?) -> GetHistoryRequest {
        GetHistoryRequest(threadId: threadId,
                          count: count,
                          fromTime: fromTime,
                          offset: offset,
                          order: fromTime != nil ? "asc" : "desc",
                          toTime: toTime,
                          readOnly: viewModel?.readOnly == true)
    }
}

// MARK: Event Handlers
extension ThreadHistoryViewModel {
    private func onUploadEvents(_ event: UploadEventTypes) {
        switch event {
        case .canceled(let uniqueId):
            onUploadCanceled(uniqueId)
        default:
            break
        }
    }

    private func onUploadCanceled(_ uniqueId: String?) {
        if let uniqueId = uniqueId {
            removeByUniqueId(uniqueId)
            //            animateObjectWillChange()
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .delivered(let response):
            await onDeliver(response)
        case .seen(let response):
            await onSeen(response)
        case .sent(let response):
            await onSent(response)
        case .deleted(let response):
            await deleteQueue.onDeleteEvent(response)
        case .pin(let response):
            await onPinMessage(response)
        case .unpin(let response):
            await onUNPinMessage(response)
        case .edited(let response):
            await onEdited(response)
        default:
            break
        }
    }

    // It will be only called by ThreadsViewModel
    public func onNewMessage(_ messages: [Message], _ oldConversation: Conversation?, _ updatedConversation: Conversation) async {
        thread = updatedConversation
        guard let viewModel = viewModel else { return }
        let wasAtBottom = isLastMessageInsideTheSections(oldConversation)
        if wasAtBottom {
            for message in messages {
                let bottomVMBeforeJoin = sections.last?.vms.last
                self.viewModel?.thread = updatedConversation
                let currentIndexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "")
                let vm = await insertOrUpdateMessageViewModelOnNewMessage(message, viewModel)
                viewModel.scrollVM.scrollToNewMessageIfIsAtBottomOrMe(message)
                reloadIfStitchChangedOnNewMessage(bottomVMBeforeJoin, message)
            }
        }
        viewModel.updateUnreadCount(updatedConversation.unreadCount)
        if viewModel.scrollVM.isAtBottomOfTheList {
            await setSeenForAllOlderMessages(newMessage: messages.last ?? .init(), myId: appUserId ?? -1)
        }
        showEmptyThread(show: false)
    }
    
    public func onForwardMessageForActiveThread(_ messages: [Message]) async {
        let messages = removeDuplicateForwards(messages)
        guard let viewModel = viewModel else { return }
        
        let bottomVMBeforeJoin = sections.last?.vms.last
        let beforeSectionCount = sections.count
        
        let sortedMessages = messages.sortedByTime()
        var viewModels = await makeCalculateViewModelsFor(sortedMessages)

        /// Remove duplicated messeages if the onForwardMessageForActiveThread called twice, as a result of cuncrrency issue.
        /// PS: It does not matter if we remove duplicate messages by method above,
        /// we have to do this to make sure no duplicate messages insert into append and sort,
        /// if not it will lead to an exception.
        for message in messages {
            if sections.last?.vms.contains(where: {$0.message.id == message.id}) == true {
                viewModels.removeAll(where: {$0.message.id == message.id})
            }
        }
        await appendSort(viewModels)
        
        let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, viewModels)
        delegate?.inserted(tuple.sections, tuple.rows, .left, nil)
        if let lastSortedMessage = sortedMessages.last {
            viewModel.scrollVM.scrollToNewMessageIfIsAtBottomOrMe(lastSortedMessage)
        }
       
        if let firstSortedMessage = sortedMessages.first {
            reloadIfStitchChangedOnNewMessage(bottomVMBeforeJoin, firstSortedMessage)
        }
        showEmptyThread(show: false)
    }

    /*
     Check if we have the last message in our list,
     It'd useful in case of onNewMessage to check if we have move to time or not.
     We also check greater messages in the last section, owing to
     when I send a message it will append to the list immediately, and then it will be updated by the sent/deliver method.
     Therefore, the id is greater than the id of the previous conversation.lastMessageVO.id
     */
    private func isLastMessageInsideTheSections(_ oldConversation: Conversation?) -> Bool {
        let hasAnyUploadMessage = AppState.shared.objectsContainer.uploadsManager.hasAnyUpload(threadId: threadId) ?? false
        let isLastMessageExistInLastSection = sections.last?.vms.last?.message.id ?? 0 >= oldConversation?.lastMessageVO?.id ?? 0
        return isLastMessageExistInLastSection || hasAnyUploadMessage
    }

    private func insertOrUpdateMessageViewModelOnNewMessage(_ message: Message, _ viewModel: ThreadViewModel) async -> MessageRowViewModel {
        let beforeSectionCount = sections.count
        let vm: MessageRowViewModel
        let mainData = getMainData()
        let beforeAppnedLastVM = sections.last?.vms.last
        if let indexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "") {
            // Update a message sent by Me
            vm = sections[indexPath.section].vms[indexPath.row]
            vm.swapUploadMessageWith(message)
            await vm.recalculate(mainData: mainData)
            delegate?.reloadData(at: indexPath) // Do not call reload(at:) the item it will lead to call endDisplay
        } else {
            // A new message comes from server
            vm = MessageRowViewModel(message: message, viewModel: viewModel)
            await vm.recalculate(appendMessages: [message], mainData: mainData)
            appendSort([vm])
            let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, [vm])
            vm.calMessage.isFirstMessageOfTheUser = vm.message.ownerId != beforeAppnedLastVM?.message.ownerId
            vm.calMessage.isLastMessageOfTheUser = true
            delegate?.inserted(tuple.sections, tuple.rows, .left, nil)
        }
        return vm
    }

    private func onEdited(_ response: ChatResponse<Message>) async {
        if let message = response.result, let vm = sections.messageViewModel(for: message.id ?? -1) {
            vm.message.message = message.message
            vm.message.time = message.time
            vm.message.edited = true
            let mainData = getMainData()
            await vm.recalculate(mainData: mainData)
            guard let indexPath = sections.indexPath(for: vm) else { return }
            delegate?.edited(indexPath)
        }
    }

    private func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.messageId, let vm = sections.messageViewModel(for: messageId) {
            vm.pinMessage(time: response.result?.time)
            guard let indexPath = sections.indexPath(for: vm) else { return }
            delegate?.pinChanged(indexPath)
        }
    }

    private func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.messageId, let vm = sections.messageViewModel(for: messageId) {
            vm.unpinMessage()
            guard let indexPath = sections.indexPath(for: vm) else { return }
            delegate?.pinChanged(indexPath)
        }
    }

    private func onDeliver(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        vm.message.delivered = true
        let mainData = getMainData()
        await vm.recalculate(mainData: mainData)
        delegate?.delivered(indexPath)
    }

    private func onSeen(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        vm.message.delivered = true
        vm.message.seen = true
        let mainData = getMainData()
        await vm.recalculate(mainData: mainData)
        delegate?.seen(indexPath)
        if let messageId = response.result?.messageId, let myId = appUserId {
            await setSeenForOlderMessages(messageId: messageId, myId: myId)
        }
    }

    /*
     We have to set id because sent will be called first then onNewMessage will be called,
     and in queries id is essential to update properly the new message
     */
    private func onSent(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        let result = response.result
        vm.message.id = result?.messageId
        vm.message.time = result?.messageTime
        let mainData = getMainData()
        await vm.recalculate(mainData: mainData)
        delegate?.sent(indexPath)
    }
    
    /// Delete a message with an Id is needed, once the message has persisted before.
    internal func onDeleteMessage(_ messages: [Message], conversationId: Int) async {
        guard threadId == conversationId else { return }
        // We have to update the lastMessageVO to keep moveToBottom hide if the lastMessaegId deleted
        thread.lastMessageVO = viewModel?.thread.lastMessageVO
        let indicies = findDeletedIndicies(messages)
        deleteIndices(indicies)
        if sections.isEmpty {
            showEmptyThread(show: true)
        }
        for message in messages {
            await setDeletedIfWasReply(messageId: message.id ?? -1)
        }
    }
    
    private func setDeletedIfWasReply(messageId: Int) async {
        let deletedReplyInfoVMS = sections.compactMap { section in
            section.vms.filter { $0.message.replyInfo?.id == messageId }
        }
        .flatMap{$0}
        if deletedReplyInfoVMS.isEmpty { return }
        
        var indicesToReload: [IndexPath] = []
        for vm in deletedReplyInfoVMS {
            vm.message.replyInfo = .init()
            vm.message.replyInfo?.deleted = true
            await vm.recalculate(mainData: getMainData())
            if let indexPath = sections.findIncicesBy(uniqueId: vm.message.uniqueId, vm.message.id) {
                indicesToReload.append(indexPath)
            }
        }
        for indexPath in indicesToReload {
            delegate?.reloadData(at: indexPath)
        }
    }
}

// MARK: Append/Sort/Delete
extension ThreadHistoryViewModel {

    private func appendSort(_ viewModels: [MessageRowViewModel]) {
        /// If respone is not empty therefore the thread is not empty and we should not show it
        /// if we call setIsEmptyThread, directly without this check it will show empty thread view for a short period of time,
        /// then disappear and it lead to call move to bottom to hide, in cases like click on reply.
        showEmptyThread(show: viewModels.isEmpty == true && sections.isEmpty && isFetchedServerFirstResponse)
        
        log("Start of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        guard viewModels.count > 0 else { return }
        for vm in viewModels {
            insertIntoProperSection(vm)
        }
        sort()
        log("End of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        lastItemIdInSections = sections.last?.vms.last?.id ?? 0
        return
    }

    fileprivate func updateMessage(_ message: HistoryMessageType, _ indexPath: IndexPath?) -> MessageRowViewModel? {
        guard let indexPath = indexPath else { return nil }
        let vm = sections[indexPath.section].vms[indexPath.row]
        let isUploading = vm.message is  UploadProtocol || vm.fileState.isUploading
        if isUploading {
            /// We have to update animateObjectWillChange because after onNewMessage we will not call it, so upload file not work properly.
            vm.swapUploadMessageWith(message)
        } else {
            vm.message.updateMessage(message: message)
        }
        return vm
    }
    
    /// Remove viewModels if the message with uniqueId is already exist in the list
    /// This prevent duplication on sending forwards for example after reconnect.
    private func removeDuplicateMessagesBeforeAppend(_ viewModels: [MessageRowViewModel]) -> [MessageRowViewModel] {
        var viewModels = viewModels
        viewModels.removeAll { item in
            let removed = sections.indicesByMessageUniqueId(item.message.uniqueId ?? "") != nil
            if removed {
                log("Removed duplidate row with uniqueId: \(item.message.uniqueId ?? "")")
            }
            return removed
        }
        return viewModels
    }
    
    /// Forward messages are unpredictable, and there is a change after reconnection
    /// forward messages sent to the server and server
    /// answer with forward messages while we are requesting the bottom part on reconnect.
    /// Therefor, the forward queue still is trying to accumulate messages but the message is already in
    /// the list.
    private func removeDuplicateForwards(_ messages: [Message]) -> [Message] {
        var messages = messages
        messages.removeAll { item in
            let removed = sections.indicesByMessageUniqueId(item.uniqueId ?? "") != nil
            if removed {
                log("Removed duplidate row in forward with uniqueId: \(item.uniqueId ?? "")")
            }
            return removed
        }
        return messages
    }

    public func injectMessagesAndSort(_ requests: [HistoryMessageType]) async {
        var viewModels = await makeCalculateViewModelsFor(requests)
        viewModels = removeDuplicateMessagesBeforeAppend(viewModels)
        appendSort(viewModels)
    }
    
    public func injectUploadsAndSort(_ elements: [UploadManagerElement]) async {
        guard let viewModel = viewModel else { return }
        let mainData = await getMainData()
        var viewModels: [MessageRowViewModel] = []
        for element in elements {
            let viewModel = MessageRowViewModel(message: element.viewModel.message, viewModel: viewModel)
            viewModel.uploadElementUniqueId = element.id
            await viewModel.recalculate(mainData: mainData)
            viewModels.append(viewModel)
        }
        viewModels = removeDuplicateMessagesBeforeAppend(viewModels)
        appendSort(viewModels)
    }

    private func insertIntoProperSection(_ viewModel: MessageRowViewModel) {
        let message = viewModel.message
        if let sectionIndex = sections.sectionIndexByDate(message.time?.date ?? Date()) {
            sections[sectionIndex].vms.append(viewModel)
        } else {
            sections.append(.init(date: message.time?.date ?? Date(), vms: [viewModel]))
        }
    }

    private func sort() {
        log("Start of the Sort function: \(Date().millisecondsSince1970)")
        sections.indices.forEach { sectionIndex in
            sections[sectionIndex].vms.sort { m1, m2 in
                if m1 is UnreadMessageProtocol {
                    return false
                }
                if let t1 = m1.message.time, let t2 = m2.message.time {
                    return t1 < t2
                } else {
                    return false
                }
            }
        }
        sections.sort(by: {$0.date < $1.date})
        log("End of the Sort function: \(Date().millisecondsSince1970)")
    }

    internal func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = sections.indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.section].vms.remove(at: indices.row)
    }
    
    public func deleteMessages(_ messages: [HistoryMessageType], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        let threadId = threadId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        }
        viewModel?.selectedMessagesViewModel.clearSelection()
    }
    
    private func createUnreadBanner(time: UInt, id: Int, viewModel: ThreadViewModel) async -> MessageRowViewModel {
        let unreadMessage = UnreadMessage(
            id: LocalId.unreadMessageBanner.rawValue,
            time: time.advanced(by: 1),
            uniqueId: "\(LocalId.unreadMessageBanner.rawValue)")
        
        let vm = MessageRowViewModel(message: unreadMessage, viewModel: viewModel)
        await vm.recalculate(mainData: getMainData())
        return vm
    }

    private func removeAllSections() {
        sections.removeAll()
        delegate?.reload()
    }
}

// MARK: Appear/Disappear/Display/End Display
extension ThreadHistoryViewModel {
    public func willDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        await visibleTracker.append(message: message)
        log("Message appear id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        await seenVM?.onAppear(message)
    }

    public func didEndDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        log("Message disappeared id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        await visibleTracker.remove(message: message)
    }

    public func didScrollTo(_ contentOffset: CGPoint, _ contentSize: CGSize) {
        if isInProcessingScroll() {
            logScroll("IsProcessingScroll")
            viewModel?.scrollVM.lastContentOffsetY = contentOffset.y
            if contentOffset.y < 0 {
                doScrollAction(contentOffset, contentSize)
            }
            return
        }
        logScroll("NonProcessing")
        doScrollAction(contentOffset, contentSize)
        viewModel?.scrollVM.lastContentOffsetY = contentOffset.y
    }

    private func doScrollAction(_ contentOffset: CGPoint , _ contentSize: CGSize) {
        guard let scrollVM = viewModel?.scrollVM else { return }
        logScroll("ContentOffset: \(contentOffset) lastContentOffsetY: \(scrollVM.lastContentOffsetY)")
        if contentOffset.y > 0, contentOffset.y >= scrollVM.lastContentOffsetY {
            // scroll down
            logScroll("DOWN")
            scrollVM.scrollingUP = false
            if contentOffset.y > contentSize.height - threshold, let message = sections.last?.vms.last?.message {
                logScroll("LoadMoreBottom")
                loadMoreBottom(message: message)
            }
        } else {
            /// There is a chance if we are at the top of a table view and due to we have negative value at top because of contentInset
            /// it will start to fetch the data however, if we are at end of the top list it won't get triggered.
            // scroll up
            logScroll("UP")
            scrollVM.scrollingUP = true
            if contentOffset.y < threshold, let message = sections.first?.vms.first?.message {
                logScroll("LoadMoreTop")
                loadMoreTop(message: message)
            }
        }
    }

    private func isInProcessingScroll() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastScrollTime) < debounceInterval {
            return true
        }
        lastScrollTime = now
        return false
    }
    
    private func isLastSeenMessageIsInSections() -> Bool {
        let lastSeenId = thread.lastSeenMessageId ?? 0
        return sections.isLastSeenMessageExist(thread: thread)
    }
}

// MARK: Observers On MainActor
extension ThreadHistoryViewModel {
    private func setupNotificationObservers() {
        observe(AppState.shared.$connectionStatus) { [weak self] status in
            self?.onConnectionStatusChanged(status)
        }
        
        let messageEvent = NotificationCenter.message.publisher(for: .message).compactMap { $0.object as? MessageEventTypes }
        observe(messageEvent) { [weak self] event in
            await self?.onMessageEvent(event)
        }
        
        observe(NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)) { [weak self] newValue in
            if let key = newValue.object as? String {
                await self?.onCancelTimer(key: key)
            }
        }
        
        observe(NotificationCenter.windowMode.publisher(for: .windowMode)) { [weak self] _ in
            /// Prevent calling calling it by swiping to another app from bottom on iPadOS
            if AppState.shared.lifeCycleState == .active {
                await self?.updateAllRows()
            }
        }
        
        observe(NotificationCenter.upload.publisher(for: .upload)) { [weak self] notification in
            if let event = notification.object as? UploadEventTypes {
                await self?.onUploadEvents(event)
            }
        }
    }
    
    private func observe<P: Publisher>(_ publisher: P, action: @escaping (P.Output) async -> Void) where P.Failure == Never {
        publisher
            .sink { [weak self] value in
                Task {
                    await action(value)
                }
            }
            .store(in: &cancelable)
    }

    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}

// MARK: Logging
extension ThreadHistoryViewModel {
    private func logHistoryRequest(req: GetHistoryRequest) {
        let date = Date().millisecondsSince1970
        Logger.log(title: "ThreadHistoryViewModel", message: " Start of sending history request: \(date) milliseconds")
    }

    private func log(_ string: String) {
        Logger.log(title: "ThreadHistoryViewModel", message: string)
    }
    
    private func logScroll(_ string: String) {
        Logger.log(title: "ThreadHistoryViewModel", message: "SCROLL: \(string)")
    }
}

// MARK: Reactions
extension ThreadHistoryViewModel {
    
    private func fetchReactions(messages: [HistoryMessageType]) {
        if viewModel?.searchedMessagesViewModel.isInSearchMode == false {
            viewModel?.reactionViewModel.fetchReactions(messages: messages.compactMap({$0 as? Message}), withQueue: false)
        }
    }
}

// MARK: Scenarios utilities
extension ThreadHistoryViewModel {
    private func setHasMoreTop(_ response: ChatResponse<[Message]>) {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            showTopLoading(false)
        }
    }
    
    private func setHasMoreTopNonAsync(_ response: ChatResponse<[Message]>) {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
        }
    }
    
    private func setHasMoreTop(_ hasNext: Bool) {
        hasNextTop = hasNext
        isFetchedServerFirstResponse = true
    }

    private func setHasMoreBottom(_ hasNext: Bool) {
        hasNextBottom = hasNext
        isFetchedServerFirstResponse = true
        showBottomLoading(false)
    }
    
    private func setHasMoreBottom(_ response: ChatResponse<[Message]>) {
        if !response.cache {
            hasNextBottom = response.hasNext
            isFetchedServerFirstResponse = true
            showBottomLoading(false)
        }
    }

    private func removeOldBanner() {
        if let indices = sections.indicesByMessageUniqueId("\(LocalId.unreadMessageBanner.rawValue)") {
            deleteIndices([IndexPath(row: indices.row, section: indices.section)])
        }
    }

    private func canLoadMoreTop() -> Bool {
        let isProgramaticallyScroll = viewModel?.scrollVM.getIsProgramaticallyScrolling() == true
        return hasNextTop && !topLoading && !isProgramaticallyScroll && !bottomLoading
    }

    private func canLoadMoreBottom() -> Bool {
        let isProgramaticallyScroll = viewModel?.scrollVM.getIsProgramaticallyScrolling() == true
        return hasNextBottom && !bottomLoading && !isProgramaticallyScroll && !topLoading
    }

    public func showEmptyThread(show: Bool) {
        delegate?.emptyStateChanged(isEmpty: show)
        if show {
            showCenterLoading(false)
        }
    }
    
    public func setThreashold(_ threshold: CGFloat) {
        self.threshold = threshold
    }
    
    private func canGetNewMessagesAfterConnectionEstablished(_ status: ConnectionStatus) -> Bool {
        /// Prevent updating bottom if we have moved to a specific date
        if sections.last?.vms.last?.message.id != thread.lastMessageVO?.id { return false }
        let isActiveThread = viewModel?.isActiveThread == true
        return !isSimulated() && status == .connected && isFetchedServerFirstResponse == true && isActiveThread
    }
    
    private func detectLastMessageDeleted(sortedMessages: [HistoryMessageType]) {
        if isLastMessageEqualToLastSeen(), !isLastMessageExistInSortedMessages(sortedMessages) {
            let lastSortedMessage = sortedMessages.last
            viewModel?.thread.lastMessageVO = (lastSortedMessage as? Message)?.toLastMessageVO
            highlightVM.showHighlighted(lastSortedMessage?.uniqueId ?? "",
                                                lastSortedMessage?.id ?? -1,
                                                highlight: false)
        }
    }
    
    private func reloadIfStitchChangedOnNewMessage(_ bottomVMBeforeJoin: MessageRowViewModel?, _ newMessage: Message) {
        guard let indexPath = StitchAvatarCalculator.forNew(sections, newMessage, bottomVMBeforeJoin) else { return }
        bottomVMBeforeJoin?.calMessage.isLastMessageOfTheUser = false
        delegate?.reloadData(at: indexPath)
    }
}

// MARK: Senario Request maker methods
extension ThreadHistoryViewModel {
    private func onReconnectViewModels() async throws -> [MessageRowViewModel] {
        guard let lastMessageInListTime = sections.last?.vms.last?.message.time else { return [] }
        let requester = GetHistoryReuqester(key: keys.MORE_BOTTOM_FIFTH_SCENARIO_KEY)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        let req = makeRequest(fromTime: lastMessageInListTime.advanced(by: 1), offset: nil)
        return try await requester.get(req, queueable: true) ?? []
    }
    
    private func onMoreTopWithOffset() async throws -> [MessageRowViewModel] {
        let req = makeRequest(offset: 0)
        let requester = GetHistoryReuqester(key: keys.MORE_TOP_SECOND_SCENARIO_KEY)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        return try await requester.get(req)
    }
    
    private func onTopToTime(toTime: UInt) async throws -> [MessageRowViewModel] {
        let req = makeRequest(toTime: toTime, offset: nil)
        let requester = GetHistoryReuqester(key: keys.TOP_FIRST_SCENARIO_KEY)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        return try await requester.get(req)
    }

    private func onBottomFromTime(fromTime: UInt) async throws -> [MessageRowViewModel] {
        let req = makeRequest(fromTime: fromTime, offset: nil)
        let requester = GetHistoryReuqester(key: keys.BOTTOM_FIRST_SCENARIO_KEY)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        return try await requester.get(req)
    }
    
    private func onMoreTopWithToTime(toTime: UInt, prepend: String) async throws -> [MessageRowViewModel] {
        let req = makeRequest(toTime: toTime, offset: nil)
        log("SendMoreTopRequest")
        let requester = GetHistoryReuqester(key: prepend)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        return try await requester.get(req)
    }
    
    private func onMoreBottomWithFromTime(fromTime: UInt, prepend: String) async throws -> [MessageRowViewModel] {
        let req = makeRequest(fromTime: fromTime, offset: nil)
        log("SendMoreBottomRequest")
        let requester = GetHistoryReuqester(key: prepend)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        return try await requester.get(req)
    }
    
    private func onFetchByOffset() async throws -> [MessageRowViewModel] {
        let req = makeRequest(toTime: thread.lastMessageVO?.time?.advanced(by: 1), offset: nil)
        log("Get bottom part by last message deleted detection")
        let requester = GetHistoryReuqester(key: keys.FETCH_BY_OFFSET_KEY)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        return try await requester.get(req)
    }
    
    private func onTopWithFromTime(fromTime: UInt, prepend: String) async throws -> [MessageRowViewModel] {
        let req = makeRequest(fromTime: fromTime, offset: nil)
        log("SendTopWithFromTimeRequest")
        let requester = GetHistoryReuqester(key: prepend)
        let data = getMainData()
        requester.setup(data: data, viewModel: viewModel)
        return try await requester.get(req)
    }
}

// MARK: Seen messages
extension ThreadHistoryViewModel {
    /// When you have sent messages for example 5 messages and your partner didn't read messages and send a message directly it will send you only one seen.
    /// So you have to set seen to true for older unread messages you have sent, because the partner has read all messages and after you back to the list of thread the server will respond with seen == true for those messages.
    
    private func unseenMessages(myId: Int) -> [MessageRowViewModel] {
        let unseenMessages = sections.last?.vms.filter({($0.message.seen == false || $0.message.seen == nil) && $0.message.isMe(currentUserId: myId)})
        return unseenMessages ?? []
    }
    
    private func setSeenForAllOlderMessages(newMessage: HistoryMessageType, myId: Int) async {
        let unseenMessages = unseenMessages(myId: myId)
        let isNotMe = !newMessage.isMe(currentUserId: myId)
        let isGroup = thread.group == true
        if !isGroup, isNotMe, unseenMessages.count > 0 {
            for vm in unseenMessages {
                await setSeen(vm: vm)
            }
        }
    }
    
    private func setSeen(vm: MessageRowViewModel) async {
        if let indexPath = sections.indexPath(for: vm) {
            vm.message.delivered = true
            vm.message.seen = true
            let mainData = getMainData()
            await vm.recalculate(mainData: mainData)
            delegate?.seen(indexPath)
        }
    }
    
    private func setSeenForOlderMessages(messageId: Int, myId: Int) async {
        let vms = sections.flatMap { $0.vms }.filter { canSetSeen(for: $0.message, newMessageId: messageId, isMeId: myId) }
        for vm in vms {
            await setSeen(vm: vm)
        }
    }
}

// MARK: On Notifications actions
extension ThreadHistoryViewModel {
    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if canGetNewMessagesAfterConnectionEstablished(status) {
            // After connecting again get latest messages.
            Task {
                await tryFifthScenario(status: status)
            }
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if !isSimulated(), status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            startFetchingHistory()
        }
    }

    private func updateAllRows() async {
        let mainData = getMainData()
        for section in sections {
            for vm in section.vms {
                await vm.recalculateWithAnimation(mainData: mainData)
            }
        }
    }
}

// MARK: Avatars
extension ThreadHistoryViewModel {
    func prepareAvatars(_ viewModels: [MessageRowViewModel]) async {
        // A delay to scroll to position and layout all rows properply
        let filtered = viewModels.filter({$0.calMessage.isLastMessageOfTheUser})
        for vm in filtered {
            await viewModel?.avatarManager.addToQueue(vm)
        }
    }
}

// MARK: Cleanup
extension ThreadHistoryViewModel {
    private func onCancelTimer(key: String) {
        if topLoading || bottomLoading {
            topLoading = false
            bottomLoading = false
            showTopLoading(false)
            showBottomLoading(false)
        }
    }
}

public extension ThreadHistoryViewModel {
    
    func getSections() -> ContiguousArray<MessageSection> {
        return sections
    }
    
    func getMainData() -> MainRequirements {
        return MainRequirements(appUserId: AppState.shared.user?.id,
                                thread: viewModel?.thread,
                                participantsColorVM: viewModel?.participantsColorVM,
                                isInSelectMode: viewModel?.selectedMessagesViewModel.isInSelectMode ?? false,
                                joinLink: AppState.shared.spec.paths.talk.join)
    }
}

extension ThreadHistoryViewModel {

    @DeceleratingActor
    func waitingToFinishDecelerating() async {
        var isEnded = false
        while(!isEnded) {
            if await viewModel?.scrollVM.isEndedDecelerating == true {
                isEnded = true
#if DEBUG
                print("Deceleration has been completed.")
#endif
            } else if await viewModel == nil {
                isEnded = true
#if DEBUG
                print("ViewModel has been deallocated, thus, the deceleration will end.")
#endif
            } else {
#if DEBUG
                print("Waiting for the deceleration to be completed.")
#endif
                try? await Task.sleep(for: .nanoseconds(500000))
            }
        }
    }
}

extension ThreadHistoryViewModel {
    private func showTopLoading(_ show: Bool) {
        topLoading = show
        viewModel?.delegate?.startTopAnimation(show)
    }

    private func showCenterLoading(_ show: Bool) {
        centerLoading = show
        viewModel?.delegate?.startCenterAnimation(show)
    }

    private func showBottomLoading(_ show: Bool) {
        bottomLoading = show
        viewModel?.delegate?.startBottomAnimation(show)
    }
}

// MARK: Conditions and common functions
extension ThreadHistoryViewModel {
    private func isLastMessageEqualToLastSeen() -> Bool {
        let thread = viewModel?.thread
        return thread?.lastMessageVO?.id ?? 0 == thread?.lastSeenMessageId ?? 0
    }
    
    private func isLastMessageExistInSortedMessages(_ sortedMessages: [HistoryMessageType]) -> Bool {
        let lastMessageId = viewModel?.thread.lastMessageVO?.id
        return sortedMessages.contains(where: {$0.id == lastMessageId})
    }

    private func hasUnreadMessage() -> Bool {
        thread.lastMessageVO?.id ?? 0 > thread.lastSeenMessageId ?? 0
    }

    private func canMoveToMessageLocally(_ messageId: Int) -> String? {
        return sections.message(for: messageId)?.message.uniqueId
    }

    private func hasThreadNeverOpened() -> Bool {
        (thread.lastSeenMessageId ?? 0 == 0) && thread.lastSeenMessageTime == nil
    }

    private func newThreadLastMessageTimeId() -> (time: UInt, lastMSGId: Int)? {
        guard
            hasThreadNeverOpened(),
            let lastMSGId = thread.lastMessageVO?.id,
            let time = thread.lastMessageVO?.time
        else { return nil }
        return (time, lastMSGId)
    }
    
    public func isSimulated() -> Bool {
        let createThread = AppState.shared.appStateNavigationModel.userToCreateThread != nil
        return createThread && thread.id == LocalId.emptyThread.rawValue
    }
    
    private var appUserId: Int? {
        return AppState.shared.user?.id
    }
    
    private var isConnected: Bool {
        AppState.shared.connectionStatus == .connected
    }
    
    private func findDeletedIndicies(_ messages: [Message]) -> [IndexPath] {
        var indicies: [IndexPath] = []
        for message in messages {
            if let indexPath = sections.viewModelAndIndexPath(for: message.id ?? -1)?.indexPath {
                indicies.append(indexPath)
            }
        }
        return indicies
    }
    
    private func makeCalculateViewModelsFor(_ messages: [HistoryMessageType]) async -> [MessageRowViewModel] {
        let mainData = getMainData()
        return await MessageRowCalculators.batchCalulate(messages, mainData: mainData, viewModel: viewModel)
    }
    
    private var lastMessageIndexPath: IndexPath? {
        sections.viewModelAndIndexPath(for: viewModel?.thread.lastMessageVO?.id ?? -1)?.indexPath
    }
}

/// SectionHolder
extension ThreadHistoryViewModel {
    public func deleteIndices(_ indices: [IndexPath]) {
        log("deleteIndicies: \(indices)")
        var sectionsToDelete: [Int] = []
        var rowsToDelete: [IndexPath] = indices
        Dictionary(grouping: indices, by: {$0.section}).forEach { section, indexPaths in
            for indexPath in indexPaths.sorted(by: {$0.row > $1.row}) {
                guard isSectionAndRowExist(indexPath) else {
                    /// We couldn't find the indexPath as a result of a bug that we should investigate.
                    /// To prevent the crash we will remove it from pending delete rows
                    rowsToDelete.removeAll(where: { $0.section == indexPath.section && $0.row == indexPath.row})
                    continue
                }
                sections[indexPath.section].vms.remove(at: indexPath.row)
                if sections[indexPath.section].vms.isEmpty {
                    sections.remove(at: indexPath.section)
                    sectionsToDelete.append(indexPath.section)
                }
            }
        }
        
        /// Remove all deleted sections from rowsToDelete to just delete rows in a section.
        rowsToDelete.removeAll(where: { sectionsToDelete.contains($0.section) })
        
        let sectionsSet = sectionsToDelete.sorted().map{ IndexSet($0..<$0+1) }
        delegate?.delete(sections: sectionsSet, rows: rowsToDelete)
    }
    
    public func reload(at: IndexPath, vm: MessageRowViewModel) {
        log("reload")
        sections[at.section].vms[at.row] = vm
        delegate?.reloadData(at: at)
    }

    private func isSectionAndRowExist(_ indexPath: IndexPath) -> Bool {
        guard sections.indices.contains(where: {$0 == indexPath.section}) else { return false }
        return sections[indexPath.section].vms.indices.contains(where: {$0 == indexPath.row})
    }
}

extension ThreadHistoryViewModel {
    public func reattachUploads() {
        if isReattachedUploads == true { return }
        isReattachedUploads = true
        Task {
            let elements = AppState.shared.objectsContainer.uploadsManager.elements.filter { $0.threadId  == threadId }
            if elements.isEmpty { return }
            await AppState.shared.objectsContainer.uploadsManager.stateMediator.append(elements: elements)
        }
    }
}
