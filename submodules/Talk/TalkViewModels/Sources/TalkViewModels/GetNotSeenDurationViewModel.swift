//
//  GetNotSeenDurationViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 6/9/25.
//

import Combine
import Chat
import Foundation

@MainActor
public final class GetNotSeenDurationViewModel {
    private let userId: Int
    private let KEY: String = "NOT_SEEN_KEY-\(UUID().uuidString)"
    private var cancelable: AnyCancellable?
    
    public init(userId: Int) {
        self.userId = userId
    }
    
    public func get() async -> UserLastSeenDuration? {
        let req = NotSeenDurationRequest(userIds: [userId])
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else { return }
            sinkWith(continuation)
            // Start request after setting up listener
            Task { @ChatGlobalActor in
                RequestsManager.shared.append(prepend: KEY, value: req)
                await ChatManager.activeInstance?.contact.notSeen(req)
            }
        }
    }
    
    private func sinkWith(_ continuation: CheckedContinuation<UserLastSeenDuration?, Never>) {
        cancelable = NotificationCenter.contact.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] event in
                Task {
                    if let lastSeen = self?.handleEvent(event) {
                        continuation.resume(returning: lastSeen)
                        self?.cancelable?.cancel() // ✅ Cancel after resuming
                        self?.cancelable = nil
                    }
                }
            }
    }
    
    private func handleEvent(_ event: ContactEventTypes?) -> UserLastSeenDuration? {
        guard case .notSeen(let response) = event,
              !response.cache,
              response.pop(prepend: KEY) != nil
        else { return nil }
        return response.result?.first?.notSeenDuration.first
    }
}
