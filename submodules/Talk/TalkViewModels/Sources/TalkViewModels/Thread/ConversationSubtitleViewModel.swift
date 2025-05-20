//
//  ConversationSubtitleViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import Chat
import TalkModels

@MainActor
public final class ConversationSubtitleViewModel {
    private var subtitle: String = ""
    private var partnerLastSeen = ""
    private var thread: Conversation? { viewModel?.thread }
    private var p2pPartnerFinderVM: FindPartnerParticipantViewModel?
    public weak var viewModel: ThreadViewModel?
    private var cancellableSet: Set<AnyCancellable> = []
    private let PARTICIPANTS_COUNT_KEY: String = "GET-PARTICIPANTS-COUNT-\(UUID().uuidString)"
    
    public init() {}
    
    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        if isP2P {
            getPartnerInfo()
        } else {
            setParticipantsCountOnOpen()
        }
        registerObservers()
    }
    
    private func registerObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] newValue in
                if newValue != .connected {
                    self?.updateTo(newValue.stringValue.bundleLocalized())
                } else {
                    self?.updateTo(self?.getParticipantsCountOrLastSeen())
                }
            }
            .store(in: &cancellableSet)
        
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancellableSet)
    }
    
    private func getParticipantsCountOrLastSeen() -> String? {
        let threadsItem = viewModel?.threadsViewModel?.threads.first(where: {$0.id == thread?.id})
        let count = thread?.participantCount ?? threadsItem?.participantCount ?? 0
        if thread?.group == true, let participantsCount = count.localNumber(locale: Language.preferredLocale) {
            let localizedLabel = "Thread.Toolbar.participants".bundleLocalized()
            if count == 0 {
                requestParticipantsCount()
            }
            return "\(participantsCount) \(localizedLabel)"
        } else if thread?.id == LocalId.emptyThread.rawValue {
            return setUnknownSubtitle()
        } else if isP2P, partnerLastSeen.isEmpty {
            return setUnknownSubtitle()
        } else if partnerLastSeen.isEmpty == false {
            return partnerLastSeen
        } else {
            return nil
        }
    }
    
    private func setUnknownSubtitle() -> String {
        let lastSeen = "Contacts.lastSeen.unknown".bundleLocalized()
        let localized = "Contacts.lastVisited".bundleLocalized()
        let formatted = String(format: localized, lastSeen)
        return formatted
    }
    
    private func getPartnerInfo() {
        guard let threadId = thread?.id else { return }
        p2pPartnerFinderVM = .init()
        p2pPartnerFinderVM?.findPartnerBy(threadId: threadId) { [weak self] partner in
            if let partner = partner {
                self?.processResponse(partner)
            }
        }
    }
    
    private func processResponse(_ partner: Participant) {
        guard let lastSeen = partner.notSeenDuration?.lastSeenString else { return }
        let localized = "Contacts.lastVisited".bundleLocalized()
        let formatted = String(format: localized, lastSeen)
        self.partnerLastSeen = formatted
        updateTo(partnerLastSeen)
    }
    
    private var isP2P: Bool {
        thread?.group == false && thread?.type != .selfThread
    }
    
    private func updateTo(_ newValue: String?) {
        viewModel?.delegate?.updateSubtitleTo(newValue)
    }
    
    public func setEvent(smt: SMT?) {
        let hasEvent = smt != nil
        if hasEvent {
            updateTo(smt?.stringEvent?.bundleLocalized())
        } else {
            updateTo(getParticipantsCountOrLastSeen())
        }
    }
    
    private func setParticipantsCountOnOpen() {
        Task {
            // We will wait to delegate inside the ThreadViewModel set by viewController then set the participants count.
            try? await Task.sleep(for: .milliseconds(200))
            await MainActor.run { [weak self] in
                self?.updateTo(self?.getParticipantsCountOrLastSeen())
            }
        }
    }
    
    private func requestParticipantsCount() {
        guard let threadId = thread?.id, thread?.participantCount == nil else { return }
        let req = ThreadsRequest(threadIds: [threadId])
        RequestsManager.shared.append(prepend: PARTICIPANTS_COUNT_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
    }
    
    private func onThreadEvent(_ event: ThreadEventTypes?) {
        if case .threads(let response) = event, response.cache == false, response.pop(prepend: PARTICIPANTS_COUNT_KEY) != nil {
            viewModel?.thread.participantCount = response.result?.first?.participantCount
            updateTo(getParticipantsCountOrLastSeen())
        }
    }
    
    public func updateSubtitle() {
        setParticipantsCountOnOpen()
    }
}
