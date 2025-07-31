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
    
    // MARK: - Stored Properties
    
    private weak var threadVM: ThreadViewModel?
    private var cancelable: Set<AnyCancellable> = []
    private var seenPublisher = PassthroughSubject<Message, Never>()
    private var lastInQueue: Int = 0
    
    // MARK: - Computed Properties
    
    private var historyVM: ThreadHistoryViewModel? { threadVM?.historyVM }
    private var thread: Conversation { threadVM?.thread ?? Conversation(id: 0) }
    private var threadId: Int { thread.id ?? 0 }
    private var threadsVM: ThreadsViewModel { threadVM?.threadsViewModel ?? .init() }
    private var archivesVM: ArchiveThreadsViewModel { AppState.shared.objectsContainer.archivesVM }
    private var threads: ContiguousArray<CalculatedConversation> { threadVM?.thread.isArchive == true ? archivesVM.archives : threadsVM.threads }
    private var isAppActive: Bool { AppState.shared.lifeCycleState == .active || AppState.shared.lifeCycleState == .foreground }
    private var currentUserId: Int? { AppState.shared.user?.id }
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - Setup
    
    public func setup(viewModel: ThreadViewModel) {
        self.threadVM = viewModel
        
        seenPublisher
            .filter { $0.id ?? 0 > 0 } // Prevent send -1/-2/-3 or LocalId rows UI Elements as seen message.
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.sendSeen(for: newValue)
            }
            .store(in: &cancelable)
        
        setupOnSceneBecomeActiveObserver()
    }
    
    private func setupOnSceneBecomeActiveObserver() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(onSceneBecomeActive(_:)), name: UIScene.willEnterForegroundNotification, object: nil)
        }
    }
    
    // MARK: - Appearance
    
    internal func onAppear(_ message: HistoryMessageType) async {
        if await !canReduce(for: message) {
            log("Can't reduce message: \(message.message ?? "") Type: \(message.type ?? .unknown) id: \(message.id ?? 0)")
            return
        }
        
        await reduceUnreadCountLocally(message)
        
        if message.id ?? 0 >= lastInQueue, let message = message as? Message {
            lastInQueue = message.id ?? 0
            seenPublisher.send(message)
            log("Send Seen to publisher queue for message: \(message.message ?? "") Type: \(message.type ?? .unknown) id: \(message.id ?? 0)")
        }
    }
    
    // MARK: - Message Handling
    
    private func canReduce(for message: HistoryMessageType) async -> Bool {
        return await hasUnreadAndLastMessageIsBiggerLastSeen(messageId: message.id)
    }
    
    private func hasUnreadAndLastMessageIsBiggerLastSeen(messageId: Int?) -> Bool {
        if unreadCount() == 0 { return false }
        if messageId == LocalId.unreadMessageBanner.rawValue { return false }
        return (messageId ?? 0) > lastSeenMessageId()
    }
    
    /// We reduce it locally to keep the UI Sync and user feels it really read the message.
    /// However, we only send seen request with debouncing.
    private func reduceUnreadCountLocally(_ message: HistoryMessageType) async {
        if let newUnreadCount = newLocalUnreadCount(for: message) {
            await setUnreadCount(newUnreadCount: newUnreadCount)
            log("Reduced locally to: \(newUnreadCount)")
        } else {
            log("Can't reduce locally")
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
        guard shouldSendSeen(for: message) else { return }
        
        if let messageId = message.id {
            setLastSeenMessageId(messageId: messageId)
            let threadId = self.threadId
            
            Task { @ChatGlobalActor in
                await log("send seen for message:\(message.messageTitle) with id:\(messageId)")
                await ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
            }
        }
    }
    
    internal func sendSeenForAllUnreadMessages() {
        if let message = thread.lastMessageVO,
           (message.seen == nil || message.seen == false),
           message.participant?.id != currentUserId,
           unreadCount() > 0
        {
            sendSeen(for: message.toMessage)
        }
    }
    
    // MARK: - State Management
    
    private func unreadCount() -> Int {
        return threads.first(where: { $0.id == threadId })?.unreadCount ?? 0
    }
    
    private func setUnreadCount(newUnreadCount: Int) async {
        threadVM?.thread.unreadCount = newUnreadCount
        
        if let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].unreadCount = newUnreadCount
            await ThreadCalculators.reCalculateUnreadCount(threads[index])
            threads[index].animateObjectWillChange()
        }
        
        threadVM?.delegate?.onUnreadCountChanged()
    }
    
    private func lastSeenMessageId() -> Int {
        return threads.first(where: { $0.id == threadId })?.lastSeenMessageId ?? 0
    }
    
    private func setLastSeenMessageId(messageId: Int) {
        threadVM?.thread.lastSeenMessageId = messageId
        
        if let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].lastSeenMessageId = messageId
        }
    }
    
    // MARK: - Helpers
    
    private func shouldSendSeen(for message: Message) -> Bool {
        guard let messageId = message.id else { return false }
        let isMe = message.isMe(currentUserId: currentUserId)
        return !isMe && isAppActive
    }
    
    @available(iOS 13.0, *)
    @objc private func onSceneBecomeActive(_: Notification) {
        let hasLastMessageSeen = thread.lastMessageVO?.id != lastSeenMessageId()
        let lastMessage = thread.lastMessageVO
        
        Task { [weak self] in
            let isAtEndOfTheList = self?.threadVM?.scrollVM.isAtBottomOfTheList == true
            
            if isAtEndOfTheList, hasLastMessageSeen, let lastMessage = lastMessage {
                self?.sendSeen(for: lastMessage.toMessage)
            }
        }
    }
    
    private func log(_ string: String) {
        Logger.log(title: "HistorySeenViewModel", message: string)
    }
}
