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

@MainActor
public final class MutualGroupViewModel: ObservableObject {
    @Published public private(set) var mutualThreads: ContiguousArray<Conversation> = []
    private var partner: Participant?
    private var cancelable: AnyCancellable?
    public private(set) var lazyList = LazyListViewModel()

    public init() {
        cancelable = NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
    }

    public func setPartner(_ partner: Participant?) {
        self.partner = partner
        if let userName = partner?.username {
            fetchMutualThreads(username: userName)
        }
    }

    public func loadMoreMutualGroups() async {
        if let username = partner?.username, await lazyList.canLoadMore() {
            lazyList.prepareForLoadMore()
            fetchMutualThreads(username: username)
        }
    }

    public func fetchMutualThreads(username: String) {
        guard AppState.shared.objectsContainer.navVM.selectedId != LocalId.emptyThread.rawValue else { return }
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
    }
}
