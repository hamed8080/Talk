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

@MainActor
public final class ThreadScrollingViewModel {
    var task: Task<(), Never>?
    private var isProgramaticallyScroll: Bool = false
    public var scrollingUP = false
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init(id: -1)}
    public var isAtBottomOfTheList: Bool = false
    public var lastContentOffsetY: CGFloat = 0
    init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        isAtBottomOfTheList = thread.lastMessageVO?.id == thread.lastSeenMessageId || thread.lastSeenMessageId ?? 0 > thread.lastMessageVO?.id ?? 0
    }

    private func scrollTo(_ uniqueId: String, position: UITableView.ScrollPosition = .bottom, animate: Bool) {
        viewModel?.historyVM.delegate?.scrollTo(uniqueId: uniqueId, position: position, animate: animate)
    }

    public func scrollToBottom() {
        Task {
            if let messageId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
                viewModel?.threadsViewModel?.saveScrollPositionVM.remove(thread.id ?? -1)
                await viewModel?.historyVM.moveToTime(time, messageId, highlight: false, moveToBottom: true)
            }
        }
    }

    public func scrollToNewMessageIfIsAtBottomOrMe(_ message: HistoryMessageType) {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            scrollTo(uniqueId, animate: true)
            isAtBottomOfTheList = true
            viewModel?.delegate?.showMoveToBottom(show: false)
        }
    }

    public func scrollToLastMessageOnlyIfIsAtBottom() {
        let message = lastMessageOrLastUploadingMessage()
        if isAtBottomOfTheList, let uniqueId = message?.uniqueId {
            disableExcessiveLoading()
            scrollTo(uniqueId, animate: true)
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
