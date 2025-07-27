//
//  GetSpecificConversationViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 2/18/25.
//

import Combine
import Foundation
import Chat
import Logger

@MainActor
public final class GetSpecificConversationViewModel {
    private var objectId = UUID().uuidString
    private let GET_NOT_ACTIVE_THREADS_KEY: String
    private var cancelable: AnyCancellable?
    
    public init() {
        GET_NOT_ACTIVE_THREADS_KEY = "GET-NOT-ACTIVE-THREADS-\(objectId)"
    }
    
    public func getNotActiveThreads(_ conversationId: Int) async -> Conversation? {
        let req = ThreadsRequest(threadIds: [conversationId])
        RequestsManager.shared.append(prepend: GET_NOT_ACTIVE_THREADS_KEY, value: req)
        
        return await withCheckedContinuation { continuation in
            log("Get a conversation by id: \(conversationId)")
            sinkWith(continuation)
            // Start request after setting up listener
            Task { @ChatGlobalActor in
                await ChatManager.activeInstance?.conversation.get(req)
            }
        }
    }
    
    private func sinkWith(_ continuation: CheckedContinuation<Conversation?, Never>) {
        cancelable = NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task {
                    if let conversation = self?.handleThreadEvent(event) {
                        self?.log("Calling continuation for get a conversation by id: \(conversation.id ?? -1)")
                        continuation.resume(returning: conversation)
                        self?.cancelable?.cancel() // ✅ Cancel after resuming
                        self?.cancelable = nil
                    }
                }
            }
    }
    
    private func handleThreadEvent(_ event: ThreadEventTypes?) -> Conversation? {
        guard case .threads(let response) = event,
              !response.cache,
              response.pop(prepend: GET_NOT_ACTIVE_THREADS_KEY) != nil
        else { return nil }
        return response.result?.first
    }
    
    func log(_ string: String) {
        Logger.log(title: "GetSpecificConversationViewModel", message: string)
    }
}
