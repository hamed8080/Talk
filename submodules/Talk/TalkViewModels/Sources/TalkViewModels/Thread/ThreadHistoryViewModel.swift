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

public typealias MessageType = any HistoryMessageProtocol
public typealias MessageIndex = Array<MessageType>.Index
public typealias SectionIndex = Array<MessageSection>.Index
public typealias HistoryResponse = ChatResponse<[Message]>

enum JoinPoint {
    case bottom(bottomVMBeforeJoin: MessageRowViewModel?)
    case top(topVMBeforeJoin: MessageRowViewModel?)
}

//@HistoryActor
public final class ThreadHistoryViewModel {
    // MARK: Stored Properties
    internal weak var viewModel: ThreadViewModel?
    public weak var delegate: HistoryScrollDelegate?
    public var sections: ContiguousArray<MessageSection> = .init()

    @HistoryActor private var threshold: CGFloat = 800
    private var created: Bool = false
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
    private var isJumpedToLastMessage = false
    private var tasks: [Task<Void, Error>] = []
    private var visibleTracker = VisibleMessagesTracker()
    private var highlightVM = ThreadHighlightViewModel()
    private var isEmptyThread = false
    private var lastItemIdInSections = 0
    private let keys = RequestKeys()
    
    @MainActor
    public var isUpdating = false
    private var lastScrollTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.5 // 500 milliseconds

    // MARK: Computed Properties
    private var thread: Conversation { viewModel?.thread ?? .init(id: -1) }
    private var threadId: Int { thread.id ?? -1 }
    private var isSimulated: Bool { viewModel?.isSimulatedThared == true }

    // MARK: Initializer
    nonisolated public init() {}
}

extension ThreadHistoryViewModel: StabledVisibleMessageDelegate {
    func onStableVisibleMessages(_ messages: [MessageType]) {
        Task { @HistoryActor [weak self] in
            guard let self = self else { return }
            let invalidVisibleMessages = await getInvalidVisibleMessages().compactMap({$0 as? Message})
            if invalidVisibleMessages.count > 0 {
                viewModel?.reactionViewModel.fetchReactions(messages: invalidVisibleMessages)
            }
        }
    }
}

extension ThreadHistoryViewModel {
    internal func getInvalidVisibleMessages() async -> [MessageType] {
        var invalidMessages: [Message] =  []
        let list = await visibleTracker.visibleMessages.compactMap({$0 as? Message})
        for message in list {
            if let vm = sections.messageViewModel(for: message.id ?? -1), vm.isInvalid {
                invalidMessages.append(message)
            }
        }
        return invalidMessages
    }
}

