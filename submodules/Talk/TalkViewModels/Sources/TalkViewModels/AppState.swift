//
//  AppState.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Chat
import SwiftUI
import TalkModels
import TalkExtensions
import Combine

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
    public var selfThreadBuilder: SelfThreadBuilder?
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
        updateUserCache()
    }

    public func updateUserCache() {
        Task { @ChatGlobalActor in
            let fetchedUser = ChatManager.activeInstance?.userInfo
            await MainActor.run {
                self.user = UserConfigManagerVM.instance.currentUserConfig?.user ?? user
            }
        }
    }

    public func updateWindowMode() {
        windowMode = UIApplication.shared.windowMode()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task { @MainActor in
                AppState.isInSlimMode = UIApplication.shared.windowMode().isInSlimMode
            }
        }

        NotificationCenter.windowMode.post(name: .windowMode, object: windowMode)
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
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.error = nil
                }
            }
        }
    }
}

// Observers.
private extension AppState {
    private func registerObservers() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        UIApplication.shared.connectedScenes.first(where: {$0.activationState == .foregroundActive}).publisher.sink { [weak self] newValue in
            self?.updateWindowMode()
        }
        .store(in: &cancelable)
    }
}

// Event handlers.
private extension AppState {
    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .threads(let response):
            onGetThreads(response)
        case .deleted(let response):
            onDeleted(response)
        case .left(let response):
            onLeft(response)
        default:
            break
        }
    }
}

// Conversation
public extension AppState {
    private func onGetThreads(_ response: ChatResponse<[Conversation]>) {
        if RequestsManager.shared.contains(key: response.uniqueId ?? ""), let thraed = response.result?.first {
            showThread(thraed)
        }
    }

    private func onDeleted(_ response: ChatResponse<Participant>) {
        if let index = objectsContainer.navVM.pathsTracking.firstIndex(where: { ($0 as? ThreadViewModel)?.threadId == response.subjectId }) {
            objectsContainer.navVM.popPathTrackingAt(at: index)
        }
    }

    private func onLeft(_ response: ChatResponse<User>) {
        let deletedUserId = response.result?.id
        let myId = AppState.shared.user?.id
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let conversation = threadsVM.threads.first(where: {$0.id == response.subjectId})

        if deletedUserId == myId {
            if let conversation = conversation {
                threadsVM.removeThread(conversation)
            }

            /// If I am in the detail view and press leave thread I should remove first DetailViewModel -> ThreadViewModel
            if objectsContainer.navVM.pathsTracking.firstIndex(where: { ($0 as? ConversationDetailNavigationValue)?.viewModel.thread?.id == response.subjectId }) != nil {
                objectsContainer.navVM.popLastPath()
            }

            /// Remove Thread View model and pop ThreadView
            if let index = objectsContainer.navVM.pathsTracking.firstIndex(where: { ($0 as? ConversationNavigationValue)?.viewModel.threadId == response.subjectId }) {
                objectsContainer.navVM.popLastPath()
                objectsContainer.navVM.popPathTrackingAt(at: index)
            }
        }
    }

    func showThread(_ conversation: Conversation, created: Bool = false) {
        isLoading = false
        objectsContainer.navVM.append(thread: conversation, created: created)
    }

    func openThread(contact: Contact) {
        let coreUserId = contact.user?.coreUserId ?? contact.user?.id ?? -1
        appStateNavigationModel.userToCreateThread = contact.toParticipant
        searchForP2PThread(coreUserId: coreUserId)
    }

    func openThread(participant: Participant) {
        appStateNavigationModel.userToCreateThread = participant
        searchForP2PThread(coreUserId: participant.coreUserId ?? -1)
    }

    func openThreadWith(userName: String) {
        appStateNavigationModel.userToCreateThread = .init(username: userName)
        searchForP2PThread(coreUserId: nil, userName: userName)
    }

    func openSelfThread() {
        selfThreadBuilder = SelfThreadBuilder()
        selfThreadBuilder?.create { [weak self] conversation in
            self?.showThread(conversation)
            self?.selfThreadBuilder = nil
        }
    }

    /// Forward messages form a thread to a destination thread.
    /// If the conversation is nil it try to use contact. Firstly it opens a conversation using the given contact core user id then send messages to the conversation.
    func openForwardThread(from: Int, conversation: Conversation, messages: [Message]) {
        let dstId = conversation.id ?? -1
        setupForwardRequest(from: from, to: dstId, messages: messages)
        showThread(conversation)
    }

    func openForwardThread(from: Int, contact: Contact, messages: [Message]) {
        if let conv = localConversationWith(contact) {
            setupForwardRequest(from: from, to: conv.id ?? -1, messages: messages)
            showThread(conv)
        } else {
            openEmptyForwardThread(from: from, contact: contact, messages: messages)
        }
    }

