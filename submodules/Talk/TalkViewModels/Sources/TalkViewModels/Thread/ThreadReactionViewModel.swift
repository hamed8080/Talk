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
    public var allowedReactions: [Sticker]?
    private let objectId = UUID().uuidString
    private var lock = false
    
    public init() {
    }

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
    ///
    /// If the user double click on a reaction it will lead to call
    /// this method twice(once in footer reaction row and another in double tap setting menu) as fast as possible,
    /// and it will lead to a server error, by locking the user for 0.2 we make sure that
    /// the user is not able to click more than once and if so nothing will happen and the reaction will be removed.
    public func reaction(_ sticker: Sticker, messageId: Int, myReactionId: Int?, myReactionSticker: Sticker?) {
        if lock { return }
        lock = true
        
        let isDisabled = threadVM?.thread.reactionStatus == .disable
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.lock = false
        }
        let threadId = threadId
        let isLimitedByAdmin = allowedReactions != nil
        let isInAllowedRange = allowedReactions?.contains(where: {$0.emoji == sticker.emoji}) == true
        let canSendReaction = (isLimitedByAdmin && isInAllowedRange) || !isLimitedByAdmin || thread?.group == false
        Task { @ChatGlobalActor in
            if myReactionSticker == sticker, let reactionId = myReactionId {
                let req = DeleteReactionRequest(reactionId: reactionId, conversationId: threadId)
                ChatManager.activeInstance?.reaction.delete(req)
            } else if canSendReaction && !isDisabled {
                if let reactionId = myReactionId {
                    let req = ReplaceReactionRequest(messageId: messageId, conversationId: threadId, reactionId: reactionId, reaction: sticker)
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
    }

    public func getDetail(for messageId: Int, offset: Int = 0, count: Int, sticker: Sticker? = nil) {
        let threadId = threadId
        Task { @ChatGlobalActor in
            let req = ReactionListRequest(
                messageId: messageId,
                offset: offset,
                count: count,
                conversationId: threadId,
                sticker: sticker
            )
            await AppState.shared.objectsContainer.chatRequestQueue.enqueue(.reactionListRequest(req: req))
        }
    }

    func onReactionEvent(_ event: ReactionEventTypes) async {
        switch event {
        case .add(let chatResponse):
            onAddedReaction(chatResponse)
        case .replace(let chatResponse):
            onReplaceReaction(chatResponse)
        case .delete(let chatResponse):
            onDeleteReaction(chatResponse)
        case .allowedReactions(let chatResponse):
            onAllowedReactions(chatResponse)
        default:
            break
        }
    }

    func scrollToLastMessageIfLastMessageReacionChanged(_ response: ChatResponse<ReactionMessageResponse>) {
        if response.subjectId == threadId, response.result?.messageId == threadVM?.lastMessageVO()?.id {
            threadVM?.scrollVM.scrollToLastMessageOnlyIfIsAtBottom()
        }
    }

    private func onDeleteReaction(_ response: ChatResponse<ReactionMessageResponse>) {
        guard
            let reaction = response.result?.reaction,
            let messageId = response.result?.messageId
        else { return }
        /// Find MessageRowViewModel
        guard let tuple = vmAndIndex(for: messageId) else { return }
        
        /// Recalculate the reaction
        tuple.vm.reactionDeleted(reaction)
        
        /// Reload
        threadVM?.delegate?.reactionDeleted(indexPath: tuple.indexPath, reaction: reaction)
        
        /// Scroll to bottom if last message deleted
        scrollToLastMessageIfLastMessageReacionChanged(response)
    }
    
    private func onAddedReaction(_ response: ChatResponse<ReactionMessageResponse>) {
        guard
            let reaction = response.result?.reaction,
            let messageId = response.result?.messageId
        else { return }
        /// Find MessageRowViewModel
        guard let tuple = vmAndIndex(for: messageId) else { return }
        
        /// Recalculate the reaction
        tuple.vm.reactionAdded(reaction)
        
        /// Reload
        threadVM?.delegate?.reactionAdded(indexPath: tuple.indexPath, reaction: reaction)
        
        /// Scroll to bottom if last message deleted
        scrollToLastMessageIfLastMessageReacionChanged(response)
    }
    
    private func onReplaceReaction(_ response: ChatResponse<ReactionMessageResponse>) {
        guard
            let reaction = response.result?.reaction,
            let messageId = response.result?.messageId,
            let oldSticker = response.result?.oldSticker
        else { return }
        /// Find MessageRowViewModel
        guard let tuple = vmAndIndex(for: messageId) else { return }
        
        /// Recalculate the reaction
        var oldReaction = Reaction(id: reaction.id, reaction: response.result?.oldSticker, participant: reaction.participant)
        tuple.vm.reactionReplaced(reaction, oldSticker: oldSticker)
        
        /// Reload
        threadVM?.delegate?.reactionReplaced(indexPath: tuple.indexPath, reaction: reaction)
        
        /// Scroll to bottom if last message deleted
        scrollToLastMessageIfLastMessageReacionChanged(response)
    }
    
    private func vmAndIndex(for messageId: Int?) -> (vm: MessageRowViewModel, indexPath: IndexPath)? {
        guard let messageId = messageId else { return nil }
        return threadVM?.historyVM.sections.viewModelAndIndexPath(for: messageId)
    }
    
#if DEBUG
    deinit {
        print("deinit ThreadReactionViewModel")
    }
#endif
}
