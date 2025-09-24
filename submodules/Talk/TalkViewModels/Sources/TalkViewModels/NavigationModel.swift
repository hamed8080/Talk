import Chat
import SwiftUI
import TalkModels

@MainActor
public final class NavigationModel: ObservableObject {
    @Published public var selectedId: Int?
    @Published public var paths = NavigationPath()
    var pathsTracking: [Any] = []
    var detailsStack: [ThreadDetailViewModel] = []
    public private(set) var navigationProperties: NavigationProperties = .init()
    public var twoRowTappedAtSameTime = false
    
    /// Once we navigate to a view with NavigationLink in SwiftUI
    /// insted of appending to the paths.
    private var presntedNavigationLinkId: Any?
    
    // MARK: Persist old navId to be restored on pop.
    private var prevLinkId: Any? = nil
    
    public init() {}

    public func append<T: NavigaitonValueProtocol>(value: T) {
        paths.append(value.navType)
        pathsTracking.append(value)
    }

    public func popAllPaths() {
        if paths.count > 0 {
            for _ in 0...paths.count - 1 {
                popLastPath()
            }
        }
        pathsTracking.removeAll()
    }

    public func popPathTrackingAt(at index: Int) {
        pathsTracking.remove(at: index)
    }

    public func popLastPathTracking() {
        if !pathsTracking.isEmpty {
            pathsTracking.removeLast()
        }
    }

    public func popLastPath() {
        if !paths.isEmpty {
            paths.removeLast()
        }
    }

    public func remove(innerBack: Bool = false) {
        if pathsTracking.count > 0 {
            popLastPathTracking()
            if innerBack {
                popLastPath()
            } else if pathsTracking.count == 0, paths.count > 0 {
                popLastPath()
            }
        }
    }
}

// Common methods and properties.
public extension NavigationModel {
    var previousItem: Any? {
        if pathsTracking.count > 1 {
            return pathsTracking[pathsTracking.count - 2]
        } else {
            return nil
        }
    }

    var previousTitle: String {
        if let thread = previousItem as? Conversation {
            thread.computedTitle
        } else if let threadVM = previousItem as? ThreadViewModel {
            threadVM.thread.computedTitle
        } else if let detail = previousItem as? ThreadDetailViewModel {
            detail.thread?.title ?? ""
        } else if let detail = previousItem as? ParticipantDetailViewModel {
            detail.participant.name ?? ""
        } else if let navTitle = previousItem as? NavigationTitle {
            navTitle.title
        } else {
            ""
        }
    }

    func clear() {
        animateObjectWillChange()
    }
}

// ThreadViewModel
public extension NavigationModel {
    private var threadsViewModel: ThreadsViewModel? { AppState.shared.objectsContainer.threadsVM }
    private var threadStack: [ConversationNavigationValue] { pathsTracking.compactMap{ $0 as? ConversationNavigationValue } }

    func switchFromThreadList(thread: Conversation) {
        presentedThreadViewModel?.viewModel.cancelAllObservers()
        popAllPaths()
        append(thread: thread)
    }

    func append(thread: Conversation) {
        pushToLinkId(id: "Thread-\(thread.id)")
        let viewModel = viewModel(for: thread.id ?? 0) ?? createViewModel(conversation: thread)
        let value = ConversationNavigationValue(viewModel: viewModel)
        // Pop until the same thread if exist
        popUntilSameConversation(threadId: thread.id ?? 0)
        append(value: value)
        selectedId = thread.id
        // We have to update the object with animateObjectWillChange because inside the ThreadRow we use a chagne listener on this
        animateObjectWillChange()
    }
    
    private func popUntilSameConversation(threadId: Int) {
        if threadStack.contains(where: {$0.threadId == threadId }) {
            if !paths.isEmpty {
                paths.removeLast(paths.count)
                pathsTracking.removeAll()
                detailsStack.removeAll()
            }
        }
    }

    private func createViewModel(conversation: Conversation) -> ThreadViewModel {
       return ThreadViewModel(thread: conversation, threadsViewModel: threadsViewModel)
    }

