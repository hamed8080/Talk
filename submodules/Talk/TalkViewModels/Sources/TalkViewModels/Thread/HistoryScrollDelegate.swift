//
//  HistoryScrollDelegate.swift
//  Talk
//
//  Created by hamed on 3/14/24.
//

import Foundation
import UIKit
import TalkModels

public protocol HistoryScrollDelegate: AnyObject, HistoryEmptyDelegate {
    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool)
    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition, animate: Bool)
    func reload()
    func reload(at: IndexPath)
    // Reload data only not the cell
    func reloadData(at: IndexPath)
    func inserted(at: IndexPath)
    func inserted(at: [IndexPath])
    func inserted(_ sections: IndexSet, _ rows: [IndexPath], _ animate :UITableView.RowAnimation, _ scrollTo: IndexPath?)
    func removed(at: IndexPath)
    func removed(at: [IndexPath])
    func moveRow(at: IndexPath, to: IndexPath)
    func edited(_ indexPath: IndexPath)
    func pinChanged(_ indexPath: IndexPath)
    func sent(_ indexPath: IndexPath)
    func delivered(_ indexPath: IndexPath)
    func seen(_ indexPath: IndexPath)
    func updateProgress(at: IndexPath, viewModel: MessageRowViewModel)
    func updateThumbnail(at: IndexPath, viewModel: MessageRowViewModel)
    func updateReplyImageThumbnail(at: IndexPath, viewModel: MessageRowViewModel)
    func downloadCompleted(at: IndexPath, viewModel: MessageRowViewModel)
    func uploadCompleted(at: IndexPath, viewModel: MessageRowViewModel)
    func setHighlightRowAt(_ indexPath: IndexPath, highlight: Bool)
    func performBatchUpdateForReactions(_ indexPaths: [IndexPath])
}

public protocol HistoryEmptyDelegate {
    func emptyStateChanged(isEmpty: Bool)
}

public protocol UnreadCountDelegate {
    func onUnreadCountChanged()
}

public protocol ChangeUnreadMentionsDelegate {
    func onChangeUnreadMentions()
}

public protocol ChangeSelectionDelegate {
    func setSelection(_ value: Bool)
    func updateSelectionView()
}

public protocol LastMessageAppearedDelegate {
    func lastMessageAppeared(_ appeared: Bool)
}

public protocol SheetsDelegate {
    func openForwardPicker()
    func openShareFiles(urls: [URL], title: String?, sourceView: UIView?)
}

public protocol BottomToolbarDelegate {
    func showMainButtons(_ show: Bool)
    func showSelectionBar(_ show: Bool)
    func showRecording(_ show: Bool)
    func showPickerButtons(_ show: Bool)
    func showSendButton(_ show: Bool)
    func showMicButton(_ show: Bool)
    func onItemsPicked()
    func openEditMode(_ message: (any HistoryMessageProtocol)?)
    func openReplyMode(_ message: (any HistoryMessageProtocol)?)
    func focusOnTextView(focus: Bool)
    func showForwardPlaceholder(show: Bool)
    func showReplyPrivatelyPlaceholder(show: Bool)
    func onConversationClosed()
}

public protocol LoadingDelegate {
    func startTopAnimation(_ animate: Bool)
    func startCenterAnimation(_ animate: Bool)
    func startBottomAnimation(_ animate: Bool)
}

public protocol MentionList {
    func onMentionListUpdated()
}

public protocol AvatarDelegate {
    func updateAvatar(image: UIImage, participantId: Int)
}

public protocol TopToolbarDelegate {
    func updateTitleTo(_ title: String?)
    func updateSubtitleTo(_ subtitle: String?)
    func updateImageTo(_ image: UIImage?)
    func refetchImageOnUpdateInfo()
    func onUpdatePinMessage()
}

public protocol ThreadViewDelegate: AnyObject, UnreadCountDelegate, ChangeUnreadMentionsDelegate, ChangeSelectionDelegate, LastMessageAppearedDelegate, SheetsDelegate, HistoryScrollDelegate, LoadingDelegate, MentionList, AvatarDelegate, BottomToolbarDelegate, TopToolbarDelegate, ContextMenuDelegate {
}
