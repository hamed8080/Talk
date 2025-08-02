//
//  HistoryScrollDelegate.swift
//  Talk
//
//  Created by hamed on 3/14/24.
//

import Foundation
import UIKit
import TalkModels
import Chat

@MainActor
public protocol HistoryScrollDelegate: AnyObject, HistoryEmptyDelegate, Sendable {
    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool)
    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition, animate: Bool)
    func reload()
    func reload(at: IndexPath)
    // Reload data only not the cell
    func reloadData(at: IndexPath)
    func inserted(_ sections: IndexSet, _ rows: [IndexPath], _ scrollToIndexPath: IndexPath?, _ at: UITableView.ScrollPosition?, _ withAnimation: Bool)
    func insertedWithContentOffsset(_ sections: IndexSet, _ rows: [IndexPath])
    func delete(sections: [IndexSet], rows: [IndexPath])
    func moveRow(at: IndexPath, to: IndexPath)
    func edited(_ indexPath: IndexPath)
    func pinChanged(_ indexPath: IndexPath)
    func sent(_ indexPath: IndexPath)
    func delivered(_ indexPath: IndexPath)
    func seen(_ indexPath: IndexPath)
    func updateProgress(at: IndexPath, viewModel: MessageRowViewModel)
    func updateReplyImageThumbnail(at: IndexPath, viewModel: MessageRowViewModel)
    func downloadCompleted(at: IndexPath, viewModel: MessageRowViewModel)
    func uploadCompleted(at: IndexPath, viewModel: MessageRowViewModel)
    func setHighlightRowAt(_ indexPath: IndexPath, highlight: Bool)
    func performBatchUpdateForReactions(_ indexPaths: [IndexPath]) async
    func showMoveToBottom(show: Bool)
    func isMoveToBottomOnScreen() -> Bool
    func moveToOffset(_ offset: CGFloat)
    func reactionDeleted(indexPath: IndexPath, reaction: Reaction)
    func reactionAdded(indexPath: IndexPath, reaction: Reaction)
    func reactionReplaced(indexPath: IndexPath, reaction: Reaction)
    func visibleIndexPaths() -> [IndexPath]
    func lastMessageIndexPathIfVisible() -> IndexPath?
}

@MainActor
public protocol HistoryEmptyDelegate {
    func emptyStateChanged(isEmpty: Bool)
}

@MainActor
public protocol UnreadCountDelegate {
    func onUnreadCountChanged()
}

@MainActor
public protocol ChangeUnreadMentionsDelegate {
    func onChangeUnreadMentions()
}

@MainActor
public protocol ChangeSelectionDelegate {
    func setTableRowSelected(_ indexPath: IndexPath)
    func setSelection(_ value: Bool)
    func updateSelectionView()
}

@MainActor
public protocol LastMessageAppearedDelegate {
    func lastMessageAppeared(_ appeared: Bool)
}

@MainActor
public protocol SheetsDelegate {
    func openForwardPicker()
    func openShareFiles(urls: [URL], title: String?, sourceView: UIView?)
    func openMoveToDatePicker()
}

@MainActor
public protocol BottomToolbarDelegate {
    func showMainButtons(_ show: Bool)
    func showSelectionBar(_ show: Bool)
    func showRecording(_ show: Bool)
    func showPickerButtons(_ show: Bool)
    func openEditMode(_ message: HistoryMessageType?)
    func openReplyMode(_ message: HistoryMessageType?)
    func focusOnTextView(focus: Bool)
    func showForwardPlaceholder(show: Bool)
    func showReplyPrivatelyPlaceholder(show: Bool)
    func onConversationClosed()
    func muteChanged()
}

@MainActor
public protocol LoadingDelegate {
    func startTopAnimation(_ animate: Bool)
    func startCenterAnimation(_ animate: Bool)
    func startBottomAnimation(_ animate: Bool)
}

@MainActor
public protocol MentionList {
    func onMentionListUpdated()
}

@MainActor
public protocol AvatarDelegate {
    func updateAvatar(image: UIImage, participantId: Int)
}

@MainActor
public protocol TopToolbarDelegate {
    func updateTitleTo(_ title: String?)
    func updateSubtitleTo(_ subtitle: String?)
    func updateImageTo(_ image: UIImage?)
    func refetchImageOnUpdateInfo()
    func onUpdatePinMessage()
}

@MainActor
public protocol ThreadViewDelegate: AnyObject, UnreadCountDelegate, ChangeUnreadMentionsDelegate, ChangeSelectionDelegate, LastMessageAppearedDelegate, SheetsDelegate, HistoryScrollDelegate, LoadingDelegate, MentionList, AvatarDelegate, BottomToolbarDelegate, TopToolbarDelegate, ContextMenuDelegate {
}