// MARK: Setup/Start
extension ThreadHistoryViewModel {
    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        highlightVM.setup(self)
        visibleTracker.delegate = self
        setupNotificationObservers()
    }

    // MARK: Scenarios Common Functions
    public func start() {
        Task { @HistoryActor in
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
    }

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    private func startFetchingHistory() async {
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let isSimulatedThread = viewModel?.isSimulatedThared == true
        let hasAnythingToLoadOnOpen = AppState.shared.appStateNavigationModel.moveToMessageId != nil
        await moveToMessageTimeOnOpenConversation()
        await setIsEmptyThread()
        if sections.count > 0 || hasAnythingToLoadOnOpen || isSimulatedThread { return }
        hasSentHistoryRequest = true
        tryFirstScenario()
        trySecondScenario()
        trySeventhScenario()
        await tryEightScenario()
        tryNinthScenario()
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
                showTopLoading(false) // We do not need to show two loadings at the same time.
            }
        }
    }

    @HistoryActor
    private func onMoreTopFirstScenario(_ response: HistoryResponse) async {
        await onMoreTop(response)
        /* 
         It'd be better to go to the last message in the sections, instead of finding the item.
         If the last message has been deleted, we can not find the message.
         Consequently, the scroll to the last message won't work.
        */
        let uniqueId = sections.last?.vms.last?.message.uniqueId
        delegate?.scrollTo(uniqueId: uniqueId ?? "", position: .bottom, animate: false)

        /// 4- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
        if let fromTime = thread.lastSeenMessageTime {
            viewModel?.scrollVM.isProgramaticallyScroll = false
            await appenedUnreadMessagesBannerIfNeeed()
            await moreBottom(prepend: keys.MORE_BOTTOM_FIRST_SCENARIO_KEY, fromTime.advanced(by: 1))
        }
        showCenterLoading(false)
    }

    private func onMoreBottomFirstScenario(_ response: HistoryResponse) async {
        await onMoreBottom(response)
    }

    // MARK: Scenario 2
    private func trySecondScenario() {
        /// 1- Get the top part to time messages
        if isLastMessageEqualToLastSeen(), let toTime = thread.lastSeenMessageTime {
            Task {
                hasNextBottom = false
                await moreTop(prepend: keys.MORE_TOP_SECOND_SCENARIO_KEY, toTime.advanced(by: 1))
                showTopLoading(false) // We have to hide it to prevent double loading center and top
            }
        }
    }

    private func onMoreTopSecondScenario(_ response: HistoryResponse) async {
        await onMoreTop(response)
        if let uniqueId = thread.lastMessageVO?.uniqueId, let messageId = thread.lastMessageVO?.id {
            delegate?.reload()
            delegate?.scrollTo(uniqueId: uniqueId, position: .bottom, animate: false)
            await highlightVM.showHighlighted(uniqueId, messageId, highlight: false)
        }
        showCenterLoading(false)
        await fetchReactions(messages: response.result ?? [])
    }

    // MARK: Scenario 3 or 4 more top/bottom.

    // MARK: Scenario 5
    private func tryFifthScenario(status: ConnectionStatus) {
        /// 1- Get the bottom part of the list of what is inside the memory.
        if canGetNewMessagesAfterConnectionEstablished(status), let lastMessageInListTime = sections.last?.vms.last?.message.time {
            showBottomLoading(true)
            let req = makeRequest(fromTime: lastMessageInListTime.advanced(by: 1))
            doRequest(req, keys.MORE_BOTTOM_FIFTH_SCENARIO_KEY)
        }
    }

    private func canGetNewMessagesAfterConnectionEstablished(_ status: ConnectionStatus) -> Bool {
        return !isSimulated && status == .connected && isFetchedServerFirstResponse == true && viewModel?.isActiveThread == true
    }

    private func onMoreBottomFifthScenario(_ response: HistoryResponse) async {
        let bottomVMBeforeJoin = sections.last?.vms.last
        let messages = response.result ?? []
        /// 2- Append the unread message banner at the end of the array. It does not need to be sorted because it has been sorted by the above function.
        if messages.count > 0 {
            removeOldBanner()
            await appenedUnreadMessagesBannerIfNeeed()
            viewModel?.scrollVM.isAtBottomOfTheList = false
        }

        /// 3- Append and sort and calculate the array but not call to update the view.
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)
        appendSort(viewModels)
        delegate?.reload()
        await updateIsLastMessageAndIsFirstMessageFor(viewModels, at: .bottom(bottomVMBeforeJoin: bottomVMBeforeJoin))

        /// 4- Set whether it has more messages at the bottom or not.
        await setHasMoreBottom(response)
        showBottomLoading(false)
        showCenterLoading(false)
        for vm in viewModels {
            await vm.register()
        }
        await fetchReactions(messages: messages)
    }

    // MARK: Scenario 6
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true, moveToBottom: Bool = false) async {
        /// 1- Move to a message locally if it exists.
        if moveToBottom, !sections.isLastSeenMessageExist(thread: thread) {
            sections.removeAll()
        } else if let uniqueId = canMoveToMessageLocally(messageId) {
            showCenterLoading(false) // To hide center loading if the uer click on reply privately header to jump back to the thread.
            await moveToMessageLocally(uniqueId, messageId, highlight, true)
            return
        } else {
            log("The message id to move to is not exist in the list")
        }

        await setIsAtBottom(newValue: false)
        showCenterLoading(true)
        showTopLoading(false)

        sections.removeAll()
        delegate?.reload()
        /// 2- Fetch the top part of the message with the message itself.
        let toTimeReq = makeRequest(toTime: time.advanced(by: 1))
        let store = OnMoveTime(messageId: messageId, request: toTimeReq, highlight: highlight)
        doRequest(toTimeReq, keys.TO_TIME_KEY, store)
    }

    private func onMoveToTime(_ response: HistoryResponse, request: OnMoveTime) async {
        let messages = response.result ?? []
        // Update the UI and fetch reactions the rows at top part.
        await onMoreTop(response)
        showCenterLoading(false)

        let uniqueId = messages.first(where: {$0.id == request.messageId})?.uniqueId ?? ""
        await highlightVM.showHighlighted(uniqueId, request.messageId, highlight: request.highlight, position: .middle)

        let fromTimeRequest = makeRequest(fromTime: request.request.toTime)
        let store = OnMoveTime(messageId: request.messageId, request: fromTimeRequest, highlight: request.highlight)
        doRequest(fromTimeRequest, keys.FROM_TIME_KEY, store)
        showBottomLoading(true)
    }

    private func onMoveFromTime(request: OnMoveTime, _ response: HistoryResponse) async {
        let bottomVMBeforeJoin = sections.last?.vms.last
        let messages = response.result ?? []
        let beforeSectionCount = sections.count
        /// 8- Append and sort the array but not call to update the view.
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)
        appendSort(viewModels)
        let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, viewModels)
        delegate?.inserted(tuple.sections, tuple.rows, .fade, nil)
        await updateIsLastMessageAndIsFirstMessageFor(viewModels, at: .bottom(bottomVMBeforeJoin: bottomVMBeforeJoin))
        for vm in viewModels {
            await vm.register()
        }
        await setHasMoreBottom(response)
        showCenterLoading(false)
        await fetchReactions(messages: messages)
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    private func moveToMessageLocally(_ uniqueId: String, _ messageId: Int, _ highlight: Bool, _ animate: Bool = false) async {
        await highlightVM.showHighlighted(uniqueId, messageId, highlight: highlight, position: .top, animate: animate)
    }

    // MARK: Scenario 7
    /// When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug or when the conversation is empty.
    private func trySeventhScenario() {
        if thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 {
            requestBottomPartByCountAndOffset()
        }
    }

    private func requestBottomPartByCountAndOffset() {
        let req = makeRequest()
        doRequest(req, keys.FETCH_BY_OFFSET_KEY)
    }

    private func onFetchByOffset(_ response: HistoryResponse) async {
        let bottomVMBeforeJoin = sections.last?.vms.last
        let messages = response.result ?? []
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)
        appendSort(viewModels)
        isFetchedServerFirstResponse = true
        delegate?.reload()
        await updateIsLastMessageAndIsFirstMessageFor(viewModels, at: .bottom(bottomVMBeforeJoin: bottomVMBeforeJoin))
        await highlightVM.showHighlighted(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
        for vm in viewModels {
            await vm.register()
        }
        showCenterLoading(false)
        await fetchReactions(messages: messages)
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
    private func tryNinthScenario() {
        if hasThreadNeverOpened() && thread.lastMessageVO == nil {
            requestBottomPartByCountAndOffset()
        }
    }

    // MARK: Scenario 10
    private func moveToMessageTimeOnOpenConversation() async {
        let model = AppState.shared.appStateNavigationModel
        if let id = model.moveToMessageId, let time = model.moveToMessageTime {
            await moveToTime(time, id, highlight: true)
            AppState.shared.appStateNavigationModel = .init()
        }
    }

    // MARK: On Cache History Response
    private func onHistoryCacheRsponse(_ response: HistoryResponse) async {
        let bottomVMBeforeJoin = sections.last?.vms.last
        let messages = response.result ?? []
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)
        
        await waitingToFinishDecelerating()
        await waitingToFinishUpdating()
        appendSort(viewModels)
        viewModel?.scrollVM.disableExcessiveLoading()
        isFetchedServerFirstResponse = false
        if response.containsPartial(prependedKey: keys.MORE_TOP_KEY) {
            hasNextTop = messages.count >= count // We just need the top part when the user open the thread while it's not connected.
        }
        showBottomLoading(true)
        showTopLoading(false)
        delegate?.reload()
        await updateIsLastMessageAndIsFirstMessageFor(viewModels, at: .bottom(bottomVMBeforeJoin: bottomVMBeforeJoin))
        if !isJumpedToLastMessage {
            await highlightVM.showHighlighted(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
            isJumpedToLastMessage = true
        }
        for vm in viewModels {
            await vm.register()
        }
        showCenterLoading(false)
    }

    @HistoryActor
    private func moreTop(prepend: String, _ toTime: UInt?) async {
        if !canLoadMoreTop() { return }
        showTopLoading(true)
        let req = makeRequest(toTime: toTime)
        doRequest(req, prepend)
    }

    @HistoryActor
    private func onMoreTop(_ response: HistoryResponse) async {
        // If the last message of the thread deleted and we have seen all the messages we move to top of the thread which is wrong
        let wasEmpty = sections.isEmpty
        let topVMBeforeJoin = sections.first?.vms.first
        let messages = response.result ?? []
        let lastTopMessageVM = sections.first?.vms.first
        let beforeSectionCount = sections.count
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)

        await waitingToFinishDecelerating()
        await waitingToFinishUpdating()
        appendSort(viewModels)
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        await setHasMoreTop(response)
        let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: beforeSectionCount, viewModels)

        let moveToMessage = viewModel?.scrollVM.lastContentOffsetY ?? 0 < 24
        var indexPathToScroll: IndexPath?
        if moveToMessage, let lastTopMessageVM = lastTopMessageVM {
            indexPathToScroll = sections.indexPath(for: lastTopMessageVM)
        }
        delegate?.inserted(tuple.sections, tuple.rows, .top, indexPathToScroll)
        await updateIsLastMessageAndIsFirstMessageFor(viewModels, at: .top(topVMBeforeJoin: topVMBeforeJoin))

        await detectLastMessageDeleted(wasEmptyBeforeInsert: wasEmpty, sortedMessages: sortedMessages)

        // Register for downloading thumbnails or read cached version
        for vm in viewModels {
            await vm.register()
        }
        showTopLoading(false)
        await fetchReactions(messages: viewModels.compactMap({$0.message}))
        prepareAvatars(viewModels)
    }

    private func detectLastMessageDeleted(wasEmptyBeforeInsert: Bool, sortedMessages: [any HistoryMessageProtocol]) async {
        if wasEmptyBeforeInsert, isLastMessageEqualToLastSeen(), !isLastMessageExistInSortedMessages(sortedMessages) {
            let lastSortedMessage = sortedMessages.last
            viewModel?.thread.lastMessageVO = (lastSortedMessage as? Message)?.toLastMessageVO
            await setIsAtBottom(newValue: true)
            await highlightVM.showHighlighted(lastSortedMessage?.uniqueId ?? "",
                                                lastSortedMessage?.id ?? -1,
                                                highlight: false)
        }
    }

    private func moreBottom(prepend: String, _ fromTime: UInt?) async {
        if !canLoadMoreBottom() { return }
        showBottomLoading(true)
        let req = makeRequest(fromTime: fromTime)
        doRequest(req, prepend)
    }

    @HistoryActor
    private func onMoreBottom(_ response: HistoryResponse) async {
        let bottomVMBeforeJoin = sections.last?.vms.last
        let messages = response.result ?? []
        let beforeSectionCount = sections.count
        let sortedMessages = messages.sortedByTime()
        let viewModels = await makeCalculateViewModelsFor(sortedMessages)

        await waitingToFinishDecelerating()
        await waitingToFinishUpdating()
        appendSort(viewModels)
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        await setHasMoreBottom(response)
        let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, viewModels)
        delegate?.inserted(tuple.sections, tuple.rows, .left, nil)
        await updateIsLastMessageAndIsFirstMessageFor(viewModels, at: .bottom(bottomVMBeforeJoin: bottomVMBeforeJoin))

        for vm in viewModels {
            await vm.register()
        }

        isFetchedServerFirstResponse = true
        showBottomLoading(false)

        await fetchReactions(messages: viewModels.compactMap({$0.message}))
        prepareAvatars(viewModels)
    }

    public func loadMoreTop(message: MessageType) async {
        if let time = message.time {
            await moreTop(prepend: keys.MORE_TOP_KEY, time)
        }
    }

    public func loadMoreBottom(message: MessageType) async {
        if let time = message.time {
            // We add 1 milliseceond to prevent duplication and fetch the message itself.
            await moreBottom(prepend: keys.MORE_BOTTOM_KEY, time.advanced(by: 1))
        }
    }

    private func makeCalculateViewModelsFor(_ messages: [any HistoryMessageProtocol]) async -> [MessageRowViewModel] {
        guard let viewModel = viewModel else { return [] }
        return await withTaskGroup(of: MessageRowViewModel.self) { group in
            for message in messages {
                group.addTask {
                    let vm = MessageRowViewModel(message: message, viewModel: viewModel)
                    await vm.performaCalculation(appendMessages: messages)
                    return vm
                }
            }

            var viewModels: [MessageRowViewModel] = []
            for await vm in group {
                viewModels.append(vm)
            }
            return viewModels
        }
    }
}

