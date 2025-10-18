//
//  ThreadScrollingViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Chat
import Foundation
import UIKit
import TalkModels

public actor DeceleratingBackgroundActor {}

@globalActor public actor DeceleratingActor: GlobalActor {
    public static var shared = DeceleratingBackgroundActor()
}

@MainActor
public final class ThreadScrollingViewModel {
    var task: Task<(), Never>?
    private var isProgramaticallyScroll: Bool = false
    public var scrollingUP = false
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init(id: -1)}
    public var isAtBottomOfTheList: Bool = false
    public var lastContentOffsetY: CGFloat = 0
    public var didEndScrollingAnimation = true
    @DeceleratingActor public var isEndedDecelerating: Bool = true
    init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        isAtBottomOfTheList = thread.lastMessageVO?.id == thread.lastSeenMessageId || thread.lastSeenMessageId ?? 0 > thread.lastMessageVO?.id ?? 0
    }

    private func scrollTo(_ uniqueId: String, messageId: Int, position: UITableView.ScrollPosition = .bottom, animate: Bool) {
        viewModel?.historyVM.delegate?.scrollTo(uniqueId: uniqueId, messageId: messageId, position: position, animate: animate)
    }

    public func scrollToBottom() {
        let task: Task<Void, any Error> = Task { [weak self] in
            guard let self = self else { return }
            if let messageId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
                AppState.shared.objectsContainer.threadsVM.saveScrollPositionVM.remove(thread.id ?? -1)
                await viewModel?.historyVM.moveToTime(time, messageId, highlight: false, moveToBottom: true)
            }
        }
        viewModel?.historyVM.setTask(task)
    }

    public func scrollToNewMessageIfIsAtBottomOrMe(_ message: HistoryMessageType) {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            if !didEndScrollingAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.scrollTo(uniqueId, messageId: message.id ?? -1, animate: true)
                }
            } else {
                scrollTo(uniqueId, messageId: message.id ?? -1, animate: true)
            }
            isAtBottomOfTheList = true
            viewModel?.delegate?.showMoveToBottom(show: false)
        }
    }

    public func scrollToLastMessageOnlyIfIsAtBottom() {
        let message = lastMessageOrLastUploadingMessage()
        if isAtBottomOfTheList, let uniqueId = message?.uniqueId {
            disableExcessiveLoading()
            scrollTo(uniqueId, messageId: message?.id ?? -1, animate: true)
        }
    }

    public func lastMessageOrLastUploadingMessage() -> HistoryMessageType? {
        let lastUploadElement = AppState.shared.objectsContainer.uploadsManager.lastUploadingMessage(threadId: viewModel?.id ?? -1)
        if let lastUploadElement = lastUploadElement {
            return lastUploadElement.viewModel.message
        } else {
            return viewModel?.thread.lastMessageVO?.toMessage
        }
    }

    public func scrollToLastUploadedMessageWith(_ indexPath: IndexPath) {
        disableExcessiveLoading()
        viewModel?.delegate?.scrollTo(index: indexPath, position: .top, animate: true)
    }
    
    public func disableExcessiveLoading() {
        task = Task.detached { [weak self] in
            await self?.setIsProgramaticallyScrolling(true)
            try? await Task.sleep(for: .seconds(1))
            await self?.setIsProgramaticallyScrolling(false)
        }
    }

    public func setIsProgramaticallyScrolling(_ newValue: Bool) {
        self.isProgramaticallyScroll = newValue
    }
    
    public func cancelExessiveLoading() {
        task?.cancel()
        task = nil
    }
    
    @MainActor
    public func getIsProgramaticallyScrolling() -> Bool {
        return isProgramaticallyScroll
    }
    
    public func getIsProgramaticallyScrollingHistoryActor() async -> Bool {
        let isProgramaticallyScroll = await isProgramaticallyScroll
        return isProgramaticallyScroll
    }

    public func cancelTask() {
        task?.cancel()
        task = nil
    }
}
