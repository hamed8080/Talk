//
//  ThreadDetailViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import TalkModels
import TalkExtensions

public final class ThreadDetailViewModel: ObservableObject, Hashable {
    public static func == (lhs: ThreadDetailViewModel, rhs: ThreadDetailViewModel) -> Bool {
        lhs.thread?.id == rhs.thread?.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread?.id)
    }

    private(set) var cancelable: Set<AnyCancellable> = []
    public var thread: Conversation?
    public weak var threadVM: ThreadViewModel?
    @Published public var dismiss = false
    @Published public var isLoading = false
    public var canShowEditConversationButton: Bool { thread?.group == true && thread?.admin == true && thread?.type != .selfThread }
    public var participantDetailViewModel: ParticipantDetailViewModel?
    public var editConversationViewModel: EditConversationViewModel?
    private let p2pPartnerFinder = FindPartnerParticipantViewModel()

    public init() {}

    public func setup(thread: Conversation? = nil, threadVM: ThreadViewModel? = nil, participant: Participant? = nil) {
        clear()
        self.thread = thread
        self.threadVM = threadVM

        setupParticipantDetailViewModel(participant: participant)
        setupEditConversationViewModel()

        registerObservers()
        Task {
            await fetchPartnerParticipant()
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .mute(let response):
            onMuteChanged(response)
        case .unmute(let response):
            onUnMuteChanged(response)
        case .deleted(let response):
            onDeleteThread(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        case .updatedInfo(let response):
            if response.subjectId == thread?.id {
                let replacedEmoji = response.result?.title?.replacingOccurrences(of: NSRegularExpression.emojiRegEx, with: "\\\\u{$1}", options: .regularExpression)
                thread?.title = replacedEmoji
                thread?.image = response.result?.image
                thread?.description = response.result?.description
                animateObjectWillChange()
            }
        case .closed(let response):
            onClosed(response)
        default:
            break
        }
    }

    private func updateThreadTitle() {
        /// Update thread title inside the thread if we don't have any messages with the partner yet or it's p2p thread so the title of the thread is equal to contactName
        guard let thread = thread else { return }
        if thread.group == false || thread.id ?? 0 == LocalId.emptyThread.rawValue, let contactName = participantDetailViewModel?.participant.contactName {
            threadVM?.thread.title = contactName
//            threadVM?.animateObjectWillChange()
        }
    }

    public func toggleMute() {
        guard let threadId = thread?.id, threadId != LocalId.emptyThread.rawValue else {
            fakeMuteToggle()
            return
        }
        if thread?.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    private func fakeMuteToggle() {
        if thread?.mute == nil || thread?.mute == false {
            thread?.mute = true
        } else {
            thread?.mute = false
        }
        animateObjectWillChange()
    }

    public func mute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.mute(req)
    }

    public func unmute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.unmute(req)
    }

    public func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = true
            animateObjectWillChange()
        }
    }

    public func onUnMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = false
            animateObjectWillChange()
        }
    }

    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == thread?.id {
            dismiss = true
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == thread?.id {
            dismiss = true
        }
    }

    public func clear() {
        cancelObservers()
        thread = nil
        threadVM = nil
        dismiss = false
        isLoading = false
        participantDetailViewModel = nil
        editConversationViewModel = nil
    }

    private func registerObservers() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        registerP2PParticipantObserver()
    }

    /// Fetch contact detail of the P2P participant by threadId directly here.
    public func fetchPartnerParticipant() async {
        guard thread?.group == false else { return }
        getP2PPartnerParticipant()
    }

    private func setupParticipantDetailViewModel(participant: Participant?) {
        let partner = threadVM?.participantsViewModel.participants.first(where: {$0.auditor == false && $0.id != AppState.shared.user?.id})
        let threadP2PParticipant = AppState.shared.appStateNavigationModel.userToCreateThread
        let participant = participant ?? threadP2PParticipant ?? partner
        if let participant = participant {
            setupP2PParticipant(participant)
        }
    }

    private func setupEditConversationViewModel() {
        if let threadVM = threadVM {
            editConversationViewModel = EditConversationViewModel(threadVM: threadVM)
        }
    }

    public func cancelObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
        participantDetailViewModel?.cancelObservers()
    }

    private func getP2PPartnerParticipant() {
        guard let threadId = thread?.id else { return }
        p2pPartnerFinder.findPartnerBy(threadId: threadId) { [weak self] partner in
            if let self = self, let partner = partner {
                setupP2PParticipant(partner)
            }
        }
    }

    private func setupP2PParticipant(_ participant: Participant) {
        participantDetailViewModel = ParticipantDetailViewModel(participant: participant)
        registerP2PParticipantObserver()
    }

    private func registerP2PParticipantObserver() {
        guard let participantDetailViewModel else { return }
        participantDetailViewModel.objectWillChange.sink { [weak self] _ in
            self?.updateThreadTitle()
            /// We have to update the ui all the time and keep it in sync with the ParticipantDetailViewModel.
            self?.animateObjectWillChange()
        }
        .store(in: &cancelable)
        self.animateObjectWillChange()
    }

    private func onClosed(_ response: ChatResponse<Int>) {
        if thread?.id == response.result {
            thread?.closed = true
            animateObjectWillChange()
        }
    }

    deinit {
        print("deinit ThreadDetailViewModel")
    }
}
