//
//  ThreadSearchMessagesViewModel.swift
//  
//
//  Created by hamed on 11/27/23.
//

import Foundation
import Chat
import TalkModels
import Combine

@MainActor
public final class ThreadSearchMessagesViewModel: ObservableObject {
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    private var threadId: Int { thread?.id ?? -1 }
    @Published public private(set) var searchedMessages: ContiguousArray<Message> = .init()
    private var cancelable: Set<AnyCancellable> = []
    public var isInSearchMode: Bool = false
    private var offset = 0
    private let count = 50
    @Published public var searchText: String = ""
    private var hasMore = true
    @Published public var isLoading = false
    private var objectId = UUID().uuidString
    private let SEARCH_KEY: String

    public init(){
        SEARCH_KEY = "SEARCH-\(objectId)"
    }

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        setupNotificationObservers()
    }

    public func cancel() {
        NotificationCenter.cancelSearch.post(name: .cancelSearch, object: nil)
        isInSearchMode = false
        searchedMessages.removeAll()
    }

    private func setupNotificationObservers() {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)

        NotificationCenter.cancelSearch.publisher(for: .cancelSearch)
            .sink { [weak self] event in
                self?.reset()
            }
            .store(in: &cancelable)

        $searchText
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.doNewSearch(text: newValue)
            }
            .store(in: &cancelable)

        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    self?.onCancelTimer(key: key)
                }
            }
            .store(in: &cancelable)
    }

    public func doNewSearch(text: String) {
        if text.count < 2 { return }
        searchedMessages.removeAll()
        isInSearchMode = text.count >= 2
        isLoading = true
        offset = 0
        hasMore = true
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, query: "\(text)")
        RequestsManager.shared.append(prepend: SEARCH_KEY, value: req, autoCancel: false)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.history(req)
        }
        animateObjectWillChange()
    }

    public func loadMore() {
        if hasMore {
            self.offset = offset + count
            isLoading = true
            let req = GetHistoryRequest(threadId: threadId, count: count, offset: offset, query: "\(searchText)")
            RequestsManager.shared.append(prepend: SEARCH_KEY, value: req, autoCancel: false)
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.history(req)
            }
        }
        animateObjectWillChange()
    }

    func onSearch(_ response: ChatResponse<[Message]>) {
        if !response.cache, response.pop(prepend: SEARCH_KEY) != nil {
            isLoading = false
            response.result?.forEach { message in
                if !(searchedMessages.contains(where: { $0.id == message.id })) {
                    searchedMessages.append(message)
                }
            }
            if !response.cache, !response.hasNext {
                hasMore = false
            }
            animateObjectWillChange()
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            onSearch(response)
        default:
            break
        }
    }

    private func onCancelTimer(key: String) {
        if isLoading, key.contains(SEARCH_KEY) {
            isLoading = false
        }
    }

    private func reset() {
        searchText = ""
        hasMore = true
        isLoading = false
        isInSearchMode = false
        offset = 0
        searchedMessages.removeAll()
        animateObjectWillChange()
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
