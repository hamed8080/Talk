//
//  AssistantHistoryViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import TalkModels

@MainActor
public final class AssistantHistoryViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    public private(set) var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext }
    @Published public private(set) var histories: [AssistantAction] = []
    @Published public var isLoading = false
    private var cancelable: Set<AnyCancellable> = []

    public init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getHistory()
            }
        }
        .store(in: &canceableSet)
        NotificationCenter.assistant.publisher(for: .assistant)
            .compactMap { $0.object as? AssistantEventTypes }
            .sink { [weak self] event   in
                self?.onAssistantEvent(event)
            }
            .store(in: &cancelable)
        getHistory()
    }

    public func onAssistantEvent(_ event: AssistantEventTypes) {
        switch event {
        case .actions(let response):
            onActions(response)
        default:
            break
        }
    }

    public func onActions(_ response: ChatResponse<[AssistantAction]>) {
        if let actions = response.result {
            appendActions(actions)
            hasNext = response.hasNext
        }

        if !response.cache, response.pop() != nil {
            firstSuccessResponse = true
            isLoading = false
        }
    }

    public func getHistory() {
        if isLoading { return }
        isLoading = true
        let req = AssistantsHistoryRequest(count: count, offset: offset, fromTime: UInt(Date().advanced(by: 15 * 24 * 3600).timeIntervalSince1970))
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.assistant.history(req)
        }
    }

    public func loadMore() {
        if !isLoading { return }
        offset += count
        getHistory()
    }

    public func appendActions(_ actions: [AssistantAction]) {
        actions.forEach { action in
            if !self.histories.contains(where: { $0 == action }) {
                self.histories.append(action)
            }
        }
    }
}
