//
//  GetPartitipantsRequester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/16/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class GetPartitipantsRequester {
    private let KEY: String = UUID().uuidString
    private var cancellableSet = Set<AnyCancellable>()
    private var resumed: Bool = false
    
    enum ParticipantsError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() { }
    
    public func get(_ req: ThreadParticipantRequest) async throws -> [Participant] {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                await ChatManager.activeInstance?.conversation.participant.get(req)
            }
        }
    }
    
    private func sink(_ continuation: CheckedContinuation<[Participant], any Error>) {
        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
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
                continuation.resume(throwing: ParticipantsError.failed(resp))
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: ParticipantEventTypes) async -> [Participant]? {
        guard
            case .participants(let resp) = event,
            resp.cache == false,
            resp.pop(prepend: KEY) != nil,
            let participants = resp.result
        else { return nil }
        
        return participants
    }
}
