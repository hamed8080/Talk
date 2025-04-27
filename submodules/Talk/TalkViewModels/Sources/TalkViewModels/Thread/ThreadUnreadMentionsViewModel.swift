//
//  ThreadUnreadMentionsViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine

@MainActor
public final class ThreadUnreadMentionsViewModel {
    private weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    public private(set) var unreadMentions: ContiguousArray<Message> = .init()
    private var cancelable: Set<AnyCancellable> = []
    public private(set) var hasMention: Bool = false
    private var objectId = UUID().uuidString
    private let UNREAD_MENTIONS_KEY: String

    public init(){
        UNREAD_MENTIONS_KEY = "UNREAD-MENTIONS-\(objectId)"
    }

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        hasMention = thread?.mentioned == true
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
    }

    @HistoryActor
    public func scrollToMentionedMessage() async {
        await viewModel?.scrollVM.scrollingUP = false//open sending unread counts if we scrolled up and there is a new messge where we have mentiond
        await viewModel?.moveToFirstUnreadMessage()
    }

    public func fetchAllUnreadMentions() {
        guard let threadId = thread?.id else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 25, offset: 0, order: "desc", unreadMentioned: true)
        RequestsManager.shared.append(prepend: UNREAD_MENTIONS_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.history(req)
        }
    }

    public func setAsRead(id: Int?) {
        unreadMentions.removeAll(where: { $0.id == id })
        if unreadMentions.isEmpty {
            hasMention = false
            viewModel?.thread.mentioned = false
            viewModel?.delegate?.onChangeUnreadMentions()
        }
    }

    func onUnreadMentions(_ response: ChatResponse<[Message]>) {
        guard
            let newuUnreadMentions = response.result,
            response.subjectId == thread?.id,
            !response.cache
        else { return }
        if response.pop(prepend: UNREAD_MENTIONS_KEY) != nil {
            unreadMentions.removeAll()
            unreadMentions.append(contentsOf: newuUnreadMentions)
            unreadMentions.sort(by: {$0.time ?? 0 < $1.time ?? 1})
            viewModel?.delegate?.onChangeUnreadMentions()
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            onUnreadMentions(response)
        case .new(let response):
            onNewMesssage(response)
        default:
            break
        }
    }

    private func onNewMesssage(_ response: ChatResponse<Message>) {
        guard let message = response.result else { return }
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id ?? -1) == true
        if response.subjectId == thread?.id, !isMe, message.mentioned == true {
            unreadMentions.append(message)
            hasMention = true
            viewModel?.delegate?.onChangeUnreadMentions()
        }
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
