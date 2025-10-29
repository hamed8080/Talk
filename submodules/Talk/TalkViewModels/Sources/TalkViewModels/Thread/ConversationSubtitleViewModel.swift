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
import Logger

@MainActor
public final class ConversationSubtitleViewModel {
    private var subtitle: String = ""
    private var partnerLastSeen = ""
    public var lastSeenPartnerTime: Int?
    private var thread: Conversation? { viewModel?.thread }
    private var p2pPartnerFinderVM: FindPartnerParticipantViewModel?
    private var notSeenDurationViewModel: GetNotSeenDurationViewModel?
    public weak var viewModel: ThreadViewModel?
    private var cancellableSet: Set<AnyCancellable> = []
    
    public init() {}
    
    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        if isP2P {
            getPartnerInfo()
        } else if viewModel.id == LocalId.emptyThread.rawValue {
            getLastSeenByUserId()
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
    }
    
    private func getParticipantsCountOrLastSeen() -> String? {
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let threadsItem = threadsVM.threads.first(where: {$0.id == thread?.id})
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
            if let partner = partner?.notSeenDuration {
                self?.processResponse(partner)
            }
        }
    }
    
    private func processResponse(_ notSeenDuration: Int) {
        let lastSeen = notSeenDuration.lastSeenString
        let localized = "Contacts.lastVisited".bundleLocalized()
        let formatted = String(format: localized, lastSeen)
        self.partnerLastSeen = formatted
        updateTo(partnerLastSeen)
    }
    
    private func getLastSeenByUserId() {
        guard let userId = AppState.shared.objectsContainer.navVM.navigationProperties.userToCreateThread?.id else { return }
        notSeenDurationViewModel = .init(userId: userId)
        Task { [weak self] in
            guard let self = self else { return }
            let notSeenDuration = await notSeenDurationViewModel?.get()
            if let lastSeenByUserId = notSeenDuration?.time, let threadId = viewModel?.id {
                lastSeenPartnerTime = lastSeenByUserId
                processResponse(lastSeenByUserId)
            }
        }
    }
    
    public func getPartnerLastSeen() -> Int? {
        lastSeenPartnerTime
    }
    
    private var isP2P: Bool {
        thread?.group == false && thread?.type != .selfThread
    }
    
    private func updateTo(_ newValue: String?, _ smt: SMT? = nil) {
        viewModel?.delegate?.updateSubtitleTo(newValue, smt)
    }
    
    public func setEvent(smt: SMT?) {
        let hasEvent = smt != nil
        if hasEvent {
            updateTo(smt?.stringEvent?.bundleLocalized(), smt)
        } else {
            updateTo(getParticipantsCountOrLastSeen())
        }
    }
    
    private func setParticipantsCountOnOpen() {
        Task { [weak self] in
            guard let self = self else { return }
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
        Task { [weak self] in
            guard let self = self else { return }
            do {
                if let conversation = try await GetThreadsReuqester().get(req, withCache: false).first {
                    viewModel?.setParticipantsCount(conversation.participantCount ?? 0)
                    updateTo(getParticipantsCountOrLastSeen())
                }
            } catch {
                log("Failed to get conversation to extract pariticipantsCount with error: \(error.localizedDescription)")
            }
        }
    }
    
    public func updateSubtitle() {
        setParticipantsCountOnOpen()
    }
}

private extension ConversationSubtitleViewModel {
    func log(_ string: String) {
        Logger.log(title: "ConversationSubtitleViewModel", message: string)
    }
}
