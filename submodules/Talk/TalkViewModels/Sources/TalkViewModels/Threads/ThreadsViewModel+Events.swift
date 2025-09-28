//
//  ThreadsViewModel+Events.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Foundation
import Chat

extension ThreadsViewModel {

    func setupObservers() {
        lazyList.objectWillChange.sink { [weak self] _ in
            self?.animateObjectWillChange()
        }
        .store(in: &cancelable)
        AppState.shared.$connectionStatus
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onConnectionStatusChanged(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onThreadEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)

        NotificationCenter.call.publisher(for: .call)
            .compactMap { $0.object as? CallEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onCallEvent(event)
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
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    self?.onCancelTimer(key: key)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.system.publisher(for: .system)
            .compactMap { $0.object as? SystemEventTypes }
            .sink { [weak self] systemMessageEvent in
                Task { [weak self] in
                    await self?.onThreadSystemEvent(systemMessageEvent)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.reaction.publisher(for: .reaction)
            .compactMap { $0.object as? ReactionEventTypes }
            .sink { [weak self] reactionMessageEvent in
                Task { [weak self] in
                    self?.onReactionEvent(reactionMessageEvent)
                }
            }
            .store(in: &cancelable)
    }

    func onThreadSystemEvent(_ event: SystemEventTypes) async {
        switch event {
        case .systemMessage(let chatResponse):
            guard let result = chatResponse.result else { return }
            if let conversation = threads.first(where: { $0.id == chatResponse.subjectId }) {
                delegate?.setEvent(smt: result.smt, conversation: conversation)
            }
        default:
            break
        }
    }

    func onParticipantEvent(_ event: ParticipantEventTypes) async {
        switch event {
        case .add(let chatResponse):
            await onAddPrticipant(chatResponse)
        default:
            break
        }
    }

    func onThreadEvent(_ event: ThreadEventTypes?) async {
        switch event {
        case .created(let response):
            await onCreate(response)
        case .deleted(let response):
            onDeleteThread(response)
        case let .lastMessageDeleted(response), let .lastMessageEdited(response):
            if let thread = response.result {
                await onLastMessageChanged(thread)
            }
        case .updatedInfo(let response):
            if let thread = response.result {
                updateThreadInfo(thread)
            }
        case .mute(let response):
            await onMuteThreadChanged(mute: true, threadId: response.result)
        case .unmute(let response):
            await onMuteThreadChanged(mute: false, threadId: response.result)
        case .changedType(let response):
            onChangedType(response)
        case .spammed(let response):
            onSpam(response)
        case .unreadCount(let response):
            await onUnreadCounts(response)
        case .pin(let response):
            await onPin(response)
        case .unpin(let response):
            await onUNPin(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        case .lastSeenMessageUpdated(let response):
            await onLastSeenMessageUpdated(response)
        case .joined(let response):
            await onJoinedToPublicConversation(response)
        case .left(let response):
            onLeftThread(response)
        case .closed(let response):
            onClosed(response)
        default:
            break
        }
    }

    func onCallEvent(_ event: CallEventTypes) async {
        switch event {
        case let .callEnded(response):
            activeCallThreads.removeAll(where: { $0.callId == response?.result })
        case let .groupCallCanceled(response):
            activeCallThreads.append(.init(threadId: response.subjectId ?? -1, callId: response.result?.callId ?? -1))
        case let .callReceived(response):
            activeCallThreads.append(.init(threadId: response.result?.conversation?.id ?? -1, callId: response.result?.callId ?? -1))
        default:
            break
        }
    }

    func onMessageEvent(_ event: MessageEventTypes) async {
        switch event {
        case .new(let chatResponse):
            let message = chatResponse.result ?? .init()
            let myId = AppState.shared.user?.id ?? -1
            let isPrivate = message.conversation?.type?.isPrivate == true
            let isMeJoinedPublic = message.messageType == .participantJoin && message.participant?.id == myId && !isPrivate
            /// This if prevent duplicate joined to a public group by discarding this message,
            /// it will be added by another event directly
            if !isMeJoinedPublic {
                incNewQueue.onMessageEvent(chatResponse)                
            }
            if let uniqueId = message.uniqueId {
                AppState.shared.objectsContainer.pendingManager.remove(uniqueId: uniqueId)
            }
        case .forward(let chatResponse):
            incForwardQueue.onMessageEvent(chatResponse)
            if let uniqueId = chatResponse.uniqueId {
                AppState.shared.objectsContainer.pendingManager.removeForwards(uniqueId: uniqueId)
            }
        case .cleared(let chatResponse):
            onClear(chatResponse)
        case .seen(let response):
            onSeen(response)
        case .deleted(let response):
            await onMessageDeleted(response)
        case .pin(let response):
            onPinMessage(response)
        case .unpin(let response):
            onUNPinMessage(response)
        default:
            break
        }
    }

    private func onReactionEvent(_ event: ReactionEventTypes) {
        if case let .customizeReactions(response) = event {
            if let index = threads.firstIndex(where: {$0.id == response.subjectId}) {
                threads[index].reactionStatus = response.result?.reactionStatus
                threads[index].animateObjectWillChange()
                delegate?.reloadCellWith(conversation: threads[index])
                animateObjectWillChange()

                // Update Active view model
                let activeVM = AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel
                if let activeVM = activeVM, activeVM.id == response.subjectId {
                    activeVM.thread.reactionStatus = response.result?.reactionStatus
                    if activeVM.thread.reactionStatus == .enable {
                        activeVM.reactionViewModel.allowedReactions = Sticker.allCases.filter({ $0 != .unknown})
                    } else {
                        activeVM.reactionViewModel.allowedReactions = response.result?.allowedReactions ?? []
                    }
                }
            }
        }
    }
}
