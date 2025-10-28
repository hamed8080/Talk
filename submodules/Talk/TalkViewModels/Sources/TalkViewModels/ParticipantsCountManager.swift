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
    private var archivesVM: ThreadsViewModel { AppState.shared.objectsContainer.archivesVM }

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
        updateNonArchivesVMCount(count: count, threadId: threadId)
        updateArchivesVMCount(count: count, threadId: threadId)
    }
    
    private func updateNonArchivesVMCount(count: Int, threadId: Int) {
        if let index = threadsVM.threads.firstIndex(where: {$0.id == threadId}) {
            threadsVM.threads[index].participantCount = count
            let vm = threadViewModel(threadId: threadId)
            vm?.setParticipantsCount(count)
            vm?.conversationSubtitle.updateSubtitle()
            AppState.shared.objectsContainer.navVM.detailViewModel(threadId: threadId)?.animateObjectWillChange()
        }
    }
    
    private func updateArchivesVMCount(count: Int, threadId: Int) {
        if let index = archivesVM.threads.firstIndex(where: {$0.id == threadId}) {
            archivesVM.threads[index].participantCount = count
            let vm = threadViewModel(threadId: threadId)
            vm?.setParticipantsCount(count)
            vm?.conversationSubtitle.updateSubtitle()
            AppState.shared.objectsContainer.navVM.detailViewModel(threadId: threadId)?.animateObjectWillChange()
        }
    }
    
    private func threadViewModel(threadId: Int) -> ThreadViewModel? {
        AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
    }

    private func currentCount(threadId: Int?) -> Int {
        if let thread = threadsVM.threads.first(where: {$0.id == threadId}) {
            return thread.participantCount ?? 0
        } else if let archiveThread = archivesVM.threads.first(where: {$0.id == threadId}) {
            return archiveThread.participantCount ?? 0
        }
        return 0
    }

    func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .joined(let response):
            updateCountOnJoin(response)
        case .left(let response):
            updateCountOnLeft(response)
        default:
            break
        }
    }

    func onParticipantEvent(_ event: ParticipantEventTypes) {
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
