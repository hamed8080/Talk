//
//  GetSearchContactsRequester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/16/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class GetSearchContactsRequester {
    private let KEY: String = UUID().uuidString
    private var cancellableSet = Set<AnyCancellable>()
    private var resumed: Bool = false
    
    enum SearchContactsError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init() { }
    
    public func get(_ req: ContactsRequest, withCache: Bool) async throws -> [Contact] {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation, withCache: withCache)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                await ChatManager.activeInstance?.contact.search(req)
            }
        }
    }
    
    private func sink(_ continuation: CheckedContinuation<[Contact], any Error>, withCache: Bool) {
        NotificationCenter.contact.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    guard
                        let self = self,
                        let result = await self.handleEvent(event, withCache: withCache),
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
                continuation.resume(throwing: SearchContactsError.failed(resp))
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: ContactEventTypes, withCache: Bool) async -> [Contact]? {
        guard
            case .contacts(let resp) = event,
            resp.cache == withCache,
            resp.pop(prepend: KEY) != nil,
            let contacts = resp.result
        else { return nil }
        
        return contacts
    }
}
