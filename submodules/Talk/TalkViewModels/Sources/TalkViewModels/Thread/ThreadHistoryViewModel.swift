//
//  ThreadHistoryViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Foundation
import Chat
import OSLog
import TalkModels
import Combine
import UIKit
import CoreGraphics

@HistoryActor
public final class ThreadHistoryViewModel {
    // MARK: Stored Properties
    @MainActor internal weak var viewModel: ThreadViewModel?
    @MainActor public weak var delegate: HistoryScrollDelegate?
    private var sections: ContiguousArray<MessageSection> = .init()
    @MainActor public var mSections: ContiguousArray<MessageSection> = .init()
    @MainActor
    private var deleteQueue = DeleteMessagesQueue()

    private var threshold: CGFloat = 800
    private var topLoading = false
    private var centerLoading = false
    private var bottomLoading = false
    private var hasNextTop = true
    private var hasNextBottom = true
    private let count: Int = 25
    private var isFetchedServerFirstResponse: Bool = false
    @MainActor
    private var cancelable: Set<AnyCancellable> = []
    private var hasSentHistoryRequest = false
    @MainActor internal var seenVM: HistorySeenViewModel? { viewModel?.seenVM }
    private var tasks: [Task<Void, Error>] = []
    @VisibleActor
    private var visibleTracker = VisibleMessagesTracker()
    @MainActor private var highlightVM = ThreadHighlightViewModel()
    private var isEmptyThread = false
    private var lastItemIdInSections = 0
    private let keys = RequestKeys()
    private var middleFetcher: MiddleHistoryFetcherViewModel?
    private var firstMessageOfTheDayVM: FirstMessageOfTheDayViewModel?

    @MainActor
    public var isUpdating = false
    private var lastScrollTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.5 // 500 milliseconds

    // MARK: Computed Properties
    private var thread: Conversation = Conversation()
    private var threadId: Int = -1
    
    private var start: DispatchTime = .now()

    // MARK: Initializer
    nonisolated public init() {}
}