    var presentedThreadViewModel: ConversationNavigationValue? {
        threadStack.last
    }

    func viewModel(for threadId: Int) -> ThreadViewModel? {
        return threadStack.first(where: {$0.viewModel.id == threadId})?.viewModel
    }

    func setSelectedThreadId() {
        selectedId = threadStack.last?.viewModel.id
        animateObjectWillChange()
    }

    func remove(threadId: Int? = nil) {
        if threadId != nil {
            presentedThreadViewModel?.viewModel.cancelAllObservers()
        }
        remove(innerBack: false)
        if let threadId = threadId, (pathsTracking.last as? ThreadViewModel)?.id == threadId {
            popLastPathTracking()
            popLastPath()
        } else if paths.count > 0 {
            popLastPath()
        }
        setSelectedThreadId()
    }

    func cleanOnPop(threadId: Int) {
        if threadId == presentedThreadViewModel?.threadId {
            presentedThreadViewModel?.viewModel.cancelAllObservers()
        }
        if let detailNavValue = pathsTracking.last as? ConversationDetailNavigationValue, threadId == detailNavValue.threadId {
            popLastPathTracking()
        }
        if threadId == threadStack.last?.viewModel.id {
            popLastPathTracking()
        }
        setSelectedThreadId()
        navigationProperties = .init()
    }
}

// ThreadDetailViewModel
public extension NavigationModel {
    func appendThreadDetail(threadViewModel: ThreadViewModel) {
        let detailViewModel = ThreadDetailViewModel()
        detailViewModel.setup(threadVM: threadViewModel)
        let value = ConversationDetailNavigationValue(viewModel: detailViewModel)
        append(value: value)
        detailsStack.append(detailViewModel)
        selectedId = threadViewModel.id
        animateObjectWillChange()
    }

    func removeDetail() {
        popLastPath()
        popLastPathTracking()
        popLastDetail()
    }
    
    func popLastDetail() {
        if detailsStack.isEmpty { return }
        detailsStack.removeLast()
    }
    
    func detailViewModel(threadId: Int) -> ThreadDetailViewModel? {
        return detailsStack.first(where: {$0.thread?.id == threadId})
    }
}

public extension NavigationModel {
    func updateConversationInViewModel(_ conversation: CalculatedConversation) {
        if let vm = threadStack.first(where: {$0.viewModel.id == conversation.id})?.viewModel {
            vm.updateConversation(conversation.toStruct())
        }
    }
}

public extension NavigationModel {
    func pushToLinkId(id: Any) {
        /// Save current link id
        prevLinkId = presntedNavigationLinkId
        
        presntedNavigationLinkId = id
    }
    
    func popLinkId() {
        /// Restore previous linkId.
        presntedNavigationLinkId = prevLinkId
        
        prevLinkId = nil
    }
    
    func getLinkId() -> Any? {
        return presntedNavigationLinkId
    }
}

//MARK: Create or open an existing thread.

public extension NavigationModel {
    
