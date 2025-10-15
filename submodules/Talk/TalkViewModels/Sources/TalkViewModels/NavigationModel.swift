import Chat
import SwiftUI
import TalkModels

@MainActor
public final class NavigationModel: ObservableObject {
    /// This is the SplitViewController or the root vc of the applicaiton
    public weak var rootVC: UIViewController?
    @Published public var selectedId: Int?
    var pathsTracking: [Any] = []
    var detailsStack: [ThreadDetailViewModel] = []
    public private(set) var navigationProperties: NavigationProperties = .init()
    public var twoRowTappedAtSameTime = false
    private var splitVC: UISplitViewController? { rootVC as? UISplitViewController }
    private var navigationController: UINavigationController? { splitVC?.viewControllers.first as? UINavigationController }
    
    /// Once we navigate to a view with NavigationLink in SwiftUI
    /// insted of appending to the paths.
    private var presntedNavigationLinkId: Any?
    
    // MARK: Persist old navId to be restored on pop.
    private var prevLinkId: Any? = nil
    
    public init() {}

    public func wrapAndPush<T: View>(view: T) {
        let container = AppState.shared.objectsContainer!
        let injected = view.injectAllObjects()
        let vc = UIHostingController(rootView: injected)
        appendUIKit(value: vc)
    }
    
    public func appendUIKit<T: UIViewController>(value: T) {
        // Check if container is iPhone navigation controller or iPad split view container or on iPadOS we are in a narrow window
        if splitVC?.isCollapsed == true {
            // iPhone — push onto the existing navigation stack
            navigationController?.pushViewController(value, animated: true)
            pathsTracking.append(value)
        } else {
            // iPad — show in secondary column
            if (splitVC?.viewController(for: .secondary) as? UINavigationController)?.viewControllers.count ?? 0 >= 1 {
                (splitVC?.viewController(for: .secondary) as? UINavigationController)?.pushViewController(value, animated: true)
                pathsTracking.append(value)
            } else {
                splitVC?.showDetailViewController(value, sender: nil)
                pathsTracking.append(value)
                
                if let nav = splitVC?.viewController(for: .secondary) {
                    nav.navigationController?.setNavigationBarHidden(true, animated: false)
                }
            }
        }
    }

    public func popAllPaths() {
        pathsTracking.removeAll()
    }
    
    public func popAllPathsUIKit() {
        
        // iPhone (collapsed)
        // on iPhone PrimaryTabBarViewController is the root view controller of the navigation stack,
        // and thread view controller is the second view controller of the navigation stack,
        // So as long as we are in thread view controller, the number of view controllers inside the stack is greater than 1.
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        }
        // iPad (side-by-side)
        else if let splitVC = splitVC {
            splitVC.setViewController(nil, for: .secondary)
        }
    }

    public func popPathTrackingAt(at index: Int) {
        pathsTracking.remove(at: index)
    }

    public func popLastPathTracking() {
        if !pathsTracking.isEmpty {
            pathsTracking.removeLast()
        }
    }

    public func removeUIKit() {
        if splitVC?.isCollapsed == false, let nav = splitVC?.viewController(for: .secondary) as? UINavigationController {
            nav.popViewController(animated: true)
        } else if splitVC?.isCollapsed == false, let nav = splitVC?.viewController(for: .secondary)?.navigationController {
            nav.popViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
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
        } else if let navTitle = previousItem as? NavigationTitleProtocol {
            navTitle.navigationTitle
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
    private var threadStack: [ConversationNavigationProtocol] {
        pathsTracking.compactMap{ $0 as? ConversationNavigationProtocol }
    }
    
    func switchFromThreadListUIKit(viewController: UIViewController, conversation: Conversation) {
        presentedThreadViewModel?.viewModel?.cancelAllObservers()
        popAllPathsUIKit()
        appendUIKit(vc: viewController, conversation: conversation)
    }
    
    func appendUIKit(vc: UIViewController, conversation: Conversation) {
        pushToLinkId(id: "Thread-\(conversation.id)")
        // Pop until the same thread if exist
        popUntilSameConversation(threadId: conversation.id ?? 0)
        appendUIKit(value: vc)
        selectedId = conversation.id
        // We have to update the object with animateObjectWillChange because inside the ThreadRow we use a chagne listener on this
        animateObjectWillChange()
    }
    
    func createAndAppend(conversation: Conversation) {
        if let vc = AppState.shared.objectsContainer.threadsVM.delegate?.createThreadViewController(conversation: conversation) {
            appendUIKit(vc: vc, conversation: conversation)
        }
    }
    
    func popCurrentViewController(id: Int) {
        if AppState.shared.objectsContainer.threadsVM.threads.contains(where: { $0.id == id && $0.isSelected == true }) {
            AppState.shared.objectsContainer.threadsVM.deselectActiveThread()
        }
        
        if AppState.shared.objectsContainer.archivesVM.archives.contains(where: { $0.id == id && $0.isSelected == true }) {
            AppState.shared.objectsContainer.archivesVM.deselectActiveThread()
        }
        // iPhone (collapsed)
        // on iPhone PrimaryTabBarViewController is the root view controller of the navigation stack,
        // and thread view controller is the second view controller of the navigation stack,
        // So as long as we are in thread view controller, the number of view controllers inside the stack is greater than 1.
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        }
        // iPad (side-by-side)
        else if let splitVC = splitVC {
            splitVC.setViewController(nil, for: .secondary)
        }
    }
    
    private func popUntilSameConversation(threadId: Int) {
        if threadStack.contains(where: { $0.viewModel?.thread.id == threadId }) {
            if !pathsTracking.isEmpty {
                pathsTracking.removeAll()
                detailsStack.removeAll()
            }
        }
    }

    var presentedThreadViewModel: ConversationNavigationProtocol? {
        threadStack.last
    }

    func viewModel(for threadId: Int) -> ThreadViewModel? {
        return threadStack.first(where: { $0.threadId == threadId})?.viewModel
    }

    func setSelectedThreadId() {
        selectedId = threadStack.last?.threadId
        animateObjectWillChange()
    }

    func remove(threadId: Int? = nil) {
        if threadId != nil {
            presentedThreadViewModel?.viewModel?.cancelAllObservers()
        }
        removeUIKit()
        if let threadId = threadId, (pathsTracking.last as? ThreadViewModel)?.id == threadId {
            popLastPathTracking()
        }
        setSelectedThreadId()
    }

    func cleanOnPop(threadId: Int) {
        if threadId == presentedThreadViewModel?.viewModel?.thread.id {
            presentedThreadViewModel?.viewModel?.cancelAllObservers()
        }
        if let detailNavValue = pathsTracking.last as? ConversationDetailNavigationProtocol, threadId == detailNavValue.threadId {
            popLastPathTracking()
        }
        if threadId == threadStack.last?.threadId {
            popLastPathTracking()
        }
        setSelectedThreadId()
        navigationProperties = .init()
    }
}

