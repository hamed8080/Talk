//
//  GetCallsToJoinRequester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/16/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class GetCallsToJoinRequester {
    private let KEY: String = UUID().uuidString
    private var cancellableSet = Set<AnyCancellable>()
    private var resumed: Bool = false
    
    enum CallsToJoinError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() { }
    
    public func get(_ req: GetJoinCallsRequest, withCache: Bool, queueable: Bool = false) async throws -> [Call] {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation, withCache: withCache)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                if queueable {
                    await AppState.shared.objectsContainer.chatRequestQueue.enqueue(.callsToJoin(req: req))
                } else {
                    await ChatManager.activeInstance?.call.callsToJoin(req)
                }
            }
        }
    }
    
    private func sink(_ continuation: CheckedContinuation<[Call], any Error>, withCache: Bool) {
        NotificationCenter.call.publisher(for: .call)
            .compactMap { $0.object as? CallEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    guard
                        let self = self,
                        let result = await self.handleEvent(event, withCache: withCache),
                        !self.resumed
                    else { return }
                    
                    continuation.resume(with: .success(result))
                    self.resumed = true
                }
            }
            .store(in: &cancellableSet)
        
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<Sendable> }
            .sink { [weak self] resp in
                guard let self = self, !self.resumed else { return }
                if resp.pop(prepend: self.KEY) != nil {
                    self.resumed = true
                    continuation.resume(throwing: CallsToJoinError.failed(resp))
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: CallEventTypes, withCache: Bool) async -> [Call]? {
        guard
            case .callsToJoin(let resp) = event,
            resp.cache == withCache,
            resp.pop(prepend: KEY) != nil,
            let calls = resp.result
        else { return nil }
        
        return calls
    }
}