    public func openThread(contact: Contact) async throws {
        let coreUserId = contact.user?.coreUserId ?? contact.user?.id ?? -1
        navigationProperties.userToCreateThread = contact.toParticipant
        if let conversation = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            append(thread: conversation)
        } else {
            showEmptyThread(userName: nil)
        }
    }
    
    public func openThread(participant: Participant) async throws {
        navigationProperties.userToCreateThread = participant
        guard let coreUserId = participant.coreUserId else { return }
        
        if let conversation = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            append(thread: conversation)
        } else {
            showEmptyThread(userName: participant.username)
        }
    }
    
    public func openThreadWith(userName: String) async throws {
        navigationProperties.userToCreateThread = .init(username: userName)
        
        if let conversation = try await GetThreadsReuqester().get(userName: userName) {
            append(thread: conversation)
        } else {
            showEmptyThread(userName: userName)
        }
    }
    
    /// Forward messages from a thread to a destination thread.
    /// If the conversation is nil it try to use contact. Firstly it opens a conversation using the given contact core user id then send messages to the conversation.
    public func openForwardThread(from: Int, conversation: Conversation, messages: [Message]) {
        let dstId = conversation.id ?? -1
        setupForwardRequest(from: from, to: dstId, messages: messages)
        append(thread: conversation)
    }
    
    public func openForwardThread(from: Int, contact: Contact, messages: [Message]) async throws {
        if let conversation = checkForP2POffline(coreUserId: contact.user?.coreUserId ?? -1) {
            setupForwardRequest(from: from, to: conversation.id ?? -1, messages: messages)
            append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: contact.user?.coreUserId ?? -1) {
            setupForwardRequest(from: from, to: conversation.id ?? -1, messages: messages)
            append(thread: conversation)
        } else {
            let dstId = LocalId.emptyThread.rawValue
            setupForwardRequest(from: from, to: dstId, messages: messages)
            try await openThread(contact: contact)
        }
    }
    
    public func setupForwardRequest(from: Int, to: Int, messages: [Message]) {
        self.navigationProperties.forwardMessages = messages
        let messageIds = messages
            .sorted { $0.time ?? 0 < $1.time ?? 0 }
            .compactMap { $0.id }
        let req = ForwardMessageRequest(fromThreadId: from, threadId: to, messageIds: messageIds)
        navigationProperties.forwardMessageRequest = req
    }
    
    private func checkForP2POffline(coreUserId: Int) -> Conversation? {
        let threads = AppState.shared.objectsContainer.threadsVM.threads + AppState.shared.objectsContainer.archivesVM.archives
        
        return threads.first(where: {
            ($0.partner == coreUserId || ($0.participants?.contains(where: { $0.coreUserId == coreUserId }) ?? false)) &&
            $0.group == false && $0.type == .normal
        }
        )?.toStruct()
    }
    
    private func checkForOffline(threadId: Int) -> Conversation? {
        let threads = AppState.shared.objectsContainer.threadsVM.threads + AppState.shared.objectsContainer.archivesVM.archives
        return threads.first(where: { $0.id == threadId })?.toStruct()
    }
    
    public func showEmptyThread(userName: String? = nil) {
        guard let participant = navigationProperties.userToCreateThread
        else { return }
        let particpants = [participant]
        let conversation = Conversation(
            id: LocalId.emptyThread.rawValue,
            image: participant.image,
            title: participant.name ?? userName,
            participants: particpants)
        append(thread: conversation)
    }
    
    public func openThreadAndMoveToMessage(conversationId: Int, messageId: Int, messageTime: UInt) async throws {
        self.navigationProperties.moveToMessageId = messageId
        self.navigationProperties.moveToMessageTime = messageTime
        
        /// Check if destiation thread is already inside NavigationPath stack,
        /// If it is exist we will pop and remove current Path, to show the viewModel
        if viewModel(for: conversationId) != nil, let currentThreadId = presentedThreadViewModel?.threadId {
            remove(threadId: currentThreadId)
        } else if let conversation = checkForOffline(threadId: conversationId) {
            append(thread: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(.init(threadIds: [conversationId])).first {
            append(thread: conversation)
        }
    }
    
    public func canNavigateToConversation() -> Bool {
        if !twoRowTappedAtSameTime {
            twoRowTappedAtSameTime = true
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                Task { @MainActor [weak self] in
                    self?.twoRowTappedAtSameTime = false
                }
            }
            return true
        }
        return false
    }
}

// MARK: NavigationProperties

public extension NavigationModel {
    func resetNavigationProperties() {
        navigationProperties = .init()
    }
    
    func setParticipantToCreateThread(_ participant: Participant?) {
        navigationProperties.userToCreateThread = nil
    }
    
    func setReplyPrivately(_ replyPrivately: Message?) {
        navigationProperties.replyPrivately = replyPrivately
    }
    
    func updateForwardToThreadId(id: Int) {
        navigationProperties.forwardMessageRequest?.threadId = id
    }
}
