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
    
    enum ReactionError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() {
        self.KEY = "MESSAGE-REACTION"
    }
    
    public func get(_ req: ReactionCountRequest, queueable: Bool = false) async throws -> [ReactionRowsCalculated] {
        return try await withCheckedThrowingContinuation { continuation in
            sink(continuation)
            Task { @ChatGlobalActor in
                RequestsManager.shared.append(prepend: KEY, value: req)
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
                Task {
                    if let result = await self?.handleEvent(event) {
                        continuation.resume(with: .success(result))
                    }
                }
            }
            .store(in: &cancellableSet)
        
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<Sendable> }
            .sink { [weak self] resp in
                if let key = self?.KEY, resp.pop(prepend: key) != nil {
                    continuation.resume(throwing: ReactionError.failed(resp))
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: ReactionEventTypes) async -> [ReactionRowsCalculated]? {
        if case .count(let resp) = event, resp.pop(prepend: KEY) != nil {
            return await calculateReactions(resp.result ?? [])
        }
        return nil
    }
    
    @AppBackgroundActor
    private func calculateReactions(_ msgsReactions: [ReactionCountList]) async -> [ReactionRowsCalculated] {
        var cals: [ReactionRowsCalculated] = []
        for msgReaction in msgsReactions {
            cals.append(MessageRowCalculators.calulateReactions(msgReaction, msgReaction.messageId ?? -1))
        }
        return cals
    }
}
