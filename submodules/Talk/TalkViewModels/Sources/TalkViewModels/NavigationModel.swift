import Chat
import SwiftUI
import TalkModels

@MainActor
public final class NavigationModel: ObservableObject {
    @Published public var selectedId: Int?
    @Published public var paths = NavigationPath()
    var pathsTracking: [Any] = []
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
            return thread.computedTitle
        } else if let threadVM = previousItem as? ThreadViewModel {
            return threadVM.thread.computedTitle
        } else if let detail = previousItem as? ThreadDetailViewModel {
            return detail.thread?.title ?? ""
        } else if let detail = previousItem as? ParticipantDetailViewModel {
            return detail.participant.name ?? ""
        } else if let navTitle = previousItem as? NavigationTitle {
            return navTitle.title
        } else {
            return ""
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

    func append(thread: Conversation, created: Bool = false) {
        Task { @MainActor in
            let viewModel = viewModel(for: thread.id ?? 0) ?? createViewModel(conversation: thread)
            Task { @HistoryActor in
                await viewModel.historyVM.setCreated(created) 
            }
            let value = ConversationNavigationValue(viewModel: viewModel)
            append(value: value)
            selectedId = thread.id
            // We have to update the object with animateObjectWillChange because inside the ThreadRow we use a chagne listener on this
            animateObjectWillChange()
        }
    }

    private func createViewModel(conversation: Conversation) -> ThreadViewModel {
       return ThreadViewModel(thread: conversation, threadsViewModel: threadsViewModel)
    }

    var presentedThreadViewModel: ConversationNavigationValue? {
        threadStack.last
    }

    func viewModel(for threadId: Int) -> ThreadViewModel? {
        return threadStack.first(where: {$0.viewModel.threadId == threadId})?.viewModel
    }

    func setSelectedThreadId() {
        selectedId = threadStack.last?.viewModel.threadId
        animateObjectWillChange()
    }

    func remove(threadId: Int? = nil) {
        if threadId != nil {
            presentedThreadViewModel?.viewModel.cancelAllObservers()
        }
        remove(innerBack: false)
        if let threadId = threadId, (pathsTracking.last as? ThreadViewModel)?.threadId == threadId {
            popLastPathTracking()
            popLastPath()
        } else if paths.count > 0 {
            popLastPath()
        }
        setSelectedThreadId()
    }

    func cleanOnPop(threadId: Int? = nil) {
        if threadId != nil {
            presentedThreadViewModel?.viewModel.cancelAllObservers()
        }
        popLastPathTracking()
        setSelectedThreadId()
    }
}

// ThreadDetailViewModel
public extension NavigationModel {
    func appendThreadDetail(threadViewModel: ThreadViewModel) {
        let detailViewModel = AppState.shared.objectsContainer.threadDetailVM
        detailViewModel.setup(thread: threadViewModel.thread, threadVM: threadViewModel)
        let value = ConversationDetailNavigationValue(viewModel: detailViewModel)
        append(value: value)
        selectedId = threadViewModel.threadId
        animateObjectWillChange()
    }

    func removeDetail() {
        popLastPath()
        popLastPathTracking()
    }
}

public extension NavigationModel {
    func updateConversationInViewModel(_ conversation: CalculatedConversation) {
        if let vm = threadStack.first(where: {$0.viewModel.threadId == conversation.id})?.viewModel {
            vm.updateConversation(conversation.toStruct())
        }
    }
}
