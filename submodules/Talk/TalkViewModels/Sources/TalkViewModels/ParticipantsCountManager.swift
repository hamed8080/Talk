//
//  ParticipantsCountManager.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Combine
import Chat

/* 
 This viewModel only manages the number of participants in a group localy.
 It will update the ThreadViewModel in the stack of navigations, then look for any
 opened detail view.
*/
@MainActor
public class ParticipantsCountManager {
    public var cancelable: Set<AnyCancellable> = []
    private var threadsVM: ThreadsViewModel { AppState.shared.objectsContainer.threadsVM }

    init() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onThreadEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onParticipantEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    func updateCountOnDelete(_ response: ChatResponse<[Participant]>) {
        let threadId = response.subjectId ?? -1
        reduceCount(threadId: threadId)
    }

    func updateCountOnAdd(_ response: ChatResponse<Conversation>) {
        let threadId = response.result?.id ?? -1
        let addedCount = (response.result?.participants ?? []).count
        increaseCount(addedCount: addedCount, threadId: threadId)
    }

    func updateCountOnLeft(_ response: ChatResponse<User>) {
        let threadId = response.subjectId ?? -1
        reduceCount(threadId: threadId)
    }

    func updateCountOnJoin(_ response: ChatResponse<Conversation>) {
        let threadId = response.result?.id ?? -1
        increaseCount(addedCount: 1, threadId: threadId)
    }

    private func reduceCount(threadId: Int) {
        let current = currentCount(threadId: threadId)
        let count = max(0, current - 1)
        updateCount(count: count, threadId: threadId)
    }

    private func increaseCount(addedCount: Int, threadId: Int) {
        let current = currentCount(threadId: threadId)
        let count = current + addedCount
        updateCount(count: count, threadId: threadId)
    }

    private func updateCount(count: Int, threadId: Int) {
        if let index = threadsVM.threads.firstIndex(where: {$0.id == threadId}) {
            threadsVM.threads[index].participantCount = count
            threadViewModel(threadId: threadId)?.thread.participantCount = count
//            threadViewModel(threadId: threadId)?.animateObjectWillChange()
            detailViewModel(threadId: threadId)?.animateObjectWillChange()
        }
    }

    private func threadViewModel(threadId: Int) -> ThreadViewModel? {
        AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
    }

    private func detailViewModel(threadId: Int) -> ThreadDetailViewModel? {
        if AppState.shared.objectsContainer.threadDetailVM.thread?.id == threadId {
            return AppState.shared.objectsContainer.threadDetailVM
        }
        return nil
    }

    private func currentCount(threadId: Int?) -> Int {
        threadsVM.threads.first(where: {$0.id == threadId})?.participantCount ?? 0
    }

    @MainActor
    func onThreadEvent(_ event: ThreadEventTypes?) async {
        switch event {
        case .joined(let response):
            updateCountOnJoin(response)
        case .left(let response):
            updateCountOnLeft(response)
        default:
            break
        }
    }

    @MainActor
    func onParticipantEvent(_ event: ParticipantEventTypes) async {
        switch event {
        case .add(let chatResponse):
            updateCountOnAdd(chatResponse)
        case .deleted(let chatResponse):
            updateCountOnDelete(chatResponse)
        default:
            break
        }
    }
}
