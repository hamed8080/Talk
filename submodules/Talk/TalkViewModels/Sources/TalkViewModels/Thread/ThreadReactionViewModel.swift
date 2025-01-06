//
//  ThreadReactionViewModel.swift
//  Talk
//
//  Created by hamed on 10/22/22.
//

import Chat
import Foundation
import Combine

@MainActor
public final class ThreadReactionViewModel {
    private var cancelable: Set<AnyCancellable> = []
    weak var threadVM: ThreadViewModel?
    private var thread: Conversation? { threadVM?.thread }
    private var threadId: Int { thread?.id ?? -1 }
    private var hasEverDisonnected = false
    private var inQueueToGetReactions: [Int] = []
    public var allowedReactions: [Sticker] = []
    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.threadVM = viewModel
        registerObservers()
        getAllowedReactions()
    }

    private func registerObservers() {
        NotificationCenter.reaction.publisher(for: .reaction)
            .compactMap { $0.object as? ReactionEventTypes }
            .sink { [weak self] reactionEvent in
                Task { [weak self] in
                    await self?.onReactionEvent(reactionEvent)
                }
            }
            .store(in: &cancelable)
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                if status == .disconnected {
                    self?.hasEverDisonnected = true
                }
                if status == .connected && self?.hasEverDisonnected == true {
                    self?.onReconnected()
                }
            }
            .store(in: &cancelable)
    }

    public func getAllowedReactions() {
        let thread = threadVM?.thread
        let isClosed = thread?.closed == true
        if thread?.reactionStatus == .custom, !isClosed {
            let req = ConversationAllowedReactionsRequest(conversationId: threadId)
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.reaction.allowedReactions(req)
            }
        }
    }

    private func onAllowedReactions(_ response: ChatResponse<AllowedReactionsResponse>) {
        if response.result?.conversationId == threadId, let allowedReactions = response.result?.allowedReactions {
            self.allowedReactions = allowedReactions
        }
    }

    /// Add/Remove/Replace
    public func reaction(_ sticker: Sticker, messageId: Int) {
        let threadId = threadId
        Task { @ChatGlobalActor in
            let myReaction = ChatManager.activeInstance?.reaction.inMemoryReaction.currentReaction(messageId)
            if myReaction?.reaction == sticker, let reactionId = myReaction?.id {
                let req = DeleteReactionRequest(reactionId: reactionId, conversationId: threadId)
                ChatManager.activeInstance?.reaction.delete(req)
            } else if let reacrionId = myReaction?.id {
                let req = ReplaceReactionRequest(messageId: messageId, conversationId: threadId, reactionId: reacrionId, reaction: sticker)
                ChatManager.activeInstance?.reaction.replace(req)
            } else {
                let req = AddReactionRequest(messageId: messageId,
                                             conversationId: threadId,
                                             reaction: sticker
                )
                ChatManager.activeInstance?.reaction.add(req)
            }
        }
    }

    public func getReactionSummary(_ messageIds: [Int], conversationId: Int) {
        let threadId = threadId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.reaction.count(.init(messageIds: messageIds, conversationId: threadId))
        }
    }

    public func getCurrentUserReaction(for messageId: Int) {
        let threadId = threadId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.reaction.reaction(.init(messageId: messageId, conversationId: threadId))
        }
    }

    public func getDetail(for messageId: Int, offset: Int = 0, count: Int, sticker: Sticker? = nil) {
        let threadId = threadId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.reaction.get(.init(messageId: messageId,
                                    offset: offset,
                                    count: count,
                                    conversationId: threadId,
                                    sticker: sticker)
            )
        }
    }

    @MainActor
    func onReactionEvent(_ event: ReactionEventTypes) async {
        switch event {
        case .inMemoryUpdate(let copies):
            await updateReactions(reactions: copies)
        case .add(let chatResponse):
            scrollToLastMessageIfLastMessageReacionChanged(chatResponse)
        case .replace(let chatResponse):
            scrollToLastMessageIfLastMessageReacionChanged(chatResponse)
        case .delete(let chatResponse):
            scrollToLastMessageIfLastMessageReacionChanged(chatResponse)
        case .allowedReactions(let chatResponse):
            onAllowedReactions(chatResponse)
        default:
            break
        }
    }

    func scrollToLastMessageIfLastMessageReacionChanged(_ response: ChatResponse<ReactionMessageResponse>) {
        if response.subjectId == threadId, response.result?.messageId == thread?.lastMessageVO?.id {
            Task {
                await threadVM?.scrollVM.scrollToLastMessageOnlyIfIsAtBottom()
            }
        }
    }

    func onReconnected() {
        // clear all reactions
        clearReactionsOnReconnect()
    }

    internal func fetchReactions(messages: [Message]) {
        guard threadVM?.searchedMessagesViewModel.isInSearchMode == false else { return}
        let messageIds = messages
            .filter({$0.id ?? -1 > 0})
            .filter({$0.reactionableType})
            .compactMap({$0.id})
        inQueueToGetReactions.append(contentsOf: messageIds)
        threadVM?.reactionViewModel.getReactionSummary(messageIds, conversationId: threadId)
    }

    internal func updateReactions(reactions: [ReactionInMemoryCopy]) async {
        // We have to check if the response count is greater than zero because there is a chance to get reactions of zero count.
        // And we need to remove older reactions if any of them were removed.
        guard let historyVM = threadVM?.historyVM, reactions.count > 0 else { return }
        for copy in reactions {
            inQueueToGetReactions.removeAll(where: {$0 == copy.messageId})
            if let vm = historyVM.mSections.messageViewModel(for: copy.messageId) {
                await vm.setReaction(reactions: copy)
            }
        }

        /// All things inisde the qeueu are old data and there will be a chance the reaction row has been removed.
        for id in inQueueToGetReactions {
            if let vm = historyVM.mSections.messageViewModel(for: id) {
                await vm.clearReactions()
            }
        }
        inQueueToGetReactions.removeAll()
        let wasAtBottom = threadVM?.scrollVM.isAtBottomOfTheList == true

        // Update UI of each message
        let indexPaths: [IndexPath] = reactions.compactMap({ historyVM.mSections.viewModelAndIndexPath(for: $0.messageId)?.indexPath })
        if !indexPaths.isEmpty {
           threadVM?.delegate?.performBatchUpdateForReactions(indexPaths)
        }
    }

    internal func clearReactionsOnReconnect() {
        Task { [weak self] in
            await self?.threadVM?.historyVM.getSections().forEach { section in
                section.vms.forEach { vm in
                    vm.invalid()
                }
            }
            await self?.fetchVisibleReactionsOnReconnect()
        }
    }

    internal func fetchVisibleReactionsOnReconnect() async {
        let visibleMessages = await (threadVM?.historyVM.getInvalidVisibleMessages() ?? []).compactMap({$0 as? Message})
        await fetchReactions(messages: visibleMessages)
    }

    deinit {
        print("deinit ThreadReactionViewModel")
    }
}
