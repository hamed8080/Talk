//
//  MutualGroupViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import Combine
import TalkModels
import UIKit

public enum MutualGroupItem: Hashable, Sendable {
    case conversation(Conversation)
    case noResult
}

public enum MutualGroupsListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UIMutualGroupsViewControllerDelegate: AnyObject {
    func apply(snapshot: NSDiffableDataSourceSnapshot<MutualGroupsListSection, MutualGroupItem>, animatingDifferences: Bool)
    func updateImage(image: UIImage?, id: Int)
}

@MainActor
public final class MutualGroupViewModel {
    public private(set) var mutualThreads: ContiguousArray<Conversation> = []
    public private(set) var avatars: [Int: ImageLoaderViewModel] = [:]
    private var partner: Participant?
    private var cancelable: AnyCancellable?
    public weak var delegate: UIMutualGroupsViewControllerDelegate?
    public private(set) var lazyList = LazyListViewModel()
    private var isCompleted = false

    public init() {
        cancelable = NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
    }
    
    public func updateUI(animation: Bool, reloadSections: Bool) {
        /// Create
        var snapshot = NSDiffableDataSourceSnapshot<MutualGroupsListSection, MutualGroupItem>()
        
        /// Configure
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(mutualThreads).compactMap({ MutualGroupItem.conversation($0) }), toSection: .main)
        if reloadSections {
            snapshot.reloadSections([.main])
        }
        
        if mutualThreads.isEmpty && !lazyList.isLoading {
            snapshot.appendSections([.noResult])
            snapshot.appendItems([MutualGroupItem.noResult], toSection: .noResult)
        }
        
        /// Apply
        Task { @AppBackgroundActor in
            await MainActor.run {
                delegate?.apply(snapshot: snapshot, animatingDifferences: animation)
            }
        }
    }

    public func setPartner(_ partner: Participant?) {
        self.partner = partner
    }

    public func loadMoreMutualGroups() async {
        if let username = partner?.username, await lazyList.canLoadMore() {
            lazyList.prepareForLoadMore()
            fetchMutualThreads()
        }
    }

    public func fetchMutualThreads() {
        guard let username = partner?.username, AppState.shared.objectsContainer.navVM.selectedId != LocalId.emptyThread.rawValue else { return }
        lazyList.setLoading(true)
        let invitee = Invitee(id: "\(username)", idType: .username)
        let req = MutualGroupsRequest(toBeUser: invitee, count: lazyList.count, offset: lazyList.offset)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.mutual(req)
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .mutual(let chatResponse):
            onMutual(chatResponse)
        default:
            break
        }
    }

    private func onMutual(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            lazyList.setLoading(false)
            lazyList.setHasNext(response.hasNext)
            for (_, thread) in threads.enumerated() {
                if !self.mutualThreads.contains(where: {$0.id == thread.id}) {
                    mutualThreads.append(thread)
                }
            }
        }
        updateUI(animation: false, reloadSections: false)
    }
}
