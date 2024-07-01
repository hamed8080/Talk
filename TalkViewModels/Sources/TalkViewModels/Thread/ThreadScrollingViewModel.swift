//
//  ThreadScrollingViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Chat
import Foundation
import ChatModels
import ChatDTO
import ChatCore
import UIKit
import TalkModels

public actor DeceleratingBackgroundActor {}

@globalActor public actor DeceleratingActor: GlobalActor {
    public static var shared = DeceleratingBackgroundActor()
}

public final class ThreadScrollingViewModel {
    var task: Task<(), Never>?
    public var isProgramaticallyScroll: Bool = false
    @HistoryActor public var scrollingUP = false
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init(id: -1)}
    public var isAtBottomOfTheList: Bool = false
    @HistoryActor public var lastContentOffsetY: CGFloat = 0
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

    public func scrollToLastMessageIfLastMessageIsVisible(_ message: any HistoryMessageProtocol) async {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            scrollTo(uniqueId, animate: true)
        }
    }

    public func scrollToLastUploadedMessageWith(_ indexPath: IndexPath) async {
        disableExcessiveLoading()
        viewModel?.delegate?.scrollTo(index: indexPath, position: .top, animate: true)
    }

    public func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, position: UITableView.ScrollPosition = .bottom) {
       task = Task {
            if Task.isCancelled { return }
            await MainActor.run {
                if highlight {
                    NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
                }
            }
           scrollTo(uniqueId, position: position, animate: false)
        }
    }

    @MainActor
    public func showHighlightedAsync(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, position: UITableView.ScrollPosition = .bottom, animate: Bool = false) async {
        if Task.isCancelled { return }
        if highlight {
            NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
        }
        scrollTo(uniqueId, position: position, animate: animate)
    }

    public func disableExcessiveLoading() {
        task = Task { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                isProgramaticallyScroll = true
            }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                isProgramaticallyScroll = false
            }
        }
    }

    public func cancelTask() {
        task?.cancel()
        task = nil
    }
}
