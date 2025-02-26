//
//  AssistantViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import TalkModels

@MainActor
public final class AssistantViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    @Published public private(set) var selectedAssistant: [Assistant] = []
    public private(set) var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext }
    @Published public private(set) var assistants: [Assistant] = []
    @Published public private(set) var blockedAssistants: [Assistant] = []
    @Published public var isLoading = false
    @Published public var showAddAssistantSheet = false
    @Published public var isInSelectionMode = false
    private var cancelable: Set<AnyCancellable> = []

    public init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getAssistants()
            }
        }
        .store(in: &canceableSet)
        NotificationCenter.assistant.publisher(for: .assistant)
            .compactMap { $0.object as? AssistantEventTypes }
            .sink { [weak self] event   in
                self?.onAssistantEvent(event)
            }
            .store(in: &cancelable)
        getAssistants()
    }

    public func onAssistantEvent(_ event: AssistantEventTypes) {
        switch event {
        case .assistants(let chatResponse):
            onAssistants(chatResponse)
        case .register(let response):
            onRegisterAssistant(response)
        case .deactive(let response):
            onDeactiveAssistant(response)
        case .block(let response):
            onBlockAssistant(response)
        case .unblock(let response):
            onUnBlockAssistant(response)
        case .blockedList(let response):
            onBlockedListAssistant(response)
        default:
            break
        }
    }

    public func onAssistants(_ response: ChatResponse<[Assistant]>) {
        if let assistants = response.result {
            appendOrUpdateAssistant(assistants)
            hasNext = response.hasNext
        }

        if !response.cache, response.pop() != nil {
            firstSuccessResponse = true
            isLoading = false
        }
    }

    public func getAssistants() {
        if isLoading { return }
        isLoading = true
        let req = AssistantsRequest(count: count, offset: offset)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.assistant.get(req)
        }
    }

    public func appendOrUpdateAssistant(_ assistants: [Assistant]) {
        // Remove all assistants that were cached, to prevent duplication.
        assistants.forEach { assistant in
            var assistant = assistant
            if var oldAssistant = self.assistants.first(where: { $0.participant?.id == assistant.participant?.id }) {
                oldAssistant.update(assistant)
                oldAssistant.id = assistant.participant?.id
            } else {
                assistant.id = assistant.participant?.id
                self.assistants.append(assistant)
            }
        }
    }

    public func deactiveSelectedAssistants() {
        isLoading = true
        selectedAssistant.forEach { assistant in
            var assistant = assistant
            if assistant.assistant == nil {
                assistant.assistant = .init(id: "\(assistant.participant?.coreUserId ?? 0)", idType: .coreUserId)
            }
        }
        let req = DeactiveAssistantRequest(assistants: selectedAssistant)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.assistant.deactive(req)
        }
    }

    public func deactive(indexSet: IndexSet) {
        let assistants = assistants.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        assistants.forEach { assistant in
            selectedAssistant.append(assistant)
            deactiveSelectedAssistants()
        }
    }

    public func onDeactiveAssistant(_ response: ChatResponse<[Assistant]>) {
        if response.pop() != nil {
            response.result?.forEach { assistant in
                assistants.removeAll(where: {$0.participant?.id == assistant.participant?.id})
            }
        }
    }

    public func block(_ assistant: Assistant) {
        let req = BlockUnblockAssistantRequest(assistants: [assistant])
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.assistant.block(req)
        }
    }

    public func onBlockAssistant(_ response: ChatResponse<[Assistant]>) {
        if response.pop() != nil, let index = assistants.firstIndex(where: {$0.participant?.id == response.result?.first?.participant?.id}) {
            assistants[index].block = true
        }
    }

    public func unblock(_ assistant: Assistant) {
        let req = BlockUnblockAssistantRequest(assistants: [assistant])
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.assistant.unblock(req)
        }
    }

    public func onUnBlockAssistant(_ response: ChatResponse<[Assistant]>) {
        if response.pop() != nil, let index = assistants.firstIndex(where: {$0.participant?.id == response.result?.first?.participant?.id}) {
            assistants[index].block = false
        }
    }

    public func blockedList() {
        let req = BlockedAssistantsRequest()
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.assistant.blockedList(req)
        }
    }

    public func onBlockedListAssistant(_ response: ChatResponse<[Assistant]>) {
        if response.pop() != nil {
            response.result?.forEach{ blockedAssistant in
                if !blockedAssistants.contains(where: {$0.id == blockedAssistant.id}) {
                    blockedAssistants.append(blockedAssistant)
                }
            }
        }
    }

    public func registerAssistant(_ contact: Contact) {
        let assistant = Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        let req = RegisterAssistantsRequest(assistants: [.init(assistant: assistant, roles: Roles.allCases.filter({$0 != .unknown}))])
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.assistant.register(req)
        }
    }

    public func onRegisterAssistant(_ response: ChatResponse<[Assistant]>) {
        if response.pop() != nil {
            assistants.append(contentsOf: response.result ?? [])
        }
    }

    public func toggleSelectedAssistant(isSelected: Bool, assistant: Assistant) {
        if isSelected {
            selectedAssistant.append(assistant)
        } else {
            selectedAssistant.removeAll(where: { $0.participant?.id == assistant.participant?.id })
        }
    }
}