extension ThreadHistoryViewModel: StabledVisibleMessageDelegate {
    func onStableVisibleMessages(_ messages: [HistoryMessageType]) async {
        let invalidVisibleMessages = await getInvalidVisibleMessages().compactMap({$0 as? Message})
        if invalidVisibleMessages.count > 0 {
            await viewModel?.reactionViewModel.fetchReactions(messages: invalidVisibleMessages, withQueue: false)
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
    public func setup(thread: Conversation, readOnly: Bool) async {
        self.thread = thread
        threadId = thread.id ?? -1
        middleFetcher = MiddleHistoryFetcherViewModel(threadId: threadId, readOnly: readOnly)
        await setupVisible()
        await setupMain()
        await MainActor.run {
            deleteQueue.viewModel = self
        }
    }
    
    @VisibleActor
    private func setupVisible() {
        visibleTracker.delegate = self
    }
    
    @MainActor
    private func setupMain() {
        highlightVM.setup(self)
        setupNotificationObservers()
    }
    
    // MARK: Scenarios Common Functions
    public func start() async {
        /// After deleting a thread it will again tries to call histroy,
        /// we should prevent it from calling it to not get any error.
        if isFetchedServerFirstResponse == false {
            await startFetchingHistory()
            await viewModel?.threadsViewModel?.clearAvatarsOnSelectAnotherThread()
        } else if isFetchedServerFirstResponse == true {
            /// try to open reply privately if user has tried to click on  reply privately and back button multiple times
            /// iOS has a bug where it tries to keep the object in the memory, so multiple back and forward doesn't lead to destroy the object.
            await moveToMessageTimeOnOpenConversation()
        }
    }

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    private func startFetchingHistory() async {
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let isSimulatedThread = await viewModel?.isSimulatedThared == true
        let hasAnythingToLoadOnOpen = await AppState.shared.appStateNavigationModel.moveToMessageId != nil
        await moveToMessageTimeOnOpenConversation()
        await setIsEmptyThread()
        if sections.count > 0 || hasAnythingToLoadOnOpen || isSimulatedThread { return }
        Task.detached {
            /// We won't set this variable to prevent duplicate call on connection status for the first time.
            /// If we don't sleep we will get a crash.
            try? await Task.sleep(for: .microseconds(500))
            Task { @HistoryActor in
                self.hasSentHistoryRequest = true
            }
        }
        tryFirstScenario()
        await trySecondScenario()
        await trySeventhScenario()
        await tryEightScenario()
        await tryNinthScenario()
    }
}

// MARK: Scenarios
extension ThreadHistoryViewModel {

    // MARK: Scenario 1
    private func tryFirstScenario() {
        /// 1- Get the top part to time messages
        if hasUnreadMessage(), let toTime = thread.lastSeenMessageTime {
            Task {
                await moreTop(prepend: keys.MORE_TOP_FIRST_SCENARIO_KEY, toTime.advanced(by: 1))
                await showTopLoading(false) // We do not need to show two loadings at the same time.
            }
        }
    }

    private func onMoreTopFirstScenario(_ response: HistoryResponse) async {
        await onMoreTop(response)
        let show = await showJumpToButtom()
        await delegate?.showMoveToButtom(show: show)
        /*
         It'd be better to go to the last message in the sections, instead of finding the item.
         If the last message has been deleted, we can not find the message.
         Consequently, the scroll to the last message won't work.
        */
        let uniqueId = sections.last?.vms.last?.message.uniqueId
        await delegate?.scrollTo(uniqueId: uniqueId ?? "", position: .bottom, animate: false)

        /// 4- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
        if let fromTime = thread.lastSeenMessageTime {
            await viewModel?.scrollVM.setIsProgramaticallyScrolling(false)
            await appenedUnreadMessagesBannerIfNeeed()
            await moreBottom(prepend: keys.MORE_BOTTOM_FIRST_SCENARIO_KEY, fromTime.advanced(by: 1))
        }
        await showCenterLoading(false)
    }

    private func onMoreBottomFirstScenario(_ response: HistoryResponse) async {
        await onMoreBottom(response)
    }

    // MARK: Scenario 2
    /// We have to fetch with offset not time, because we want to store them inside the cahce.
    /// The cache system will only work if and only if it can store the first request last message.
    /// With middle fetcher we can not store the last message with top request even we fetch it with
    /// by advance 1, in retriving it next time, the checking system will examaine it with exact time not advance time!
    /// Therefore the cache will always the request from the server.
    private func trySecondScenario() async {
        if await isLastMessageEqualToLastSeen() {
            hasNextBottom = false
            let req = await makeRequest(offset: 0)
            log("trySecondScenario")
            doRequest(req, keys.MORE_TOP_SECOND_SCENARIO_KEY)
        }
    }

    private func onMoreTopSecondScenario(_ response: HistoryResponse) async {
        await onMoreTop(response)
        await showCenterLoading(false)
        if let uniqueId = thread.lastMessageVO?.uniqueId, let messageId = thread.lastMessageVO?.id {
            /// Inside onMoreTop we disable excessive loading so we have to wait to move to the right place,
            /// however we scroll there first and then wait to finish scrolling programatically,
            /// then scroll again to the bottom of the list, it will always scroll to perfect position
            /// even after reactions has been set. So it looks perfect on openning a thread,
            /// where all the messages has been seen.
            await highlightVM.showHighlighted(uniqueId, messageId, highlight: false)
            while await viewModel?.scrollVM.getIsProgramaticallyScrolling() == true {}
            await highlightVM.showHighlighted(uniqueId, messageId, highlight: false)
        }
    }

    // MARK: Scenario 3 or 4 more top/bottom.

    // MARK: Scenario 5
    private func tryFifthScenario(status: ConnectionStatus) async {
        /// 1- Get the bottom part of the list of what is inside the memory.
        if await canGetNewMessagesAfterConnectionEstablished(status), let lastMessageInListTime = sections.last?.vms.last?.message.time {
            await showBottomLoading(true)
            let req = await makeRequest(fromTime: lastMessageInListTime.advanced(by: 1), offset: nil)
            await doRequestQueue(req, keys.MORE_BOTTOM_FIFTH_SCENARIO_KEY)
        }
    }

    private func canGetNewMessagesAfterConnectionEstablished(_ status: ConnectionStatus) async -> Bool {
        let isActiveThread = await viewModel?.isActiveThread == true
        return await !isSimulated() && status == .connected && isFetchedServerFirstResponse == true && isActiveThread
    }

    private func onMoreBottomFifthScenario(_ response: HistoryResponse) async {
        let messages = response.result ?? []
        if messages.count > 0 {
            await removeOldBanner()
            await appenedUnreadMessagesBannerIfNeeed()
            await viewModel?.scrollVM.setIsProgramaticallyScrolling(false)
        }
        await onMoreBottom(response)
    }

    // MARK: Scenario 6
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true, moveToBottom: Bool = false) async {
        /// 1- Move to a message locally if it exists.
        if moveToBottom, !sections.isLastSeenMessageExist(thread: thread) {
            await removeAllSections()
        } else if let uniqueId = canMoveToMessageLocally(messageId) {
            await showCenterLoading(false) // To hide center loading if the uer click on reply privately header to jump back to the thread.
            await moveToMessageLocally(uniqueId, messageId, highlight, true)
            return
        } else {
            log("The message id to move to is not exist in the list")
        }

        centerLoading = true
        topLoading = false
        sections.removeAll()
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            await MainActor.run {
                viewModel?.delegate?.startCenterAnimation(true)
                viewModel?.delegate?.startTopAnimation(false)
                mSections.removeAll()
                delegate?.reload()
            }
        }
        middleFetcher?.completion = { [weak self] response in
            Task { [weak self] in
                await self?.onMoveToTime(response, messageId: messageId, highlight: highlight)
            }
        }
        middleFetcher?.start(time: time, messageId: messageId, highlight: highlight)
    }

