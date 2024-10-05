//
//  FindPartnerParticipantViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine
import TalkModels

public final class FindPartnerParticipantViewModel {
    private let id: String = "P2P_PARTNET_PARTICIPANT_KEY-\(UUID().uuidString)"
    private var cancelable: Set<AnyCancellable> = []
    public typealias CompletionHandler = (Participant?) -> Void
    private var completion: CompletionHandler?

    public init() {
        registerNotifications()
    }

    public func findPartnerBy(threadId: Int, completion: CompletionHandler? = nil) {
        self.completion = completion
        let req = ThreadParticipantRequest(threadId: threadId, offset: 0, count: 20)
        RequestsManager.shared.append(prepend: id, value: req)
        ChatManager.activeInstance?.conversation.participant.get(req)
    }

    private func onP2PPartnerParticipant(_ response: ChatResponse<[Participant]>) {
        if !response.cache, response.pop(prepend: id) != nil, let participants = response.result {
            if let partner = participants.first(where: {$0.auditor == false && $0.id != AppState.shared.user?.id}) {
                completion?(partner)
            }
        }
    }

    private func registerNotifications() {
        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                self?.onParticipantEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onParticipantEvent(_ event: ParticipantEventTypes?) {
        if case .participants(let response) = event {
            onP2PPartnerParticipant(response)
        }
    }

    deinit {
        print("deinit FindPartnerParticipantViewModel")
    }
}
