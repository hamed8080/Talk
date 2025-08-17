//
//  GetThreadsRequester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/16/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class GetThreadsReuqester {
    private let KEY: String = UUID().uuidString
    private var cancellableSet = Set<AnyCancellable>()
    private var resumed: Bool = false
    
    enum ThreadsError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() { }
    
    public func get(_ req: ThreadsRequest, withCache: Bool, queueable: Bool = false) async throws -> [Conversation] {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation, withCache: withCache)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                if queueable {
                    await AppState.shared.objectsContainer.chatRequestQueue.enqueue(.getConversations(req: req))
                } else {
                    await ChatManager.activeInstance?.conversation.get(req)
                }
            }
        }
    }
    
    public func getCalculated(_ req: ThreadsRequest, withCache: Bool, queueable: Bool = false, myId: Int, navSelectedId: Int?, keepOrder: Bool = false) async throws -> [CalculatedConversation] {
        let conversations = try await get(req, withCache: withCache, queueable: queueable)
        return await calculate(conversations, myId, navSelectedId, keepOrder)
    }
    
    private func sink(_ continuation: CheckedContinuation<[Conversation], any Error>, withCache: Bool) {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    guard let self = self, !self.resumed else { return }
                    if let result = await self.handleEvent(event, withCache: withCache) {
                        self.resumed = true
                        continuation.resume(with: .success(result))
                    }
                }
            }
            .store(in: &cancellableSet)
        
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<Sendable> }
            .sink { [weak self] resp in
                guard let self = self, !self.resumed else { return }
                if resp.pop(prepend: self.KEY) != nil {
                    self.resumed = true
                    continuation.resume(throwing: ThreadsError.failed(resp))
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: ThreadEventTypes, withCache: Bool) async -> [Conversation]? {
        guard
            case .threads(let resp) = event,
            resp.cache == withCache,
            resp.pop(prepend: KEY) != nil,
            let threads = resp.result
        else { return nil }
        
        return threads
    }
    
    private func calculate(_ conversations: [Conversation], _ myId: Int, _ navSelectedId: Int?, _ keepOrder: Bool) async -> [CalculatedConversation] {
        return await ThreadCalculators.calculate(conversations: conversations,
                                                 myId: myId,
                                                 navSelectedId: navSelectedId,
                                                 nonArchives: true,
                                                 keepOrder: keepOrder)
    }
}
