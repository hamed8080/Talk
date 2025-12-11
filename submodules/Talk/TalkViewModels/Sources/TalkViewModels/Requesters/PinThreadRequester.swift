//
//  PinThreadRequester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/16/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class PinThreadRequester {
    private let KEY: String = UUID().uuidString
    private var cancellableSet = Set<AnyCancellable>()
    private var resumed: Bool = false
    
    enum ThreadsError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() { }
    
    public func unpin(_ req: GeneralSubjectIdRequest) async throws -> Bool {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                await ChatManager.activeInstance?.conversation.unpin(req)
            }
        }
    }
    
    private func sink(_ continuation: CheckedContinuation<Bool, any Error>) {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    guard
                        let self = self,
                        let result = await self.handleUnpinEvent(event),
                        !self.resumed
                    else { return }
                    self.resumed = true
                    continuation.resume(with: .success(result))
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
                self.resumed = true
                continuation.resume(throwing: ThreadsError.failed(resp))
            }
            .store(in: &cancellableSet)
    }
    
    private func handleUnpinEvent(_ event: ThreadEventTypes) async -> Bool? {
        guard
            case .unpin(let resp) = event,
            resp.cache == false,
            resp.pop(prepend: KEY) != nil,
            let threads = resp.result
        else { return false }
        
        return true
    }
}
