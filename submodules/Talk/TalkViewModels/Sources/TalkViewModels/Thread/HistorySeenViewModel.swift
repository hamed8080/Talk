//
//  HistorySeenViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import Logger
import Chat
import TalkModels
import UIKit

@MainActor
public final class HistorySeenViewModel {
    private weak var threadVM: ThreadViewModel?
    private var historyVM: ThreadHistoryViewModel? { threadVM?.historyVM }
    private var seenPublisher = PassthroughSubject<Message, Never>()
    private var cancelable: Set<AnyCancellable> = []
    private var thread: Conversation { threadVM?.thread ?? Conversation(id: 0) }
    private var threadId: Int { thread.id ?? 0 }
    private var threadsVM: ThreadsViewModel { threadVM?.threadsViewModel ?? .init() }
    private var archivesVM: ArchiveThreadsViewModel { AppState.shared.objectsContainer.archivesVM }
    private var lastInQueue: Int = 0
    private var threads: ContiguousArray<CalculatedConversation> { threadVM?.thread.isArchive == true ? archivesVM.archives : threadsVM.threads }
    
    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.threadVM = viewModel
        seenPublisher
            .filter{$0.id ?? 0 > 0} // Prevent send -1/-2/-3 UI Elements as seen message.
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.sendSeen(for: newValue)
            }
            .store(in: &cancelable)
        setupOnSceneBecomeActiveObserver()
    }

    internal func onAppear(_ message: HistoryMessageType) async {
        logSeen("OnAppear message: \(message.message ?? "") Type: \(message.type ?? .unknown) id: \(message.id ?? 0)")
        if await !canReduce(for: message) {
            logSeen("Can't reduce message: \(message.message ?? "") Type: \(message.type ?? .unknown) id: \(message.id ?? 0)")
            return
        }
        await logMessageApperance(message, appeard: true, isUp: false)
        await reduceUnreadCountLocaly(message)
        if message.id ?? 0 >= lastInQueue, let message = message as? Message {
            lastInQueue = message.id ?? 0
            seenPublisher.send(message)
            logSeen("Send Seen to publisher queue for message: \(message.message ?? "") Type: \(message.type ?? .unknown) id: \(message.id ?? 0)")
        }
    }

    /// We use isProgramaticallyScroll false to only not sending scrolling up when the user really scrolling
    /// If we don't do that it will result in not sending seen for threads with messages lower than 10, on opening the thread.
    private func canReduce(for message: HistoryMessageType) async -> Bool {
        if await scrollupAndNotPorgramatically() { return false }
        return await hasUnreadAndLastMessageIsBiggerLastSeen(messageId: message.id)
    }
    
    private func hasUnreadAndLastMessageIsBiggerLastSeen(messageId: Int?) -> Bool {
        if unreadCount() == 0 { return false }
        if messageId == LocalId.unreadMessageBanner.rawValue { return false }
        return messageId ?? 0 > lastSeenMessageId()
    }
    
    private func scrollupAndNotPorgramatically() async -> Bool {
        let scrollingUP = await threadVM?.scrollVM.scrollingUP == true
        let isProgramaticallyScroll = await threadVM?.scrollVM.getIsProgramaticallyScrollingHistoryActor() == true
        let result = scrollingUP && !isProgramaticallyScroll
        await logSeen("Scrolling up: \(scrollingUP) isProgramaticallyScroll: \(isProgramaticallyScroll)")
        return result
    }

    /// We reduce it locally to keep the UI Sync and user feels it really read the message.
    /// However, we only send seen request with debouncing
    private func reduceUnreadCountLocaly(_ message: HistoryMessageType) async {
        if let newUnreadCount = newLocalUnreadCount(for: message) {
            await setUnreadCount(newUnreadCount: newUnreadCount)
            logSeen("Reduced localy to: \(newUnreadCount)")
        } else {
            logSeen("Can't Reduced localy")
        }
    }

    private func newLocalUnreadCount(for message: HistoryMessageType) -> Int? {
        let messageId = message.id ?? -1
        let currentUnreadCount = unreadCount()
        if currentUnreadCount > 0, messageId >= thread.lastSeenMessageId ?? 0 {
            let newUnreadCount = currentUnreadCount - 1
            return newUnreadCount
        }
        return nil
    }

    private func sendSeen(for message: Message) {
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        if let messageId = message.id, !isMe, AppState.shared.lifeCycleState == .active || AppState.shared.lifeCycleState == .foreground {
            setLastSeenMessageId(messageId: messageId)
            Task {
                await log("send seen for message:\(message.messageTitle) with id:\(messageId)")
            }
            let threadId = threadId
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
            }
        }
    }

    internal func sendSeenForAllUnreadMessages() {
        if let message = thread.lastMessageVO,
           message.seen == nil || message.seen == false,
           message.participant?.id != AppState.shared.user?.id,
           unreadCount() > 0
        {
            sendSeen(for: message.toMessage)
        }
    }

    private func setupOnSceneBecomeActiveObserver() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(onSceneBeomeActive(_:)), name: UIScene.willEnterForegroundNotification, object: nil)
        }
    }

    @available(iOS 13.0, *)
    @objc private func onSceneBeomeActive(_: Notification) {
        let hasLastMeesageSeen = thread.lastMessageVO?.id != lastSeenMessageId()
        let lastMessage = thread.lastMessageVO
        Task { [weak self] in
            let isAtEndOfTleList = self?.threadVM?.scrollVM.isAtBottomOfTheList == true
            if isAtEndOfTleList, hasLastMeesageSeen, let lastMessage = lastMessage {
                self?.sendSeen(for: lastMessage.toMessage)
            }
        }
    }
    
    /// We have to use this as a source of truth for unread count.
    /// That's beacuse the ThreadViewModel.thread instance is different than ThreadsViewModel[index].instance
    private func unreadCount() -> Int {
        return threads.first(where: {$0.id == threadId})?.unreadCount ?? 0
    }
    
    private func setUnreadCount(newUnreadCount: Int) async {
        threadVM?.thread.unreadCount = newUnreadCount
        if let index = threads.firstIndex(where: {$0.id == threadId}) {
            threads[index].unreadCount = newUnreadCount
            await ThreadCalculators.reCalculateUnreadCount(threads[index])
            threads[index].animateObjectWillChange()
        }
        threadVM?.delegate?.onUnreadCountChanged()
    }
    
    private func lastSeenMessageId() -> Int {
        return threads.first(where: {$0.id == threadId})?.lastSeenMessageId ?? 0
    }
    
    private func setLastSeenMessageId(messageId: Int) {
        threadVM?.thread.lastSeenMessageId = messageId
        if let index = threads.firstIndex(where: { $0.id == threadId ?? -1 }) {
            threads[index].lastSeenMessageId = messageId
        }
    }

    @AppBackgroundActor
    private func logMessageApperance(_ message: HistoryMessageType, appeard: Bool, isUp: Bool? = nil) {
#if DEBUG
        let dir = isUp == true ? "UP" : (isUp == false ? "DOWN" : "")
        let messageId = message.id ?? 0
        let uniqueId = message.uniqueId ?? ""
        let text = message.message ?? ""
        let time = message.time ?? 0
        let appeardText = appeard ? "appeared" : "disappeared"
        let detailedText = "id: \(messageId) uniqueId: \(uniqueId) message: \(text) time: \(time)"
        if isUp != nil {
            log("On message \(appeardText) when scrolling \(dir), \(detailedText)")
        } else {
            log("On message \(appeardText) with \(detailedText)")
        }
#endif
    }

    @AppBackgroundActor
    private func log(_ string: String) {
        Logger.log( title: "HistorySeenViewModel", message: string)
    }
    
    private func logSeen(_ string: String) {
        Logger.log( title: "HistorySeenViewModel", message: string)
    }
}
