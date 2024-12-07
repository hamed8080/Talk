//
//  ReactionTabParticipantsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import Chat

public typealias ReactionTabId = String

@MainActor
public class ReactionTabParticipantsViewModel: ObservableObject {

    @Published public var reactions: [ReactionTabId: [Reaction]] = [:]
    private var cancelable: Set<AnyCancellable> = []
    private let messageId: Int
    private var activeTab: ReactionTabId?
    private var sticker: Sticker?
    public weak var viewModel: ThreadReactionViewModel?
    private var offset: Int = 0
    private let count: Int = 15
    private var hasNext = true

    public init(messageId: Int) {
        self.messageId = messageId
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.reaction.publisher(for: .reaction)
            .compactMap({$0.object as? ReactionEventTypes })
            .sink { [weak self] event in
                self?.onReactionEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onReactionEvent(_ event: ReactionEventTypes) {
        switch event {
        case .list(let chatResponse):
            onList(chatResponse)
        default:
            break
        }
    }

    private func onList(_ response: ChatResponse<ReactionList>) {
        guard response.result?.messageId == messageId, let reactions = response.result?.reactions
        else { return }
        let groups = Dictionary(grouping: reactions, by: {$0.reaction})
        hasNext = response.result?.reactions?.count ?? 0 >= count
        if canAppendIntoActiveTab(groups) {
            appendToActiveTab(groups.first?.value ?? [])
        } else {
            appendToAllTab(response.result?.reactions ?? [])
        }
    }

    private func appendToActiveTab(_ reactions: [Reaction]) {
        guard let activeTab = activeTab else { return }
        createArrayIfIsEmpty()
        reactions.forEach { reaction in
            if !isReactionInTab(activeTab, reactionId: reaction.id ?? -1) {
                self.reactions[activeTab]?.append(reaction)
            }
        }
    }

    public func setActiveTab(tabId: ReactionTabId) {
        self.activeTab = tabId
        self.sticker = Sticker(emoji: tabId.first ?? Character(""))
        offset = 0
        hasNext = true
        getActiveTabParticipants()
    }

    private func getActiveTabParticipants() {
        viewModel?.getDetail(for: messageId, offset: offset, count: count, sticker: sticker)
    }

    public func loadMoreParticipants() {
        if !hasNext { return }
        offset = offset + count
        viewModel?.getDetail(for: messageId, offset: offset, count: count, sticker: sticker)
    }

    public func participants(for tabId: ReactionTabId) -> [Reaction] {
        reactions[tabId] ?? []
    }

    private func canAppendIntoActiveTab(_ groups: [Sticker? : [Reaction]]) -> Bool {
        groups.count == 1 && sticker == groups.first?.key
    }

    private func isReactionInTab(_ tabId: ReactionTabId, reactionId: Int) -> Bool {
        self.reactions[tabId]?.contains(where: {$0.id == reactionId}) == true
    }

    private func createArrayIfIsEmpty() {
        guard let activeTab = activeTab else { return }
        if self.reactions[activeTab] == nil {
            self.reactions[activeTab] = []
        }
    }

    public func appendToAllTab(_ reactions: [Reaction]) {
        guard let activeTab = activeTab else { return }
        createArrayIfIsEmpty()
        reactions.forEach { reaction in
            if !isReactionInTab(activeTab, reactionId: reaction.id ?? -1) {
                self.reactions[activeTab]?.append(reaction)
            }
        }
    }
}
