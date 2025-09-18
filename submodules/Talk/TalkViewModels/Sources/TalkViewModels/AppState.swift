//
//  AppState.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Chat
import Combine
import SwiftUI
import TalkExtensions
import TalkModels

@MainActor
public final class AppState: ObservableObject, Sendable {
    public static let shared = AppState()
    public var spec: Spec = Spec.empty
    public var user: User?
    @Published public var error: ChatError?
    @Published public var isLoading: Bool = false
    @Published public var callLogs: [URL]?
    @Published public var connectionStatusString = ""
    private var cancelable: Set<AnyCancellable> = []
    public var windowMode: WindowMode = .iPhone
    public static var isInSlimMode = AppState.shared.windowMode.isInSlimMode
    public var lifeCycleState: AppLifeCycleState?
    public var objectsContainer: ObjectsContainer!
    public var appStateNavigationModel: AppStateNavigationModel = .init()
    @Published public var connectionStatus: ConnectionStatus = .connecting {
        didSet {
            setConnectionStatus(connectionStatus)
        }
    }
    
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }
    
    private init() {
        registerObservers()
        updateWindowMode()
        updateUserCache(user: UserConfigManagerVM.instance.currentUserConfig?.user)
    }

    public func updateUserCache(user: User?) {
        Task { @ChatGlobalActor in
            await MainActor.run {
                self.user = user
            }
        }
    }
    
    public func updateWindowMode() {
        windowMode = UIApplication.shared.windowMode()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task { @MainActor in
                AppState.isInSlimMode =
                UIApplication.shared.windowMode().isInSlimMode
            }
        }
        
        NotificationCenter.windowMode.post(
            name: .windowMode, object: windowMode)
    }
    
    public func setConnectionStatus(_ status: ConnectionStatus) {
        if status == .connected {
            connectionStatusString = ""
        } else {
            connectionStatusString = String(describing: status) + " ..."
        }
    }
    
    public func animateAndShowError(_ error: ChatError) {
        withAnimation {
            isLoading = false
            self.error = error
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) {
                [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.error = nil
                }
            }
        }
    }
}

// Observers.
extension AppState {
    private func registerObservers() {
        UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }).publisher.sink { [weak self] newValue in
            self?.updateWindowMode()
        }
        .store(in: &cancelable)
    }
}

// Conversation
extension AppState {
    public func openThread(contact: Contact) async throws {
        let coreUserId = contact.user?.coreUserId ?? contact.user?.id ?? -1
        appStateNavigationModel.userToCreateThread = contact.toParticipant
        if let conversation = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            navVM.append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            navVM.append(thread: conversation)
        } else {
            showEmptyThread(userName: nil)
        }
    }
    
    public func openThread(participant: Participant) async throws {
        appStateNavigationModel.userToCreateThread = participant
        guard let coreUserId = participant.coreUserId else { return }
        
        if let conversation = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            navVM.append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            navVM.append(thread: conversation)
        } else {
            showEmptyThread(userName: participant.username)
        }
    }
    
    public func openThreadWith(userName: String) async throws {
        appStateNavigationModel.userToCreateThread = .init(username: userName)
        
        if let conversation = try await GetThreadsReuqester().get(userName: userName) {
            navVM.append(thread: conversation)
        } else {
            showEmptyThread(userName: userName)
        }
    }
    
    /// Forward messages from a thread to a destination thread.
    /// If the conversation is nil it try to use contact. Firstly it opens a conversation using the given contact core user id then send messages to the conversation.
    public func openForwardThread(from: Int, conversation: Conversation, messages: [Message]) {
        let dstId = conversation.id ?? -1
        setupForwardRequest(from: from, to: dstId, messages: messages)
        navVM.append(thread: conversation)
    }
    
    public func openForwardThread(from: Int, contact: Contact, messages: [Message]) async throws {
        if let conversation = checkForP2POffline(coreUserId: contact.user?.coreUserId ?? -1) {
            setupForwardRequest(from: from, to: conversation.id ?? -1, messages: messages)
            navVM.append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: contact.user?.coreUserId ?? -1) {
            setupForwardRequest(from: from, to: conversation.id ?? -1, messages: messages)
            navVM.append(thread: conversation)
        } else {
            let dstId = LocalId.emptyThread.rawValue
            setupForwardRequest(from: from, to: dstId, messages: messages)
            try await openThread(contact: contact)
        }
    }
    
    public func setupForwardRequest(from: Int, to: Int, messages: [Message]) {
        self.appStateNavigationModel.forwardMessages = messages
        let messageIds = messages
            .sorted { $0.time ?? 0 < $1.time ?? 0 }
            .compactMap { $0.id }
        let req = ForwardMessageRequest(fromThreadId: from, threadId: to, messageIds: messageIds)
        appStateNavigationModel.forwardMessageRequest = req
    }
    
    private func checkForP2POffline(coreUserId: Int) -> Conversation? {
        let threads = objectsContainer.threadsVM.threads + objectsContainer.archivesVM.archives
        
        return threads.first(where: {
            ($0.partner == coreUserId || ($0.participants?.contains(where: { $0.coreUserId == coreUserId }) ?? false)) &&
            $0.group == false && $0.type == .normal
        }
        )?.toStruct()
    }
    
    private func checkForOffline(threadId: Int) -> Conversation? {
        let threads = objectsContainer.threadsVM.threads + objectsContainer.archivesVM.archives
        return threads.first(where: { $0.id == threadId })?.toStruct()
    }
    
    public func showEmptyThread(userName: String? = nil) {
        guard let participant = appStateNavigationModel.userToCreateThread
        else { return }
        let particpants = [participant]
        let conversation = Conversation(
            id: LocalId.emptyThread.rawValue,
            image: participant.image,
            title: participant.name ?? userName,
            participants: particpants)
        navVM.append(thread: conversation)
    }
    
    public func openThreadAndMoveToMessage(conversationId: Int, messageId: Int, messageTime: UInt) async throws {
        self.appStateNavigationModel.moveToMessageId = messageId
        self.appStateNavigationModel.moveToMessageTime = messageTime
        
        /// Check if destiation thread is already inside NavigationPath stack,
        /// If it is exist we will pop and remove current Path, to show the viewModel
        let navVM = objectsContainer.navVM
        if navVM.viewModel(for: conversationId) != nil, let currentThreadId = navVM.presentedThreadViewModel?.threadId {
            navVM.remove(threadId: currentThreadId)
        } else if let conversation = checkForOffline(threadId: conversationId) {
            navVM.append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(.init(threadIds: [conversationId])).first {
            navVM.append(thread: conversation)
        }
    }
}

extension AppState {
    public func openURL(url: URL) {
        NotificationCenter.default.post(name: NSNotification.Name("openURL"), object: url)
        animateObjectWillChange()
    }
}

extension AppState {
    public func clear() {
        appStateNavigationModel = .init()
        callLogs = nil
        error = nil
        isLoading = false
    }
}

// Lifesycle
extension AppState {
    public var isInForeground: Bool {
        lifeCycleState == .active || lifeCycleState == .foreground
    }
}

extension AppState {    
    static func serverType(config: ChatConfig?) -> ServerTypes? {
        if config?.spec.server.server == ServerTypes.main.rawValue {
            return .main
        } else if config?.spec.server.server == ServerTypes.sandbox.rawValue {
            return .sandbox
        } else if config?.spec.server.server == ServerTypes.integration.rawValue {
            return .integration
        } else {
            return nil
        }
    }
}
