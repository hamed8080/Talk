//
//  GetMessageReactionsReuqester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 6/9/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class GetMessageReactionsReuqester {
    private let KEY: String
    private var cancellableSet = Set<AnyCancellable>()
    private var threadId = 0
    private var resumed: Bool = false

    enum ReactionError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() {
        self.KEY = "MESSAGE-REACTION"
    }
    
    public func get(_ req: ReactionCountRequest, queueable: Bool = false) async throws -> [ReactionRowsCalculated] {
        let key = KEY
        self.threadId = req.conversationId
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                if queueable {
                    await AppState.shared.objectsContainer.chatRequestQueue.enqueue(.reactionCount(req: req))
                } else {
                    await ChatManager.activeInstance?.reaction.count(req)
                }
            }
        }
    }
    
    private func sink(_ continuation: CheckedContinuation<[ReactionRowsCalculated], any Error>) {
        NotificationCenter.reaction.publisher(for: .reaction)
            .compactMap { $0.object as? ReactionEventTypes }
            .sink { [weak self] event in
                Task { @MainActor [weak self] in
                    guard
                        let self = self,
                        let result = await self.handleEvent(event),
                        !self.resumed
                    else { return }
                    continuation.resume(with: .success(result))
                    self.resumed = true
                    self.cancellableSet.removeAll()
                }
            }
            .store(in: &cancellableSet)
        
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<Sendable> }
            .sink { [weak self] resp in
                guard
                    let self = self,
                    resp.pop(prepend: self.KEY) != nil,
                    !self.resumed
                else { return }
                continuation.resume(throwing: ReactionError.failed(resp))
                self.cancellableSet.removeAll()
                self.resumed = true
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: ReactionEventTypes) async -> [ReactionRowsCalculated]? {
        if case .count(let resp) = event, resp.subjectId == threadId, resp.pop(prepend: KEY) != nil {
            let myId = AppState.shared.user?.id ?? -1
            return await calculateReactions(resp.result ?? [], myId: myId)
        }
        return nil
    }
    
    @AppBackgroundActor
    private func calculateReactions(_ msgsReactions: [ReactionCountList], myId: Int) async -> [ReactionRowsCalculated] {
        var cals: [ReactionRowsCalculated] = []
        for msgReaction in msgsReactions {
            let msgId = msgReaction.messageId ?? 0
            cals.append(MessageReactionCalculator(message: Message(id: msgId), myId: myId).calulateReactions(msgReaction))
        }
        return cals
    }
}