    private func onMoveToTime(_ response: HistoryResponse, messageId: Int, highlight: Bool) async {
        let messages = response.result ?? []
        await onMoreTop(response, isMiddleFetcher: true)
        // If messageId is equal to thread.lastMessageVO?.id it means we are going to open up the thread at the bottom of it so there is
        if messageId == thread.lastMessageVO?.id {
            hasNextBottom = false
        } else {
            await setHasMoreBottom(response) // We have to set bootom too for when user start scrolling bottom.
        }
        centerLoading = false
        let lastMessageVOId = thread.lastMessageVO?.id
        await MainActor.run {
            // Update the UI and fetch reactions the rows at top part.
            delegate?.emptyStateChanged(isEmpty: response.result?.count == 0)
            if messageId == lastMessageVOId {
                setIsAtBottom(newValue: true)
            } else {
                viewModel?.delegate?.showMoveToButtom(show: true)
            }
            let uniqueId = messages.first(where: {$0.id == messageId})?.uniqueId ?? ""
            highlightVM.showHighlighted(uniqueId, messageId, highlight: highlight, position: .middle)
            viewModel?.delegate?.startCenterAnimation(false)
            fetchReactions(messages: messages)
        }
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    private func moveToMessageLocally(_ uniqueId: String, _ messageId: Int, _ highlight: Bool, _ animate: Bool = false) async {
        await highlightVM.showHighlighted(uniqueId, messageId, highlight: highlight, position: .top, animate: animate)
    }

    // MARK: Scenario 7
    /// When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug or when the conversation is empty.
    private func trySeventhScenario() async {
        if thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 {
            await requestBottomPartByCountAndOffset()
        }
    }

    private func requestBottomPartByCountAndOffset() async {
        let req = await makeRequest(toTime: thread.lastMessageVO?.time?.advanced(by: 1), offset: nil)
        log("Get bottom part by last message deleted detection")
        doRequest(req, keys.FETCH_BY_OFFSET_KEY)
    }

    private func onFetchByOffset(_ response: HistoryResponse) async {
        await onMoreTop(response)
        await delegate?.showMoveToButtom(show: false)
        await showCenterLoading(false)
        await delegate?.scrollTo(uniqueId: response.result?.first?.uniqueId ?? "", position: .bottom, animate: true)
    }

    // MARK: Scenario 8
    /// When a new thread has been built and me is added by another person and this is our first time to visit the thread.
    private func tryEightScenario() async {
        if let tuple = newThreadLastMessageTimeId() {
            await moveToTime(tuple.time, tuple.lastMSGId, highlight: false)
        }
    }

    // MARK: Scenario 9
    /// When a new thread has been built and there is no message inside the thread yet.
    private func tryNinthScenario() async {
        if hasThreadNeverOpened() && thread.lastMessageVO == nil {
            await showCenterLoading(false)
            isEmptyThread = true
            await delegate?.emptyStateChanged(isEmpty: isEmptyThread)
        }
    }

    // MARK: Scenario 10
    private func moveToMessageTimeOnOpenConversation() async {
        let model = await AppState.shared.appStateNavigationModel
        if let id = model.moveToMessageId, let time = model.moveToMessageTime {
            await moveToTime(time, id, highlight: true)
            await MainActor.run {
                AppState.shared.appStateNavigationModel = .init()
            }
        }
    }

    // MARK: Scenario 11
    public func moveToTimeByDate(time: UInt) {
        firstMessageOfTheDayVM = FirstMessageOfTheDayViewModel(threadId: threadId, readOnly: false)
        firstMessageOfTheDayVM?.completion = { [weak self] message in
            guard let message = message else { return }
            Task { [weak self] in
                await self?.moveToTime(message.time ?? 0, message.id ?? -1)
            }
        }
        firstMessageOfTheDayVM?.startOfDate(time: time, highlight: true)
    }

    // MARK: On Cache History Response
    private func onHistoryCacheRsponse(_ response: HistoryResponse) async {
        await onMoreTop(response)
    }

    private func moreTop(prepend: String, _ toTime: UInt?) async {
        if await !canLoadMoreTop() { return }
        await showTopLoading(true)
        let req = await makeRequest(toTime: toTime, offset: nil)
        log("SendMoreTopRequest")
        doRequest(req, prepend)
    }

    private func onMoreTop(_ response: HistoryResponse, isMiddleFetcher: Bool = false) async {
        // If the last message of the thread deleted and we have seen all the messages we move to top of the thread which is wrong
        let wasEmpty = sections.isEmpty
        let topVMBeforeJoin = sections.first?.vms.first
        let messages = response.result ?? []
        let lastTopMessageVM = sections.first?.vms.first
        let beforeSectionCount = sections.count
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)
        let shouldUpdateOldTopSection = stitchAvatarsOnLoadMoreTop(viewModels)

        await waitingToFinishDecelerating()
        await waitingToFinishUpdating()
        await appendSort(viewModels)
        /// 4- Disable excessive loading on the top part.
        await viewModel?.scrollVM.disableExcessiveLoading()
        setHasMoreTopNonAsync(response)
        let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: beforeSectionCount, viewModels)

        let moveToMessage = await viewModel?.scrollVM.lastContentOffsetY ?? 0 < 24
        var indexPathToScroll: IndexPath?
        if moveToMessage, let lastTopMessageVM = lastTopMessageVM {
            indexPathToScroll = sections.indexPath(for: lastTopMessageVM)
        }
        await delegate?.inserted(tuple.sections, tuple.rows, .top, indexPathToScroll)
        
        if let row = shouldUpdateOldTopSection, let indexPath = sections.indexPath(for: row) {
            await delegate?.reloadData(at: indexPath)
        }
                
        /// We should not detect last message deleted if we are going to fetch with middleFetcher
        /// because the list is empty before we move to time, so it will calculate it wrongly.
        /// And if we moveToTime, and start scrolling to top the list is not empty anymore,
        /// so the wasEmpty is false.
        if !isMiddleFetcher, wasEmpty {
            await detectLastMessageDeleted(sortedMessages: sortedMessages)
        }
   
        topLoading = false
        await MainActor.run {
            // Register for downloading thumbnails or read cached version
            for vm in viewModels {
                vm.register()
            }
            viewModel?.delegate?.startTopAnimation(false)
            if !isMiddleFetcher {
                fetchReactions(messages: viewModels.compactMap({$0.message}))
            }
        }
        
