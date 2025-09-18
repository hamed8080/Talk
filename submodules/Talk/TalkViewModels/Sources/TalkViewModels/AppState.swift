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

/// Properties that can transfer between each navigation page and stay alive unless manually destroyed.
public struct AppStateNavigationModel: Sendable {
    public var userToCreateThread: Participant?
    public var replyPrivately: Message?
    public var forwardMessages: [Message]?
    public var forwardMessageRequest: ForwardMessageRequest?
    public var moveToMessageId: Int?
    public var moveToMessageTime: UInt?
    public var openURL: URL?
    public init() {}
}

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
    public var searchP2PThread: SearchP2PConversation?
    public var searchThreadById: SearchConversationById?
    @Published public var connectionStatus: ConnectionStatus = .connecting {
        didSet {
            setConnectionStatus(connectionStatus)
        }
    }
    
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
            AppState.shared.objectsContainer.navVM.append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            AppState.shared.objectsContainer.navVM.append(thread: conversation)
        } else {
            showEmptyThread(userName: nil)
        }
    }
    
    public func openThread(participant: Participant) async throws {
        appStateNavigationModel.userToCreateThread = participant
        guard let coreUserId = participant.coreUserId else { return }
        
        if let conversation = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            AppState.shared.objectsContainer.navVM.append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            AppState.shared.objectsContainer.navVM.append(thread: conversation)
        } else {
            showEmptyThread(userName: nil)
        }
    }
    
    public func openThreadWith(userName: String) {
        appStateNavigationModel.userToCreateThread = .init(username: userName)
        searchForP2PThread(coreUserId: nil, userName: userName)
    }
    
    /// Forward messages from a thread to a destination thread.
    /// If the conversation is nil it try to use contact. Firstly it opens a conversation using the given contact core user id then send messages to the conversation.
    public func openForwardThread(
        from: Int, conversation: Conversation, messages: [Message]
    ) {
        let dstId = conversation.id ?? -1
        setupForwardRequest(from: from, to: dstId, messages: messages)
        AppState.shared.objectsContainer.navVM.append(thread: conversation)
    }
    
    public func openForwardThread(from: Int, contact: Contact, messages: [Message]) {
        if let conv = localConversationWith(contact) {
            setupForwardRequest(
                from: from, to: conv.id ?? -1, messages: messages)
            AppState.shared.objectsContainer.navVM.append(thread: conv)
        } else {
            Task {
                try await openEmptyForwardThread(from: from, contact: contact, messages: messages)
            }
        }
    }
    
    private func openEmptyForwardThread(from: Int, contact: Contact, messages: [Message]) async throws {
        let dstId = LocalId.emptyThread.rawValue
        setupForwardRequest(from: from, to: dstId, messages: messages)
        try await openThread(contact: contact)
    }
    
    public func setupForwardRequest(from: Int, to: Int, messages: [Message]) {
        self.appStateNavigationModel.forwardMessages = messages
        let messageIds = messages.sorted { $0.time ?? 0 < $1.time ?? 0 }
            .compactMap { $0.id }
        let req = ForwardMessageRequest(
            fromThreadId: from, threadId: to, messageIds: messageIds)
        appStateNavigationModel.forwardMessageRequest = req
    }
    
    private func localConversationWith(_ contact: Contact) -> Conversation? {
        guard let coreUserId = contact.user?.coreUserId,
              let conversation = checkForP2POffline(coreUserId: coreUserId)
        else { return nil }
        return conversation
    }
    
    public func searchForP2PThread(coreUserId: Int?, userName: String? = nil) {
        if let thread = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            onSearchP2PThreads(thread)
            return
        }
        searchP2PThread = SearchP2PConversation()
        searchP2PThread?.searchForP2PThread(
            coreUserId: coreUserId, userName: userName
        ) { [weak self] conversation in
            self?.onSearchP2PThreads(conversation, userName: userName)
            self?.searchP2PThread = nil
        }
    }
    
    public func searchForGroupThread(
        threadId: Int, moveToMessageId: Int, moveToMessageTime: UInt
    ) {
        if let thread = checkForGroupOffline(tharedId: threadId) {
            AppState.shared.objectsContainer.navVM.append(thread: thread)
            return
        }
        searchThreadById = SearchConversationById()
        searchThreadById?.search(id: threadId) { [weak self] conversations in
            if let thread = conversations?.first {
                AppState.shared.objectsContainer.navVM.append(thread: thread)
            }
            self?.searchThreadById = nil
        }
    }
    
    private func onSearchP2PThreads(
        _ thread: Conversation?, userName: String? = nil
    ) {
        let thread = getRefrenceObject(thread) ?? thread
        updateThreadIdIfIsInForwarding(thread)
        if let thread = thread {
            AppState.shared.objectsContainer.navVM.append(thread: thread)
        } else {
            showEmptyThread(userName: userName)
        }
    }
    
    public func checkForP2POffline(coreUserId: Int) -> Conversation? {
        let threads = objectsContainer.threadsVM.threads + objectsContainer.archivesVM.archives
        
        return threads.first(where: {
            ($0.partner == coreUserId
             || ($0.participants?.contains(where: {
                $0.coreUserId == coreUserId
            }) ?? false))
            && $0.group == false && $0.type == .normal
        }
        )?.toStruct()
    }
    
    private func updateThreadIdIfIsInForwarding(_ thread: Conversation?) {
        if let req = appStateNavigationModel.forwardMessageRequest {
            let forwardReq = ForwardMessageRequest(
                fromThreadId: req.fromThreadId,
                threadId: thread?.id ?? LocalId.emptyThread.rawValue,
                messageIds: req.messageIds)
            appStateNavigationModel.forwardMessageRequest = forwardReq
        }
    }
    
    /// It will search through the Conversation array to prevent creation of new refrence.
    /// If we don't use object refrence in places that needs to open the thread there will be a inconsistensy in data such as reply privately.
    private func getRefrenceObject(_ conversation: Conversation?)
    -> Conversation?
    {
        objectsContainer.threadsVM.threads.first { $0.id == conversation?.id }?
            .toStruct()
    }
    
    public func checkForGroupOffline(tharedId: Int) -> Conversation? {
        objectsContainer.threadsVM.threads
            .first(where: { $0.group == true && $0.id == tharedId })?.toStruct()
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
        AppState.shared.objectsContainer.navVM.append(thread: conversation)
    }
    
    public func openThreadAndMoveToMessage(
        conversationId: Int, messageId: Int, messageTime: UInt
    ) {
        self.appStateNavigationModel.moveToMessageId = messageId
        self.appStateNavigationModel.moveToMessageTime = messageTime
        
        /// Check if destiation thread is already inside NavigationPath stack,
        /// If it is exist we will pop and remove current Path, to show the viewModel
        let navVM = objectsContainer.navVM
        if navVM.viewModel(for: conversationId) != nil,
           let currentThreadId = navVM.presentedThreadViewModel?.threadId
        {
            navVM.remove(threadId: currentThreadId)
        } else {
            searchForGroupThread(
                threadId: conversationId, moveToMessageId: messageId,
                moveToMessageTime: messageTime)
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
