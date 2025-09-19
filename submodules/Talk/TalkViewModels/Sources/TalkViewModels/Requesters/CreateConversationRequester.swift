//
//  CreateConversationRequester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/16/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class CreateConversationRequester {
    private let KEY: String = UUID().uuidString
    private var cancellableSet = Set<AnyCancellable>()
    private var resumed: Bool = false
    
    enum CreateConversatioError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() { }
    
    public func create(_ req: CreateThreadRequest) async throws -> Conversation {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                await ChatManager.activeInstance?.conversation.create(req)
            }
        }
    }
    
    public func create(coreUserId: Int) async throws -> Conversation {
        let invitee = Invitee(id: "\(coreUserId)", idType: .coreUserId)
        let req = CreateThreadRequest(invitees: [invitee], title: "", type: StrictThreadTypeCreation.p2p.threadType)
        return try await create(req)
    }
    
    private func sink(_ continuation: CheckedContinuation<Conversation, any Error>) {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    guard
                        let self = self,
                        let result = await self.handleEvent(event),
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
                    continuation.resume(throwing: CreateConversatioError.failed(resp))
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: ThreadEventTypes) async -> Conversation? {
        guard
            case .created(let resp) = event,
            resp.cache == false,
            resp.pop(prepend: KEY) != nil,
            let conversation = resp.result
        else { return nil }
        
        return conversation
    }
}