// ThreadDetailViewModel
public extension NavigationModel {
    func appendThreadDetailUIKit(vc: UIViewController,
                                 navigationController: UINavigationController?,
                                 conversationId: Int,
                                 detailViewModel: ThreadDetailViewModel
    ) {
        // iPad — Push to navigation controller instead of replacing the whole secondary view controller in split view controller
        navigationController?.pushViewController(vc, animated: true)
        detailsStack.append(detailViewModel)
        selectedId = conversationId
        animateObjectWillChange()
    }

    func removeDetail(id: Int) {
        popLastPathTracking()
        popLastDetail()
        
        removeUIKit()
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
        if let vm = threadStack.first(where: { $0.threadId == conversation.id })?.viewModel {
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
            createAndAppend(conversation: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            createAndAppend(conversation: conversation)
        } else {
            showEmptyThread(userName: nil)
        }
    }
    
    public func openThread(participant: Participant) async throws {
        navigationProperties.userToCreateThread = participant
        guard let coreUserId = participant.coreUserId else { return }
        
        if let conversation = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            createAndAppend(conversation: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: coreUserId) {
            createAndAppend(conversation: conversation)
        } else {
            showEmptyThread(userName: participant.username)
        }
    }
    
    public func openThreadWith(userName: String) async throws {
        navigationProperties.userToCreateThread = .init(username: userName)
        
        if let conversation = try await GetThreadsReuqester().get(userName: userName) {
            createAndAppend(conversation: conversation)
        } else {
            showEmptyThread(userName: userName)
        }
    }
    
    /// Forward messages from a thread to a destination thread.
    /// If the conversation is nil it try to use contact. Firstly it opens a conversation using the given contact core user id then send messages to the conversation.
    public func openForwardThread(from: Int, conversation: Conversation, messages: [Message]) {
        let dstId = conversation.id ?? -1
        setupForwardRequest(from: from, to: dstId, messages: messages)
        createAndAppend(conversation: conversation)
    }
    
    public func openForwardThread(from: Int, contact: Contact, messages: [Message]) async throws {
        if let conversation = checkForP2POffline(coreUserId: contact.user?.coreUserId ?? -1) {
            setupForwardRequest(from: from, to: conversation.id ?? -1, messages: messages)
            createAndAppend(conversation: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(coreUserId: contact.user?.coreUserId ?? -1) {
            setupForwardRequest(from: from, to: conversation.id ?? -1, messages: messages)
            createAndAppend(conversation: conversation)
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
        createAndAppend(conversation: conversation)
    }
    
    public func openThreadAndMoveToMessage(conversationId: Int, messageId: Int, messageTime: UInt) async throws {
        self.navigationProperties.moveToMessageId = messageId
        self.navigationProperties.moveToMessageTime = messageTime
        
        /// Check if destiation thread is already inside NavigationPath stack,
        /// If it is exist we will pop and remove current Path, to show the viewModel
        if viewModel(for: conversationId) != nil, let currentThreadId = presentedThreadViewModel?.threadId {
            remove(threadId: currentThreadId)
        } else if let conversation = checkForOffline(threadId: conversationId) {
            createAndAppend(conversation: conversation)
        } else if let conversation = try await GetThreadsReuqester().get(.init(threadIds: [conversationId])).first {
            createAndAppend(conversation: conversation)
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