    private func openEmptyForwardThread(from: Int, contact: Contact, messages: [Message]) {
        let dstId = LocalId.emptyThread.rawValue
        setupForwardRequest(from: from, to: dstId, messages: messages)
        openThread(contact: contact)
    }

    func setupForwardRequest(from: Int, to: Int, messages: [Message]) {
        self.appStateNavigationModel.forwardMessages = messages
        let messageIds = messages.sorted{$0.time ?? 0 < $1.time ?? 0}.compactMap{$0.id}
        let req = ForwardMessageRequest(fromThreadId: from, threadId: to, messageIds: messageIds)
        appStateNavigationModel.forwardMessageRequest = req
    }

    private func localConversationWith(_ contact: Contact) -> Conversation? {
        guard let coreUserId = contact.user?.coreUserId,
        let conversation = checkForP2POffline(coreUserId: coreUserId)
        else { return nil }
        return conversation
    }

    func searchForP2PThread(coreUserId: Int?, userName: String? = nil) {
        if let thread = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            onSearchP2PThreads(thread)
            return
        }
        searchP2PThread = SearchP2PConversation()
        searchP2PThread?.searchForP2PThread(coreUserId: coreUserId, userName: userName) { [weak self] conversation in
            self?.onSearchP2PThreads(conversation, userName: userName)
            self?.searchP2PThread = nil
        }
    }

    func searchForGroupThread(threadId: Int, moveToMessageId: Int, moveToMessageTime: UInt) {
        if let thread = checkForGroupOffline(tharedId: threadId) {
            showThread(thread)
            return
        }
        searchThreadById = SearchConversationById()
        searchThreadById?.search(id: threadId) { [weak self] conversations in
            if let thread = conversations?.first {
                self?.showThread(thread)
            }
            self?.searchThreadById = nil
        }
    }

    private func onSearchP2PThreads(_ thread: Conversation?, userName: String? = nil) {
        let thread = getRefrenceObject(thread) ?? thread
        updateThreadIdIfIsInForwarding(thread)
        if let thread = thread {
            showThread(thread)
        } else {
            showEmptyThread(userName: userName)
        }
    }

    func checkForP2POffline(coreUserId: Int) -> Conversation? {
        objectsContainer.threadsVM.threads
            .first(where: {
                ($0.partner == coreUserId || ($0.participants?.contains(where: {$0.coreUserId == coreUserId}) ?? false))
                && $0.group == false && $0.type == .normal}
            )
    }

    private func updateThreadIdIfIsInForwarding(_ thread: Conversation?) {
        if let req = appStateNavigationModel.forwardMessageRequest {
            let forwardReq = ForwardMessageRequest(fromThreadId: req.fromThreadId, threadId: thread?.id ?? LocalId.emptyThread.rawValue, messageIds: req.messageIds)
            appStateNavigationModel.forwardMessageRequest = forwardReq
        }
    }

    /// It will search through the Conversation array to prevent creation of new refrence.
    /// If we don't use object refrence in places that needs to open the thread there will be a inconsistensy in data such as reply privately.
    private func getRefrenceObject(_ conversation: Conversation?) -> Conversation? {
        objectsContainer.threadsVM.threads.first{ $0.id == conversation?.id}
    }

    func checkForGroupOffline(tharedId: Int) -> Conversation? {
        objectsContainer.threadsVM.threads
            .first(where: { $0.group == true && $0.id == tharedId })
    }

    func showEmptyThread(userName: String? = nil) {
        guard let participant = appStateNavigationModel.userToCreateThread else { return }
        let particpants = [participant]
        let conversation = Conversation(id: LocalId.emptyThread.rawValue,
                                        image: participant.image,
                                        title: participant.name ?? userName,
                                        participants: particpants)
        showThread(conversation)
    }

    func openThreadAndMoveToMessage(conversationId: Int, messageId: Int, messageTime: UInt) {
        self.appStateNavigationModel.moveToMessageId = messageId
        self.appStateNavigationModel.moveToMessageTime = messageTime
        searchForGroupThread(threadId: conversationId, moveToMessageId: messageId, moveToMessageTime: messageTime)
    }
}

public extension AppState {
    func openURL(url: URL) {
        appStateNavigationModel.openURL = url
        animateObjectWillChange()
    }
}

public extension AppState {
    func clear() {
        appStateNavigationModel = .init()
        callLogs = nil
        error = nil
        isLoading = false
    }
}

// Lifesycle
public extension AppState {
    var isInForeground: Bool { lifeCycleState == .active || lifeCycleState == .foreground }
}
