import Chat
import SwiftUI
import TalkModels

@MainActor
public final class NavigationModel: ObservableObject {
    @Published public var selectedId: Int?
    @Published public var paths = NavigationPath()
    var pathsTracking: [Any] = []
    var detailsStack: [ThreadDetailViewModel] = []
    
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
        AppState.shared.appStateNavigationModel = .init()
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