        await prepareAvatars(viewModels)
    }
    
    private func stitchAvatarsOnLoadMoreTop(_ sortedVMS: [MessageRowViewModel]) -> MessageRowViewModel? {
        let sorted = sortedVMS.sorted(by: {$0.message.id ?? 0 < $1.message.id ?? 0 })
        guard
            let sectionFirstMessage = sections.first?.vms.first,
            let lastSortedMessage = sorted.last
        else { return nil }
        
        var shouldUpdateTopInSection = false
        if sectionFirstMessage.message.ownerId == lastSortedMessage.message.ownerId {
            sectionFirstMessage.calMessage.isFirstMessageOfTheUser = false
            lastSortedMessage.calMessage.isLastMessageOfTheUser = false
            shouldUpdateTopInSection = true
        }
        
        return shouldUpdateTopInSection ? sectionFirstMessage : nil
    }
    
    private func stitchAvatarsOnLoadMoreBottom(_ sortedVMS: [MessageRowViewModel]) -> MessageRowViewModel? {
        let sorted = sortedVMS.sorted(by: {$0.message.id ?? 0 < $1.message.id ?? 0 })
        guard
            let sectionLastMessage = sections.last?.vms.last,
            let firstSortedMessage = sorted.first
        else { return nil }
        
        var shouldUpdateBottomInSection = false
        if sectionLastMessage.message.ownerId == firstSortedMessage.message.ownerId {
            sectionLastMessage.calMessage.isLastMessageOfTheUser = false
            firstSortedMessage.calMessage.isFirstMessageOfTheUser = false
            shouldUpdateBottomInSection = true
        }
        
        return shouldUpdateBottomInSection ? sectionLastMessage : nil
    }

    private func detectLastMessageDeleted(sortedMessages: [HistoryMessageType]) async {
        if await isLastMessageEqualToLastSeen(), await !isLastMessageExistInSortedMessages(sortedMessages) {
            let lastSortedMessage = sortedMessages.last
            await MainActor.run {
                viewModel?.thread.lastMessageVO = (lastSortedMessage as? Message)?.toLastMessageVO
            }
            await setIsAtBottom(newValue: true)
            await highlightVM.showHighlighted(lastSortedMessage?.uniqueId ?? "",
                                                lastSortedMessage?.id ?? -1,
                                                highlight: false)
        }
    }
    
    private func reloadIfStitchChangedOnNewMessage(_ bottomVMBeforeJoin: MessageRowViewModel?, _ newMessage: Message) async {
        guard
            let bottomVMBeforeJoin = bottomVMBeforeJoin,
            bottomVMBeforeJoin.message.ownerId == newMessage.ownerId,
            let indexPath = sections.indexPath(for: bottomVMBeforeJoin)
        else { return }
        bottomVMBeforeJoin.calMessage.isLastMessageOfTheUser = false
        await delegate?.reloadData(at: indexPath)
    }

    private func moreBottom(prepend: String, _ fromTime: UInt?) async {
        if await !canLoadMoreBottom() { return }
        await showBottomLoading(true)
        let req = await makeRequest(fromTime: fromTime, offset: nil)
        log("SendMoreBottomRequest")
        doRequest(req, prepend)
    }

    private func onMoreBottom(_ response: HistoryResponse, isMiddleFetcher: Bool = false) async {
        let messages = response.result ?? []
        let beforeSectionCount = sections.count
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)
        let shouldUpdateOldBottomSection = stitchAvatarsOnLoadMoreBottom(viewModels)

        await waitingToFinishDecelerating()
        await waitingToFinishUpdating()
        await appendSort(viewModels)
        /// 4- Disable excessive loading on the top part.
        await viewModel?.scrollVM.disableExcessiveLoading()
        await setHasMoreBottom(response)
        let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, viewModels)
        await delegate?.inserted(tuple.sections, tuple.rows, .left, nil)

        if let row = shouldUpdateOldBottomSection, let indexPath = sections.indexPath(for: row) {
            await delegate?.reloadData(at: indexPath)
        }
        
        for vm in viewModels {
            await vm.register()
        }

        isFetchedServerFirstResponse = true
        await showBottomLoading(false)

        if !isMiddleFetcher {
            await fetchReactions(messages: viewModels.compactMap({$0.message}))
        }
        await prepareAvatars(viewModels)
    }

    public func loadMoreTop(message: HistoryMessageType) async {
        if let time = message.time {
            await moreTop(prepend: keys.MORE_TOP_KEY, time)
        }
    }

    public func loadMoreBottom(message: HistoryMessageType) async {
        if let time = message.time {
            // We add 1 milliseceond to prevent duplication and fetch the message itself.
            await moreBottom(prepend: keys.MORE_BOTTOM_KEY, time.advanced(by: 1))
        }
    }

    private func makeCalculateViewModelsFor(_ messages: [HistoryMessageType]) async -> [MessageRowViewModel] {
        let mainData = await getMainData()
        return await MessageRowCalculators.batchCalulate(messages, mainData: mainData, viewModel: viewModel)
    }
}

// MARK: Requests
extension ThreadHistoryViewModel {

    private func doRequest(_ req: GetHistoryRequest, _ prepend: String, _ store: OnMoveTime? = nil) {
        RequestsManager.shared.append(prepend: prepend, value: store ?? req)
        logHistoryRequest(req: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.history(req)
        }
    }
    
