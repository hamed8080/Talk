import Chat
import SwiftUI
import TalkModels
import ChatModels
import ChatCore

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
        pathsTracking.removeLast()
    }

    public func popLastPath() {
        paths.removeLast()
    }

    public func remove() {
        if pathsTracking.count > 0 {
            popLastPathTracking()
            if pathsTracking.count == 0, paths.count > 0 {
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
        let viewModel = viewModel(for: thread.id ?? 0) ?? createViewModel(conversation: thread)
        viewModel.historyVM.created = created
        let value = ConversationNavigationValue(viewModel: viewModel)
        append(value: value)
        selectedId = thread.id
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
    }

    func remove(threadId: Int? = nil) {
        if threadId != nil {
            presentedThreadViewModel?.viewModel.cancelAllObservers()
        }
        remove()
        if let threadId = threadId, (pathsTracking.last as? ThreadViewModel)?.threadId == threadId {
            popLastPathTracking()
            popLastPath()
        }
        setSelectedThreadId()
    }
}

// ThreadDetailViewModel
public extension NavigationModel {
    func appendThreadDetail(threadViewModel: ThreadViewModel? = nil, paricipant: Participant? = nil) {
        let detailViewModel = AppState.shared.objectsContainer.threadDetailVM
        if let participant = paricipant {
            detailViewModel.setup(participant: participant)
        } else {
            detailViewModel.setup(thread: threadViewModel?.thread, threadVM: threadViewModel)
        }
        let value = ConversationDetailNavigationValue(viewModel: detailViewModel)
        append(value: value)
        selectedId = threadViewModel?.threadId
    }
}


public extension NavigationModel {
    func updateConversationInViewModel(_ conversation: Conversation) {
        if let vm = threadStack.first(where: {$0.viewModel.threadId == conversation.id})?.viewModel {
            vm.updateConversation(conversation)
        }
    }
}