extension ThreadHistoryViewModel {
    func updateIsLastMessageAndIsFirstMessageFor(_ viewModels: [MessageRowViewModel], at joinPoint: JoinPoint) async {

        switch joinPoint {
        case .bottom(let bottomVMBeforeJoin):
            // bottom join point
            let firstMessageInMoreBottom = viewModels.first
            let sameUserOnJoinPoint = bottomVMBeforeJoin?.message.participant?.id == firstMessageInMoreBottom?.message.participant?.id
            if sameUserOnJoinPoint {
                // 1- Set Sections last message isLastMessage to false, if they are the same participant.
                if bottomVMBeforeJoin?.message.id != bottomVMBeforeJoin?.message.id {
                    await MainActor.run {
                        bottomVMBeforeJoin?.calMessage.isLastMessageOfTheUser = false
                    }
                    if let indexPath = sections.viewModelAndIndexPath(viewModelUniqueId: bottomVMBeforeJoin?.uniqueId ?? "")?.indexPath {
                        delegate?.reloadData(at: indexPath)
                    }
                }
                // 2- Set More bottom first message isFirstMessage to false, if they are the same participant.
                if let indexPath = sections.viewModelAndIndexPath(viewModelUniqueId: firstMessageInMoreBottom?.uniqueId ?? "")?.indexPath {
                    delegate?.reloadData(at: indexPath)
                    await MainActor.run {
                        firstMessageInMoreBottom?.calMessage.isFirstMessageOfTheUser = false
                    }
                }
            }
        case .top(let topVMBeforeJoin):
            let lastMessageInMoreTop = viewModels.last
            let sameUserOnJoinPoint = topVMBeforeJoin?.message.participant?.id == lastMessageInMoreTop?.message.participant?.id

            if sameUserOnJoinPoint {
                // 1- Set Sections first message isFirstMessage to false, if they are the same participant.
                await MainActor.run {
                    topVMBeforeJoin?.calMessage.isFirstMessageOfTheUser = false
                }
                if let indexPath = sections.viewModelAndIndexPath(viewModelUniqueId: topVMBeforeJoin?.uniqueId ?? "")?.indexPath {
                    delegate?.reloadData(at: indexPath)
                }
                // 2- Set More top last message isLastMessage to false, if they are the same participant.
                // We only set this value to false if lastMessageInMoreTop is not equal to the last messaege of the thread,
                // to prevent make it false when we open the thread for the first time.
                if lastMessageInMoreTop?.message.id ?? 0 != thread.lastMessageVO?.id ?? 0 {
                    await MainActor.run {
                        lastMessageInMoreTop?.calMessage.isLastMessageOfTheUser = false
                    }
                    if let indexPath = sections.viewModelAndIndexPath(viewModelUniqueId: lastMessageInMoreTop?.uniqueId ?? "")?.indexPath {
                        delegate?.reloadData(at: indexPath)
                    }
                }
            }
        }
    }
}

