//
//  ReactionDetailCountTabsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import Chat

@MainActor
public class ReactionDetailCountTabsViewModel: ObservableObject {
    @Published public var items: [ReactionCount] = []
    private let messageId: Int
    private let conversationId: Int
    private var cancellable: AnyCancellable?
    private let objectId = UUID().uuidString
    private let REACTION_SUMMARY: String
    
    public init(messageId: Int, conversationId: Int) {
        self.messageId = messageId
        self.conversationId = conversationId
        REACTION_SUMMARY = "REACTION-SUMMARY\(objectId)"
        register()
    }
    
    private func register() {
        cancellable = NotificationCenter.reaction.publisher(for: .reaction)
            .compactMap { $0.object as? ReactionEventTypes }
            .sink { [weak self] event in
                self?.onReactionEvent(event)
            }
    }
    
    private func onReactionEvent(_ event: ReactionEventTypes) {
        switch event {
        case .count(let chatResponse):
            onSummary(chatResponse)
        default:
            break
        }
    }
    
    private func onSummary(_ response: ChatResponse<[ReactionCountList]>) {
        if response.pop(prepend: REACTION_SUMMARY) != nil, let items = response.result?.first?.reactionCounts {
            self.items = items
        }
    }
    
    @ChatGlobalActor
    public func fetchSummary() {
        let req = ReactionCountRequest(messageIds: [messageId], conversationId: conversationId)
        RequestsManager.shared.append(prepend: REACTION_SUMMARY, value: req)
        ChatManager.activeInstance?.reaction.count(req)
    }
}