    private func doRequestQueue(_ req: GetHistoryRequest, _ prepend: String, _ store: OnMoveTime? = nil) async {
        RequestsManager.shared.append(prepend: prepend, value: store ?? req)
        logHistoryRequest(req: req)
        await AppState.shared.objectsContainer.chatRequestQueue.enqueue(.history(req: req))
    }

    private func makeRequest(fromTime: UInt? = nil, toTime: UInt? = nil, offset: Int?) async -> GetHistoryRequest {
        GetHistoryRequest(threadId: threadId,
                          count: count,
                          fromTime: fromTime,
                          offset: offset,
                          order: fromTime != nil ? "asc" : "desc",
                          toTime: toTime,
                          readOnly: await viewModel?.readOnly == true)
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
        case .history(let response):
            await onHistory(response)
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

    private func onHistory(_ response: ChatResponse<[Message]>) async {
        if !response.cache, response.subjectId == threadId, middleFetcher?.isContaninsKeys(response) == false {
            log("Start on history:\(Date().millisecondsSince1970)")
            /// For the first scenario.
            if response.pop(prepend: keys.MORE_TOP_FIRST_SCENARIO_KEY) != nil {
                await onMoreTopFirstScenario(response)
            }

            if response.pop(prepend: keys.MORE_BOTTOM_FIRST_SCENARIO_KEY) != nil {
                await onMoreBottomFirstScenario(response)
            }

            /// For the second scenario.
            if response.pop(prepend: keys.MORE_TOP_SECOND_SCENARIO_KEY) != nil {
                await onMoreTopSecondScenario(response)
            }

            /// For the scenario three and four.
            if response.pop(prepend: keys.MORE_TOP_KEY) != nil {
                await onMoreTop(response)
            }

            /// For the scenario three and four.
            if response.pop(prepend: keys.MORE_BOTTOM_KEY) != nil {
                await onMoreBottom(response)
            }

            /// For the fifth scenario.
            if response.pop(prepend: keys.MORE_BOTTOM_FIFTH_SCENARIO_KEY) != nil {
                await onMoreBottomFifthScenario(response)
            }

            /// For the seventh scenario.
            if response.pop(prepend: keys.FETCH_BY_OFFSET_KEY) != nil {
                await onFetchByOffset(response)
            }

            await setIsEmptyThread()
            log("End on history:\(Date().millisecondsSince1970)")
        } else if response.cache, await !isConnected {
            await onHistoryCacheRsponse(response)
        }
    }

    // It will be only called by ThreadsViewModel
    public func onNewMessage(_ messages: [Message], _ oldConversation: Conversation?, _ updatedConversation: Conversation) async {
        thread = updatedConversation
        let wasAtBottom = await isLastMessageInsideTheSections(oldConversation)
        if let viewModel = await viewModel, wasAtBottom {
            for message in messages {
                let bottomVMBeforeJoin = sections.last?.vms.last
                await MainActor.run {
                    self.viewModel?.thread = updatedConversation
                }
                let currentIndexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "")
                let vm = await insertOrUpdateMessageViewModelOnNewMessage(message, viewModel)
                await viewModel.scrollVM.scrollToNewMessageIfIsAtBottomOrMe(message)
                await vm.register()
                await sortAndMoveRowIfNeeded(message: message, currentIndexPath: currentIndexPath)
                await reloadIfStitchChangedOnNewMessage(bottomVMBeforeJoin, message)
            }
        }
        await viewModel?.updateUnreadCount(updatedConversation.unreadCount)
        await setSeenForAllOlderMessages(newMessage: messages.last ?? .init(), myId: await appUserId ?? -1)
        await setIsEmptyThread()
    }

