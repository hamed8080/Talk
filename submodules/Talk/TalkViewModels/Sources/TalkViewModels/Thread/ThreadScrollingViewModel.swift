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
    @DeceleratingActor public var isEndedDecelerating: Bool = true
    init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        Task {
            await MainActor.run {
                isAtBottomOfTheList = thread.lastMessageVO?.id == thread.lastSeenMessageId
            }
        }
    }

    private func scrollTo(_ uniqueId: String, position: UITableView.ScrollPosition = .bottom, animate: Bool) {
        viewModel?.historyVM.delegate?.scrollTo(uniqueId: uniqueId, position: position, animate: animate)
    }

    public func scrollToBottom() {
        Task {
            if let messageId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
                await viewModel?.historyVM.moveToTime(time, messageId, highlight: false, moveToBottom: true)
            }
        }
    }

    public func scrollToNewMessageIfIsAtBottomOrMe(_ message: HistoryMessageType) {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            scrollTo(uniqueId, animate: true)
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
        let lastUploadElement = AppState.shared.objectsContainer.uploadsManager.lastUploadingMessage(threadId: viewModel?.threadId ?? -1)
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