// MARK: Requests
extension ThreadHistoryViewModel {

    private func doRequest(_ req: GetHistoryRequest, _ prepend: String, _ store: OnMoveTime? = nil) {
        RequestsManager.shared.append(prepend: prepend, value: store ?? req)
        logHistoryRequest(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func makeRequest(fromTime: UInt? = nil, toTime: UInt? = nil, offset: Int = 0) -> GetHistoryRequest {
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
    private func onUploadEvents(_ notification: Notification) {
        guard let event = notification.object as? UploadEventTypes else { return }
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
            await onDeleteMessage(response)
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
        if !response.cache, response.subjectId == threadId {
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

            /// For the sixth scenario.
            if let request = response.pop(prepend: keys.TO_TIME_KEY) as? OnMoveTime {
                await onMoveToTime(response, request: request)
            }

            if let request = response.pop(prepend: keys.FROM_TIME_KEY) as? OnMoveTime {
                await onMoveFromTime(request: request, response)
            }

            await setIsEmptyThread()

            log("End on history:\(Date().millisecondsSince1970)")
        } else if response.cache && AppState.shared.connectionStatus != .connected {
            await onHistoryCacheRsponse(response)
        }
    }

    // It will be only called by ThreadsViewModel
    public func onNewMessage(_ message: Message, _ oldConversation: Conversation?, _ updatedConversation: Conversation) async {
        if let viewModel = viewModel, isLastMessageInsideTheSections(oldConversation) {
            let bottomVMBeforeJoin = sections.last?.vms.last
            self.viewModel?.thread = updatedConversation
            let currentIndexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "")
            let vm = await insertOrUpdateMessageViewModelOnNewMessage(message, viewModel)
            await viewModel.scrollVM.scrollToNewMessageIfIsAtBottomOrMe(message)
            await vm.register()
            await sortAndMoveRowIfNeeded(message: message, currentIndexPath: currentIndexPath)
            await updateAvatarAndGroupuserNameForLastUserMessageIfNeeded(message, bottomVMBeforeJoin)
        }
        setSeenForAllOlderMessages(newMessage: message)
        await setIsEmptyThread()
    }

    /*
     We use this method in new messages due to the fact that, if we are uploading multiple files/pictures...
     we don't know when the upload message will be completed, thus it's essential to sort them and then check if the row has been moved after sorting.
    */
    @HistoryActor
    private func sortAndMoveRowIfNeeded(message: Message, currentIndexPath: IndexPath?) async {
        sort()
        let newIndexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "")
        if let currentIndexPath = currentIndexPath, let newIndexPath = newIndexPath, currentIndexPath != newIndexPath {
            delegate?.moveRow(at: currentIndexPath, to: newIndexPath)
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
    private func isLastMessageInsideTheSections(_ oldConversation: Conversation?) -> Bool {
        let hasAnyUploadMessage = viewModel?.uploadMessagesViewModel.hasAnyUploadMessage() ?? false
        let isLastMessageExistInLastSection = sections.last?.vms.last?.message.id ?? 0 >= oldConversation?.lastMessageVO?.id ?? 0
        return isLastMessageExistInLastSection || hasAnyUploadMessage
    }

    private func insertOrUpdateMessageViewModelOnNewMessage(_ message: Message, _ viewModel: ThreadViewModel) async -> MessageRowViewModel {
        let beforeSectionCount = sections.count
        let vm: MessageRowViewModel
        if let indexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "") {
            // Update a message sent by Me
            vm = sections[indexPath.section].vms[indexPath.row]
            vm.swapUploadMessageWith(message)
            await vm.performaCalculation()
            delegate?.reloadData(at: indexPath) // Do not call reload(at:) the item it will lead to call endDisplay
        } else {
            // A new message comes from server
            vm = MessageRowViewModel(message: message, viewModel: viewModel)
            await vm.performaCalculation(appendMessages: [message])
            appendSort([vm])
            let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, [vm])
            delegate?.inserted(tuple.sections, tuple.rows, .left, nil)
        }
        return vm
    }

    private func updateAvatarAndGroupuserNameForLastUserMessageIfNeeded(_ message: Message, _ bottomVMBeforeJoin: MessageRowViewModel?) async {
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        if thread.group == true, !isMe, let vm = sections.messageViewModel(for: message.uniqueId ?? "") {
            await updateIsLastMessageAndIsFirstMessageFor([vm], at: .bottom(bottomVMBeforeJoin: bottomVMBeforeJoin))

            if let prevIndexPath = sections.sameUserPrevIndex(message) {
                sections[prevIndexPath.section].vms[prevIndexPath.row].calMessage.isLastMessageOfTheUser = false
                delegate?.reload(at: prevIndexPath)
            }
        }
    }

    private func onEdited(_ response: ChatResponse<Message>) async {
        if let message = response.result, let vm = sections.messageViewModel(for: message.id ?? -1) {
            vm.message.message = message.message
            vm.message.time = message.time
            vm.message.edited = true
            await vm.performaCalculation()
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
        await vm.performaCalculation()
        await vm.performaCalculation()
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
        await vm.performaCalculation()
        await MainActor.run {
            delegate?.seen(indexPath)
        }
        setSeenForOlderMessages(messageId: response.result?.messageId)
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
        await vm.performaCalculation()
        await MainActor.run {
            delegate?.sent(indexPath)
        }
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    internal func onDeleteMessage(_ response: ChatResponse<Message>) async {
        guard let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id,
              threadId == responseThreadId,
              let indices = sections.findIncicesBy(uniqueId: response.uniqueId, response.result?.id)
        else { return }
        sections[indices.section].vms.remove(at: indices.row)
        if sections[indices.section].vms.count == 0 {
            sections.remove(at: indices.section)
        }
        delegate?.removed(at: indices)
        await setIsEmptyThread()
    }
}

// MARK: Append/Sort/Delete
extension ThreadHistoryViewModel {

    private func appendSort(_ viewModels: [MessageRowViewModel]) {
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

    fileprivate func updateMessage(_ message: MessageType, _ indexPath: IndexPath?) -> MessageRowViewModel? {
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

    public func injectMessagesAndSort(_ requests: [any HistoryMessageProtocol]) async {
        let viewModels = await makeCalculateViewModelsFor(requests)
        appendSort(viewModels)
        for vm in viewModels {
            await vm.register()
        }
    }

    private func insertIntoSection(_ message: MessageType) -> MessageRowViewModel? {
        if message.threadId == threadId || message.conversation?.id == threadId, let viewModel = viewModel {
            let viewModel = MessageRowViewModel(message: message, viewModel: viewModel)
            if let sectionIndex = sections.sectionIndexByDate(message.time?.date ?? Date()) {
                sections[sectionIndex].vms.append(viewModel)
                return viewModel
            } else {
                sections.append(.init(date: message.time?.date ?? Date(), vms: [viewModel]))
                return viewModel
            }
        }
        return nil
    }

    private func insertOrUpdate(_ message: MessageType) -> MessageRowViewModel? {
        guard let uniqueId = message.uniqueId else { return nil }
        let indices = sections.findIncicesBy(uniqueId: uniqueId, message.id ?? -1)
        if let vm = updateMessage(message, indices) {
            return vm
        }
        return insertIntoSection(message)
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

    public func deleteMessages(_ messages: [MessageType], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        viewModel?.selectedMessagesViewModel.clearSelection()
    }

    private func appenedUnreadMessagesBannerIfNeeed() async {
        guard
            let tuples = sections.message(for: thread.lastSeenMessageId),
            let viewModel = viewModel
        else { return }
        let time = (tuples.message.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time, uniqueId: "\(LocalId.unreadMessageBanner.rawValue)")
        let indexPath = tuples.indexPath
        let vm = MessageRowViewModel(message: unreadMessage, viewModel: viewModel)
        await vm.performaCalculation()
        sections[indexPath.section].vms.append(vm)
        let bannerIndexPath = IndexPath(row: sections[indexPath.section].vms.indices.last!, section: indexPath.section)
        delegate?.inserted(at: bannerIndexPath)
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            delegate?.scrollTo(index: indexPath, position: .middle, animate: true)
        }
    }
}

// MARK: Appear/Disappear/Display/End Display
extension ThreadHistoryViewModel {
    @HistoryActor
    public func willDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        visibleTracker.append(message: message)
        log("Message appear id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        if message.id == thread.lastMessageVO?.id {
            await setIsAtBottom(newValue: true)
        }
        await seenVM?.onAppear(message)
    }

    @HistoryActor
    public func didEndDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        log("Message disappeared id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        visibleTracker.remove(message: message)
        if message.id == thread.lastMessageVO?.id {
            await setIsAtBottom(newValue: false)
        }
    }

    @MainActor
    private func setIsAtBottom(newValue: Bool) {
        if viewModel?.scrollVM.isAtBottomOfTheList != newValue {
            viewModel?.scrollVM.isAtBottomOfTheList = newValue
            viewModel?.delegate?.lastMessageAppeared(newValue)
        }
    }

    public func didScrollTo(_ contentOffset: CGPoint, _ contentSize: CGSize) {
        Task { @HistoryActor in
            if isInProcessingScroll() {
                viewModel?.scrollVM.lastContentOffsetY = contentOffset.y
                if contentOffset.y < 0 {
                    await doScrollAction(contentOffset, contentSize)
                }
                return
            }
            await doScrollAction(contentOffset, contentSize)
            viewModel?.scrollVM.lastContentOffsetY = contentOffset.y
        }
    }

    @HistoryActor
    private func doScrollAction(_ contentOffset: CGPoint , _ contentSize: CGSize) async {
        guard let scrollVM = viewModel?.scrollVM else { return }
        if contentOffset.y > scrollVM.lastContentOffsetY {
            // scroll down
            scrollVM.scrollingUP = false
            if contentOffset.y > contentSize.height - threshold, let message = sections.last?.vms.last?.message {
                await loadMoreBottom(message: message)
            }
        } else {
            // scroll up
            scrollVM.scrollingUP = true
            if contentOffset.y < threshold, let message = sections.first?.vms.first?.message {
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

// MARK: Observers
extension ThreadHistoryViewModel {
    private func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                Task { [weak self] in
                    await self?.onConnectionStatusChanged(status)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { @HistoryActor [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    Task { @HistoryActor [weak self] in
                        self?.onCancelTimer(key: key)
                    }
                }
            }
            .store(in: &cancelable)
        NotificationCenter.windowMode.publisher(for: .windowMode)
            .sink { [weak self] newValue in
                self?.updateAllRows()
            }
            .store(in: &cancelable)
        NotificationCenter.upload.publisher(for: .upload)
            .sink { [weak self] notification in
                self?.onUploadEvents(notification)
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
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}

// MARK: Reactions
extension ThreadHistoryViewModel {
    @HistoryActor
    private func fetchReactions(messages: [MessageType]) async {
        if viewModel?.searchedMessagesViewModel.isInSearchMode == false {
            viewModel?.reactionViewModel.fetchReactions(messages: messages.compactMap({$0 as? Message}))
        }
    }
}

// MARK: Scenarios utilities
extension ThreadHistoryViewModel {
    private func setHasMoreTop(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            showTopLoading(false)
        }
    }

    private func setHasMoreBottom(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextBottom = response.hasNext
            isFetchedServerFirstResponse = true
            showBottomLoading(false)
        }
    }

    private func removeOldBanner() {
        if let indices = sections.indicesByMessageUniqueId("\(LocalId.unreadMessageBanner.rawValue)") {
            sections[indices.section].vms.remove(at: indices.row)
        }
    }

    private func canLoadMoreTop() -> Bool {
        return hasNextTop && !topLoading && viewModel?.scrollVM.isProgramaticallyScroll == false
    }

    private func canLoadMoreBottom() -> Bool {
        return hasNextBottom && !bottomLoading && viewModel?.scrollVM.isProgramaticallyScroll == false
    }

    public func setIsEmptyThread() async {
        let noMessage = isFetchedServerFirstResponse == true && sections.count == 0
        let emptyThread = viewModel?.isSimulatedThared == true
        isEmptyThread = emptyThread || noMessage
        delegate?.emptyStateChanged(isEmpty: isEmptyThread)
        if isEmptyThread {
            showCenterLoading(false)
        }
    }

    internal func setCreated(_ created: Bool) {
        self.created = created
    }

    public func setThreashold(_ threshold: CGFloat) {
        Task { @HistoryActor in
            self.threshold = threshold
        }
    }
}

// MARK: Seen messages
extension ThreadHistoryViewModel {
    /// When you have sent messages for example 5 messages and your partner didn't read messages and send a message directly it will send you only one seen.
    /// So you have to set seen to true for older unread messages you have sent, because the partner has read all messages and after you back to the list of thread the server will respond with seen == true for those messages.
    private func setSeenForAllOlderMessages(newMessage: MessageType) {
        let unseenMessages = sections.last?.vms.filter({($0.message.seen == false || $0.message.seen == nil) && $0.message.isMe(currentUserId: AppState.shared.user?.id)})
        let isNotMe = !newMessage.isMe(currentUserId: AppState.shared.user?.id)
        if isNotMe, unseenMessages?.count ?? 0 > 0 {
            unseenMessages?.forEach { vm in
                Task {
                    if let indexPath = sections.indexPath(for: vm) {
                        vm.message.delivered = true
                        vm.message.seen = true
                        await vm.performaCalculation()
                        await MainActor.run {
                            delegate?.seen(indexPath)
                        }
                    }
                }
            }
        }
    }

    private func setSeenForOlderMessages(messageId: Int?) {
        if let messageId = messageId {
            let isMeId = ChatManager.activeInstance?.userInfo?.id ?? 0
            sections
                .flatMap { $0.vms }
                .filter {
                    let message = $0.message
                    let notDelivered = message.delivered ?? false == false
                    let notSeen = message.seen ?? false == false
                    let isValidToChange = (message.id ?? 0 < messageId) && (notSeen || notDelivered) && message.ownerId == isMeId
                    return isValidToChange
                }
                .forEach { vm in
                    Task {
                        if let indexPath = sections.indexPath(for: vm) {
                            vm.message.delivered = true
                            vm.message.seen = true
                            await vm.performaCalculation()
                            await MainActor.run {
                                delegate?.seen(indexPath)
                            }
                        }
                    }
                }
        }
    }
}

// MARK: On Notifications actions
extension ThreadHistoryViewModel {
    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if canGetNewMessagesAfterConnectionEstablished(status) {
            // After connecting again get latest messages.
            tryFifthScenario(status: status)
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if !isSimulated, status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            await startFetchingHistory()
        }
    }

    private func updateAllRows() {
        sections.forEach { section in
            section.vms.forEach { vm in
                Task {
                    await vm.recalculateWithAnimation()
                }
            }
        }
    }
}

// MARK: Avatars
extension ThreadHistoryViewModel {
    func prepareAvatars(_ viewModels: [MessageRowViewModel]) {
        Task { [weak self] in
            guard let self = self else { return }
            // A delay to scroll to position and layout all rows properply
            try? await Task.sleep(for: .seconds(0.2))
            let filtered = viewModels.filter({$0.calMessage.isLastMessageOfTheUser})
            for vm in filtered {
                viewModel?.avatarManager.addToQueue(vm)
            }
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
    @MainActor
    func getSections() async -> ContiguousArray<MessageSection> {
        return sections
    }
}

extension ThreadHistoryViewModel {

    @DeceleratingActor
    func waitingToFinishDecelerating() async {
        var isEnded = false
        while(!isEnded) {
            if viewModel?.scrollVM.isEndedDecelerating == true {
                isEnded = true
                print("Deceleration has been completed.")
            } else if viewModel == nil {
                isEnded = true
                print("ViewModel has been deallocated, thus, the deceleration will end.")
            } else {
                print("Waiting for the deceleration to be completed.")
                try? await Task.sleep(for: .nanoseconds(500000))
            }
        }
    }

    func waitingToFinishUpdating() async {
        while await isUpdating{}
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
        viewModel?.thread.lastMessageVO?.id ?? 0 == viewModel?.thread.lastSeenMessageId ?? 0
    }

    private func isLastMessageExistInSortedMessages(_ sortedMessages: [any HistoryMessageProtocol]) -> Bool {
        sortedMessages.contains(where: {$0.id == viewModel?.thread.lastMessageVO?.id})
    }

    private func hasUnreadMessage() -> Bool {
        thread.lastMessageVO?.id ?? 0 > thread.lastSeenMessageId ?? 0
    }

    private func canMoveToMessageLocally(_ messageId: Int) -> String? {
        sections.message(for: messageId)?.message.uniqueId
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
}
