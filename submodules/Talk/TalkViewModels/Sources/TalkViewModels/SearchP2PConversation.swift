//
//  SearchP2PConversation.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class SearchP2PConversation {
    private let id: String = "SEARCH-P2P-\(UUID().uuidString)"
    private var cancelable: Set<AnyCancellable> = []
    public typealias CompletionHandler = (Conversation?) -> Void
    private var completion: CompletionHandler?

    public init(){
        registerNotifications()
    }

    public func searchForP2PThread(coreUserId: Int?, userName: String? = nil, completion: CompletionHandler? = nil) {
        self.completion = completion
        let req = ThreadsRequest(type: .normal, partnerCoreUserId: coreUserId, userName: userName)
        RequestsManager.shared.append(prepend: id, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
    }

    private func onSearchP2PThreads(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, response.pop(prepend: id) != nil {
            completion?(response.result?.first)
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
            onSearchP2PThreads(response)
        }
    }
}
