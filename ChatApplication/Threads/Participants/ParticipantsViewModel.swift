//
//  ParticipantsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation
import SwiftUI

class ParticipantsViewModel: ObservableObject {
    private var thread: Conversation
    private var hasNext = true
    private var count = 15
    private var offset = 0
    private(set) var firstSuccessResponse = false
    private(set) var cancellableSet: Set<AnyCancellable> = []
    @Published var isLoading = false
    @Published private(set) var totalCount = 0
    @Published private(set) var participants: [Participant] = []

    init(thread: Conversation) {
        self.thread = thread
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: threadEventNotificationName)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                if case let .threadRemoveParticipants(removedParticipants) = event {
                    withAnimation {
                        removedParticipants.forEach { participant in
                            self?.removeParticipant(participant)
                        }
                    }
                }
            }
            .store(in: &cancellableSet)
        getParticipants()
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            offset = 0
            getParticipants()
        }
    }

    func getParticipants() {
        isLoading = true
        ChatManager.activeInstance.getThreadParticipants(.init(threadId: thread.id ?? 0, offset: offset, count: count), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getParticipants()
    }

    func onServerResponse(_ response: ChatResponse<[Participant]>) {
        if let participants = response.result {
            firstSuccessResponse = true
            appendParticipants(participants: participants)
            hasNext = response.pagination?.hasNext ?? false
        }
        isLoading = false
    }

    func onCacheResponse(_ response: ChatResponse<[Participant]>) {
        if let participants = response.result {
            appendParticipants(participants: participants)
            hasNext = response.pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    func refresh() {
        clear()
        getParticipants()
    }

    func clear() {
        offset = 0
        count = 15
        totalCount = 0
        participants = []
    }

    func setupPreview() {
        appendParticipants(participants: MockData.generateParticipants())
    }

    func removePartitipant(_ participant: Participant) {
        guard let id = participant.id else { return }
        ChatManager.activeInstance.removeParticipants(.init(participantId: id, threadId: thread.id ?? 0)) { [weak self] response in
            if response.error == nil, let participant = response.result?.first {
                self?.removeParticipant(participant)
            }
        }
    }

    func preparePaginiation() {
        offset = participants.count
    }

    func appendParticipants(participants: [Participant]) {
        // remove older data to prevent duplicate on view
        self.participants.removeAll(where: { participant in participants.contains(where: { participant.id == $0.id }) })
        self.participants.append(contentsOf: participants)
    }

    func removeParticipant(_ participant: Participant) {
        participants.removeAll(where: { $0.id == participant.id })
    }
}