    /*
     We use this method in new messages due to the fact that, if we are uploading multiple files/pictures...
     we don't know when the upload message will be completed, thus it's essential to sort them and then check if the row has been moved after sorting.
    */
    private func sortAndMoveRowIfNeeded(message: Message, currentIndexPath: IndexPath?) async {
        sort()
        let newIndexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "")
        if let currentIndexPath = currentIndexPath, let newIndexPath = newIndexPath, currentIndexPath != newIndexPath {
            await delegate?.moveRow(at: currentIndexPath, to: newIndexPath)
            await viewModel?.scrollVM.scrollToNewMessageIfIsAtBottomOrMe(message)
        }
    }

    /*
     Check if we have the last message in our list,
     It'd useful in case of onNewMessage to check if we have move to time or not.
     We also check greater messages in the last section, owing to
     when I send a message it will append to the list immediately, and then it will be updated by the sent/deliver method.
     Therefore, the id is greater than the id of the previous conversation.lastMessageVO.id
     */
    private func isLastMessageInsideTheSections(_ oldConversation: Conversation?) async -> Bool {
        let hasAnyUploadMessage = await viewModel?.uploadMessagesViewModel.hasAnyUploadMessage() ?? false
        let isLastMessageExistInLastSection = sections.last?.vms.last?.message.id ?? 0 >= oldConversation?.lastMessageVO?.id ?? 0
        return isLastMessageExistInLastSection || hasAnyUploadMessage
    }

    private func insertOrUpdateMessageViewModelOnNewMessage(_ message: Message, _ viewModel: ThreadViewModel) async -> MessageRowViewModel {
        let beforeSectionCount = sections.count
        let vm: MessageRowViewModel
        let mainData = await getMainData()
        if let indexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "") {
            // Update a message sent by Me
            vm = sections[indexPath.section].vms[indexPath.row]
            vm.swapUploadMessageWith(message)
            await vm.recalculate(mainData: mainData)
            await delegate?.reloadData(at: indexPath) // Do not call reload(at:) the item it will lead to call endDisplay
        } else {
            // A new message comes from server
            vm = MessageRowViewModel(message: message, viewModel: viewModel)
            await vm.recalculate(appendMessages: [message], mainData: mainData)
            await appendSort([vm])
            let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, [vm])
            if vm.message.ownerId == sections.last?.vms.last?.message.ownerId {
                vm.calMessage.isFirstMessageOfTheUser = false
                vm.calMessage.isLastMessageOfTheUser = true
            }
            await delegate?.inserted(tuple.sections, tuple.rows, .left, nil)
        }
        return vm
    }

    private func onEdited(_ response: ChatResponse<Message>) async {
        if let message = response.result, let vm = sections.messageViewModel(for: message.id ?? -1) {
            vm.message.message = message.message
            vm.message.time = message.time
            vm.message.edited = true
            let mainData = await getMainData()
            await vm.recalculate(mainData: mainData)
            guard let indexPath = sections.indexPath(for: vm) else { return }
            await MainActor.run {
                delegate?.edited(indexPath)
            }
        }
    }

    private func onPinMessage(_ response: ChatResponse<PinMessage>) async {
        if let messageId = response.result?.messageId, let vm = sections.messageViewModel(for: messageId) {
            vm.pinMessage(time: response.result?.time)
            guard let indexPath = sections.indexPath(for: vm) else { return }
            await MainActor.run {
                delegate?.pinChanged(indexPath)
            }
        }
    }

    private func onUNPinMessage(_ response: ChatResponse<PinMessage>) async {
        if let messageId = response.result?.messageId, let vm = sections.messageViewModel(for: messageId) {
            vm.unpinMessage()
            guard let indexPath = sections.indexPath(for: vm) else { return }
            await MainActor.run {
                delegate?.pinChanged(indexPath)
            }
        }
    }

    private func onDeliver(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        vm.message.delivered = true
        let mainData = await getMainData()
        await vm.recalculate(mainData: mainData)
        await MainActor.run {
            delegate?.delivered(indexPath)
        }
    }

    private func onSeen(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        vm.message.delivered = true
        vm.message.seen = true
        let mainData = await getMainData()
        await vm.recalculate(mainData: mainData)
        await MainActor.run {
            delegate?.seen(indexPath)
        }
        if let messageId = response.result?.messageId, let myId = await appUserId {
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
        let mainData = await getMainData()
        await vm.recalculate(mainData: mainData)
        await MainActor.run {
            delegate?.sent(indexPath)
        }
    }
    
    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    internal func onDeleteMessage(_ messages: [Message], conversationId: Int) async {
        guard threadId == conversationId else { return }
        // We have to update the lastMessageVO to keep moveToBottom hide if the lastMessaegId deleted
        thread.lastMessageVO = await viewModel?.thread.lastMessageVO
        var indicies: [IndexPath] = []
        for message in messages {
            if let indexPath = sections.viewModelAndIndexPath(for: message.id ?? -1)?.indexPath {
                indicies.append(indexPath)
            }
        }
        /// Do not remove these lines, they are here for a reason.
        /// We first have to find all indicies to simulate the mSections indexPaths,
        /// then removing them from sections not ``mSections`` by ``again`` gettig the indexPath,
        /// We have to get indexPaths twice due to the fact that if not, it will crash the app becasue of wrong indexPath.
        /// When we delete from top to bottom the index path is going to be greater than total items, so it will crash.
        for message in messages {
            if let indexPath = sections.viewModelAndIndexPath(for: message.id ?? -1)?.indexPath {
                sections[indexPath.section].vms.remove(at: indexPath.row)
                if sections[indexPath.section].vms.count == 0 {
                    sections.remove(at: indexPath.section)
                }
            }
        }
        await setIsEmptyThread()
        await onDeleteMessage(indicies)
        for message in messages {
            await setDeletedIfWasReply(messageId: message.id ?? -1)
        }
    }
    
    @MainActor
    private func onDeleteMessage(_ indices: [IndexPath]) async {
        mSections = await sections
        delegate?.removed(at: indices)
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
        await MainActor.run { [sections] in
            mSections = sections
            for indexPath in indicesToReload {
                delegate?.reloadData(at: indexPath)
            }
        }
    }
}

// MARK: Append/Sort/Delete
extension ThreadHistoryViewModel {

