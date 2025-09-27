//
//  MessageParticipantsSeenViewModel.swift
//  
//
//  Created by hamed on 11/15/23.
//

import Foundation
import Combine
import Chat

@MainActor
public class MessageParticipantsSeenViewModel: ObservableObject {
    @Published public var participants: [Participant] = []
    private var hasNext = true
    private var count = 15
    private var offset = 0
    public let message: Message
    @Published public var isLoading = false
    private var cancelable: Set<AnyCancellable> = []
    public var isEmpty: Bool { !isLoading && participants.isEmpty }

    public init(message: Message) {
        self.message = message
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                if case .seenByParticipants(let response) = event {
                    self?.onSeenParticipants(response)
                }
            }
            .store(in: &cancelable)
    }

    public func getParticipants() {
        isLoading = true
        let req = MessageSeenByUsersRequest(messageId: message.id ?? -1, count: count, offset: offset)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.seenByParticipants(req)
        }
    }

    public func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getParticipants()
    }

    public func preparePaginiation() {
        offset = participants.count
    }

    private func onSeenParticipants(_ response: ChatResponse<[Participant]> ) {
        isLoading = false
        response.result?.filter({ $0.id != AppState.shared.user?.id }).forEach{ newParticipant in
            if !self.participants.contains(where: {$0.id == newParticipant.id}) {
                self.participants.append(newParticipant)
            }
        }
    }
    
    deinit {
#if DEBUG
        print("deinit MessageParticipantsSeenViewModel for messageId: \(message.id ?? -1)")
#endif
    }
}
