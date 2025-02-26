//
//  P2PConversationBuilder.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class P2PConversationBuilder {
    private let id: String = "CREATE-P2P-\(UUID().uuidString)"
    private var cancelable: Set<AnyCancellable> = []
    public typealias CompletionHandler = (Conversation) -> Void
    private var completion: CompletionHandler?

    public init(){
        registerNotifications()
    }

    public func create(invitee: Invitee, completion: CompletionHandler? = nil) {
        self.completion = completion
        let req = CreateThreadRequest(invitees: [invitee], title: "", type: StrictThreadTypeCreation.p2p.threadType)
        RequestsManager.shared.append(prepend: id, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.create(req)
        }
    }

    public func create(coreUserId: Int, completion: CompletionHandler? = nil) {
        let invitee = Invitee(id: "\(coreUserId)", idType: .coreUserId)
        create(invitee: invitee, completion: completion)
    }

    public func create(userId: Int, completion: CompletionHandler? = nil) {
        let invitee = Invitee(id: "\(userId)", idType: .userId)
        create(invitee: invitee, completion: completion)
    }

    private func onCreateP2PThread(_ response: ChatResponse<Conversation>) {
        guard response.pop(prepend: id) != nil, let thread = response.result else { return }
        completion?(thread)
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
        if case .created(let response) = event {
            onCreateP2PThread(response)
        }
    }
}
