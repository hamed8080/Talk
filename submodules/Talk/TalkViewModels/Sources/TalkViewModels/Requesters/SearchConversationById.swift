//
//  SearchConversationById.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class SearchConversationById {
    private let id: String = "SEARCH-CONVERSATION-BY-ID-\(UUID().uuidString)"
    private var cancelable: Set<AnyCancellable> = []
    public typealias CompletionHandler = ([Conversation]?) -> Void
    private var completion: CompletionHandler?

    public init(){
        registerNotifications()
    }

    public func search(ids: [Int], completion: CompletionHandler? = nil) {
        self.completion = completion
        let req = ThreadsRequest(threadIds: ids)
        RequestsManager.shared.append(prepend: id, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
    }

    public func search(id: Int, completion: CompletionHandler? = nil) {
        search(ids: [id], completion: completion)
    }

    private func onSearcThreads(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, response.pop(prepend: id) != nil {
            completion?(response.result)
        }
    }

    private func registerNotifications() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onThreadEvent(_ event: ThreadEventTypes?) {
        if case .threads(let response) = event {
            onSearcThreads(response)
        }
    }
}
