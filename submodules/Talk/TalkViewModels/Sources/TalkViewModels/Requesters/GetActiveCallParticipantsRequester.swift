//
//  GetActiveCallParticipantsRequester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/16/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class GetActiveCallParticipantsRequester {
    private let KEY: String = UUID().uuidString
    private var cancellableSet = Set<AnyCancellable>()
    private var resumed: Bool = false
    
    enum ActiveCallParticipantsError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() { }
    
    public func get(_ callId: Int) async throws -> [CallParticipant] {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation)
            Task { @ChatGlobalActor [weak self] in
                let req = GeneralSubjectIdRequest(subjectId: callId)
                RequestsManager.shared.append(prepend: key, value: req)
                await ChatManager.activeInstance?.call.activeCallParticipants(req)
            }
        }
    }
    
    private func sink(_ continuation: CheckedContinuation<[CallParticipant], any Error>) {
        NotificationCenter.call.publisher(for: .call)
            .compactMap { $0.object as? CallEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    guard
                        let self = self,
                        let result = await self.handleEvent(event),
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
                continuation.resume(throwing: ActiveCallParticipantsError.failed(resp))
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: CallEventTypes) async -> [CallParticipant]? {
        guard
            case .activeCallParticipants(let resp) = event,
            resp.cache == false,
            resp.pop(prepend: KEY) != nil,
            let callParticipants = resp.result
        else { return nil }
        
        return callParticipants
    }
}