    private func appendSort(_ viewModels: [MessageRowViewModel]) async {
        log("Start of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        guard viewModels.count > 0 else { return }
        for vm in viewModels {
            insertIntoProperSection(vm)
        }
        sort()
        log("End of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        lastItemIdInSections = sections.last?.vms.last?.id ?? 0
        await MainActor.run { [sections] in
            mSections = sections
        }
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

    public func injectMessagesAndSort(_ requests: [HistoryMessageType]) async {
        let viewModels = await makeCalculateViewModelsFor(requests)
        await appendSort(viewModels)
        for vm in viewModels {
            await vm.register()
        }
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

    @MainActor
    public func deleteMessages(_ messages: [HistoryMessageType], forAll: Bool = false) async {
        let messagedIds = messages.compactMap(\.id)
        let threadId = await threadId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.delete(.init(threadId: await threadId, messageIds: messagedIds, deleteForAll: forAll))
        }
        viewModel?.selectedMessagesViewModel.clearSelection()
    }

    private func appenedUnreadMessagesBannerIfNeeed() async {
        guard
            thread.unreadCount ?? 0 > 0, // in self thread it's essential to check the value always, if not we will always get unread banner.
            let tuples = sections.message(for: thread.lastSeenMessageId),
            let viewModel = await viewModel
        else { return }
        let time = (tuples.message.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time, uniqueId: "\(LocalId.unreadMessageBanner.rawValue)")
        let indexPath = tuples.indexPath
        let vm = MessageRowViewModel(message: unreadMessage, viewModel: viewModel)
        let mainData = await getMainData()
        await vm.recalculate(mainData: mainData)
        sections[indexPath.section].vms.append(vm)
        await MainActor.run { [weak self, sections] in
            guard let self = self else { return }
            mSections = sections
            let bannerIndexPath = IndexPath(row: sections[indexPath.section].vms.indices.last!, section: indexPath.section)
            delegate?.inserted(at: bannerIndexPath)
        }
        try? await Task.sleep(for: .seconds(0.5))
        await MainActor.run {
            delegate?.scrollTo(index: indexPath, position: .middle, animate: true)
        }
    }

    private func removeAllSections() async {
        sections.removeAll()
        await MainActor.run {
            mSections.removeAll()
        }
    }
}

// MARK: Appear/Disappear/Display/End Display
extension ThreadHistoryViewModel {
    public func willDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        await visibleTracker.append(message: message)
        log("Message appear id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        if message.id == thread.lastMessageVO?.id {
            await setIsAtBottom(newValue: true)
            /// Hide the move to bottom button if the last message of the thread is visible,
            /// when we are loading more bottom and we reach to the last message of the thread,
            /// we have to hide this button.
            await delegate?.showMoveToButtom(show: false)
        }
        await seenVM?.onAppear(message)
    }

    public func didEndDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        log("Message disappeared id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        await visibleTracker.remove(message: message)
        if message.id == thread.lastMessageVO?.id {
            await setIsAtBottom(newValue: false)
        }
    }

    @MainActor
    private func setIsAtBottom(newValue: Bool) {
        if viewModel?.scrollVM.isAtBottomOfTheList != newValue, viewModel?.isDeletingLastMessage == false {
            viewModel?.scrollVM.isAtBottomOfTheList = newValue
            viewModel?.delegate?.lastMessageAppeared(newValue)
        }
    }

    public func didScrollTo(_ contentOffset: CGPoint, _ contentSize: CGSize) async {
        if isInProcessingScroll() {
            logScroll("IsProcessingScroll")
            await viewModel?.scrollVM.lastContentOffsetY = contentOffset.y
            if contentOffset.y < 0 {
                await doScrollAction(contentOffset, contentSize)
            }
            return
        }
        logScroll("NonProcessing")
        await doScrollAction(contentOffset, contentSize)
        await viewModel?.scrollVM.lastContentOffsetY = contentOffset.y
    }

    private func doScrollAction(_ contentOffset: CGPoint , _ contentSize: CGSize) async {
        guard let scrollVM = await viewModel?.scrollVM else { return }
        logScroll("ContentOffset: \(contentOffset) lastContentOffsetY: \(scrollVM.lastContentOffsetY)")
        if contentOffset.y > 0, contentOffset.y >= scrollVM.lastContentOffsetY {
            // scroll down
            logScroll("DOWN")
            scrollVM.scrollingUP = false
            if contentOffset.y > contentSize.height - threshold, let message = sections.last?.vms.last?.message {
                logScroll("LoadMoreBottom")
                await loadMoreBottom(message: message)
            }
        } else {
            /// There is a chance if we are at the top of a table view and due to we have negative value at top because of contentInset
            /// it will start to fetch the data however, if we are at end of the top list it won't get triggered.
            // scroll up
            logScroll("UP")
            scrollVM.scrollingUP = true
            if contentOffset.y < threshold, let message = sections.first?.vms.first?.message {
                logScroll("LoadMoreTop")
                await loadMoreTop(message: message)
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
}

// MARK: Observers On MainActor
@MainActor
extension ThreadHistoryViewModel {
    private func setupNotificationObservers() {
        observe(AppState.shared.$connectionStatus) { [weak self] status in
            await self?.onConnectionStatusChanged(status)
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
            await self?.updateAllRows()
        }
        
        observe(NotificationCenter.upload.publisher(for: .upload)) { [weak self] notification in
            if let event = notification.object as? UploadEventTypes {
                await self?.onUploadEvents(event)
            }
        }
    }
    
    private func observe<P: Publisher>(_ publisher: P, action: @escaping (P.Output) async -> Void) where P.Failure == Never {
        publisher
            .sink { value in
                Task {
                    await action(value)
                }
            }
            .store(in: &cancelable)
    }

    internal func cancel() {
        cancelAllObservers()
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
#if DEBUG
        Task.detached {
            let date = Date().millisecondsSince1970
            Logger.viewModels.debug("Start of sending history request: \(date) milliseconds")
        }
#endif
    }

    private func log(_ string: String) {
#if DEBUG
        Task.detached {
            Logger.viewModels.info("\(string, privacy: .sensitive)")
        }
#endif
    }
    
    private func logScroll(_ string: String) {
#if DEBUG
        Task.detached {
            Logger.viewModels.info("SCROLL: \(string)")
        }
#endif
    }
}

// MARK: Reactions
extension ThreadHistoryViewModel {
    @MainActor
    private func fetchReactions(messages: [HistoryMessageType]) {
        if viewModel?.searchedMessagesViewModel.isInSearchMode == false {
            Task {
                await viewModel?.reactionViewModel.fetchReactions(messages: messages.compactMap({$0 as? Message}), withQueue: false)
            }
        }
    }
}

// MARK: Scenarios utilities
extension ThreadHistoryViewModel {
    private func setHasMoreTop(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            await showTopLoading(false)
        }
    }
    
    private func setHasMoreTopNonAsync(_ response: ChatResponse<[Message]>) {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
        }
    }

    private func setHasMoreBottom(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextBottom = response.hasNext
            isFetchedServerFirstResponse = true
            await showBottomLoading(false)
        }
    }

    private func removeOldBanner() async {
        if let indices = sections.indicesByMessageUniqueId("\(LocalId.unreadMessageBanner.rawValue)") {
            sections[indices.section].vms.remove(at: indices.row)
            await MainActor.run {
                mSections[indices.section].vms.remove(at: indices.row)
                delegate?.removed(at: indices)
            }
        }
    }

    private func canLoadMoreTop() async -> Bool {
        let isProgramaticallyScroll = await viewModel?.scrollVM.getIsProgramaticallyScrolling() == true
        return hasNextTop && !topLoading && !isProgramaticallyScroll && !bottomLoading
    }

    private func canLoadMoreBottom() async -> Bool {
        let isProgramaticallyScroll = await viewModel?.scrollVM.getIsProgramaticallyScrolling() == true
        return hasNextBottom && !bottomLoading && !isProgramaticallyScroll && !topLoading
    }

    public func setIsEmptyThread() async {
        let noMessage = isFetchedServerFirstResponse == true && sections.count == 0
        let emptyThread = await viewModel?.isSimulatedThared == true
        isEmptyThread = emptyThread || noMessage
        await delegate?.emptyStateChanged(isEmpty: isEmptyThread)
        if isEmptyThread {
            await showCenterLoading(false)
        }
    }
    
    public func setThreashold(_ threshold: CGFloat) {
        self.threshold = threshold
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
        if isNotMe, unseenMessages.count > 0 {
            for vm in unseenMessages {
                await setSeen(vm: vm)
            }
        }
    }
    
    private func setSeen(vm: MessageRowViewModel) async {
        if let indexPath = sections.indexPath(for: vm) {
            vm.message.delivered = true
            vm.message.seen = true
            let mainData = await getMainData()
            await vm.recalculate(mainData: mainData)
            await MainActor.run {
                delegate?.seen(indexPath)
            }
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
    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if await canGetNewMessagesAfterConnectionEstablished(status) {
            // After connecting again get latest messages.
            await tryFifthScenario(status: status)
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if await !isSimulated(), status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            await startFetchingHistory()
        }
    }

    private func updateAllRows() async {
        let mainData = await getMainData()
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
    private func onCancelTimer(key: String) async {
        if topLoading || bottomLoading {
            topLoading = false
            bottomLoading = false
            await showTopLoading(false)
            await showBottomLoading(false)
        }
    }
}

public extension ThreadHistoryViewModel {
    @MainActor
    func getSections() async -> ContiguousArray<MessageSection> {
        return await sections
    }
    
    @MainActor
    func getMainData() -> MainRequirements {
        return MainRequirements(appUserId: AppState.shared.user?.id,
                                thread: viewModel?.thread,
                                participantsColorVM: viewModel?.participantsColorVM,
                                isInSelectMode: viewModel?.selectedMessagesViewModel.isInSelectMode ?? false)
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

    func waitingToFinishUpdating() async {
        while await isUpdating{}
    }
}

extension ThreadHistoryViewModel {
    private func showTopLoading(_ show: Bool) async {
        topLoading = show
        await viewModel?.delegate?.startTopAnimation(show)
    }

    private func showCenterLoading(_ show: Bool) async {
        centerLoading = show
        await viewModel?.delegate?.startCenterAnimation(show)
    }

    private func showBottomLoading(_ show: Bool) async {
        bottomLoading = show
        await viewModel?.delegate?.startBottomAnimation(show)
    }
}

// MARK: Conditions and common functions
extension ThreadHistoryViewModel {
    private func isLastMessageEqualToLastSeen() async -> Bool {
        let thread = await viewModel?.thread
        return thread?.lastMessageVO?.id ?? 0 == thread?.lastSeenMessageId ?? 0
    }
    
    private func isLastMessageExistInSortedMessages(_ sortedMessages: [HistoryMessageType]) async -> Bool {
        let lastMessageId = await viewModel?.thread.lastMessageVO?.id
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
    
    public func isSimulated() async -> Bool {
        let createThread = await AppState.shared.appStateNavigationModel.userToCreateThread != nil
        return createThread && thread.id == LocalId.emptyThread.rawValue
    }
    
    private var appUserId: Int? {
        get async {
            return await AppState.shared.user?.id
        }
    }
    
    private var isConnected: Bool {
        get async {
            await AppState.shared.connectionStatus == .connected
        }
    }
    
    public func indexPath(vm: MessageRowViewModel) -> IndexPath? {
        sections.indexPath(for: vm)
    }
    
    @MainActor
    public func showJumpToButtom() -> Bool {
        let readAllMeessges = viewModel?.thread.lastMessageVO?.id ?? -1 == viewModel?.thread.lastSeenMessageId ?? 0
        let hide = readAllMeessges || viewModel?.historyVM.mSections.isEmpty == true
        return !hide
    }
}
