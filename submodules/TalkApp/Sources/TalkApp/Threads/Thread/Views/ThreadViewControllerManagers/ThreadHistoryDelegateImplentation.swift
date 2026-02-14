//
//  ThreadHistoryDelegateImplentation.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 2/11/26.
//

import UIKit
import Chat
import SwiftUI

@MainActor
class ThreadHistoryDelegateImplentation: ThreadViewDelegate {
    private let vc: ThreadViewController

    init(controller: ThreadViewController) {
        self.vc = controller
    }
}

extension ThreadHistoryDelegateImplentation {
    private var viewModel: ThreadViewModel { vc.viewModel }
    private var sendContainer: ThreadBottomToolbar { vc.sendContainer }
    private var sections: ContiguousArray<MessageSection> { viewModel.historyVM.sections }
    private var moveToBottom: MoveToBottomButton { vc.moveToBottom }
    private var loadingManager: ThreadLoadingManager { vc.loadingManager }
    private var view: UIView { vc.view }
    private var topThreadToolbar: TopThreadToolbar { vc.topThreadToolbar }
    private var unreadMentionsButton: UnreadMenitonsButton { vc.unreadMentionsButton }
    private var keyboardManager: HistoryKeyboarHeightManager { vc.keyboardManager}
    private var emptyThreadView: EmptyThreadView { vc.emptyThreadView }
    private var tapGestureManager: HistoryTapGestureManager { vc.tapGestureManager }
    private var vStackOverlayButtons: UIStackView { vc.vStackOverlayButtons }
    private var contextMenuContainer: ContextMenuContainerView { vc.contextMenuContainer }
    private var dimView: DimView { vc.dimView }
    private var cancelAudioRecordingButton: CancelAudioRecordingButton { vc.cancelAudioRecordingButton }
    private var sendVM: SendContainerViewModel? { viewModel.sendContainerViewModel }
}

// MARK: Scrolling to
extension ThreadHistoryDelegateImplentation: HistoryScrollDelegate {
    var tableView: UITableView { vc.tableView }
    var viewController: UIViewController { vc }
    private var historyTableView: UIHistoryTableView { vc.tableView }
    
    func emptyStateChanged(isEmpty: Bool) {
        showEmptyThread(show: isEmpty)
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool = true) {
        if tableView.numberOfSections == 0 { return }
        if tableView.numberOfRows(inSection: index.section) < index.row + 1 { return }
        viewModel.scrollVM.didEndScrollingAnimation = false
        tableView.scrollToRow(at: index, at: position, animated: animate)
        
        if vc.isViewControllerVisible == true {
            vc.shouldScrollToBottomAtReapperance = false
        }
    }
    
    func scrollTo(uniqueId: String, messageId: Int, position: UITableView.ScrollPosition, animate: Bool = true) {
        if let indexPath = sections.findIncicesBy(uniqueId: uniqueId, id: messageId) {
            scrollTo(index: indexPath, position: position, animate: animate)
        }
    }
    
    func scrollTo(messageId: Int, position: UITableView.ScrollPosition, animate: Bool = true) {
        if let indexPath = sections.viewModelAndIndexPath(for: messageId)?.indexPath {
            scrollTo(index: indexPath, position: position, animate: animate)
        }
    }
    
    func reload(at: IndexPath) {
        tableView.reloadRows(at: [at], with: .fade)
    }
    
    func moveRow(at: IndexPath, to: IndexPath) {
        tableView.moveRow(at: at, to: to)
    }
    
    func reloadData(at: IndexPath) {
        if let cell = tableView.cellForRow(at: at) as? MessageBaseCell, let vm = sections.viewModelWith(at) {
            cell.setValues(viewModel: vm)
        }
    }
    
    func moveTolastMessageIfVisible() {
        if viewModel.scrollVM.isAtBottomOfTheList == true, let indexPath = sections.viewModelAndIndexPath(for: viewModel.lastMessageVO()?.id)?.indexPath {
            scrollTo(index: indexPath, position: .bottom)
        }
    }
    
    func uploadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.uploadCompleted(viewModel: viewModel)
    }
    
    func downloadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.downloadCompleted(viewModel: viewModel)
    }
    
    func updateProgress(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.updateProgress(viewModel: viewModel)
    }
    
    func updateReplyImageThumbnail(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.updateReplyImageThumbnail(viewModel: viewModel)
    }
    
    func inserted(_ sections: IndexSet, _ rows: [IndexPath], _ scrollToIndexPath: IndexPath?, _ at: UITableView.ScrollPosition?, _ performWithAnimation: Bool) {
        if performWithAnimation {
            runInserted(sections, rows, at, scrollToIndexPath, true)
        } else {
            UIView.performWithoutAnimation {
                runInserted(sections, rows, at, scrollToIndexPath, false)
            }
        }
    }
    
    func runInserted(_ sections: IndexSet, _ rows: [IndexPath], _ at: UITableView.ScrollPosition?, _ scrollTo: IndexPath?, _ animate: Bool) {
        tableView.beginUpdates()
        
        if !sections.isEmpty {
            self.tableView.insertSections(sections, with: .none)
        }
        if !rows.isEmpty {
            self.tableView.insertRows(at: rows, with: .none)
        }
        tableView.endUpdates()
        
        if let scrollToIndexPath = scrollTo, let at = at {
            viewModel.scrollVM.didEndScrollingAnimation = false
            tableView.scrollToRow(at: scrollToIndexPath, at: at, animated: animate)
        }
        
        viewModel.selectedMessagesViewModel.reSelectTableView()
    }
    
    func insertedWithContentOffsset(_ sections: IndexSet, _ rows: [IndexPath]) {
        /// We use setContentOffset instead of scrollTo,
        /// it will move without jumping sections and it needs estimated height to be close and calculated
        /// in advance, in order to append at top smoothly.
        
        // 1. Capture contentOffset and contentSize before insert
        let previousOffset = tableView.contentOffset
        let previousContentHeight = tableView.contentSize.height
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            
            if !sections.isEmpty {
                self.tableView.insertSections(sections, with: .none)
            }
            if !rows.isEmpty {
                self.tableView.insertRows(at: rows, with: .none)
            }
            tableView.endUpdates()
            
            // Ensure layout pass fully completes
            tableView.layoutIfNeeded()
            
            // 2. Calculate height difference after insert
            let newContentHeight = tableView.contentSize.height
            let heightDifference = newContentHeight - previousContentHeight
            
            // 3. Adjust content offset to preserve visual position
            tableView.setContentOffset(CGPoint(x: previousOffset.x, y: previousOffset.y + heightDifference), animated: false)
            
            viewModel.selectedMessagesViewModel.reSelectTableView()
        }
    }
    
    func delete(sections: [IndexSet], rows: [IndexPath]) {
        log("deleted sections")
        tableView.performBatchUpdates {
            /// First, we have to delete rows to have the right index for rows,
            /// then we are ready to delete sections
            if !rows.isEmpty {
                tableView.deleteRows(at: rows, with: .fade)
            }
            
            if !sections.isEmpty {
                /// From newer section at bottom of theread to top to prevent crash
                sections.reversed().forEach { sectionSet in
                    tableView.deleteSections(sectionSet, with: .fade)
                }
            }
        }
    }
    
    func performBatchUpdateForReactions(_ indexPaths: [IndexPath]) async {
        return await withCheckedContinuation { [weak self] continuation in
            self?.performBatchUpdateForReactions(indexPaths) {
                continuation.resume(with: .success(()))
            }
        }
    }
    
    private func performBatchUpdateForReactions(_ indexPaths: [IndexPath], completion: @escaping () -> Void) {
        log("update reactions")
        let wasAtBottom = viewModel.scrollVM.isAtBottomOfTheList == true
        tableView.performBatchUpdates { [weak self] in
            guard let self = self else {
                return
            }
            for indexPath in indexPaths {
                if let tuple = cellFor(indexPath: indexPath) {
                    tuple.cell.reactionsUpdated(viewModel: tuple.vm)
                }
            }
            if wasAtBottom {
                viewModel.scrollVM.scrollToBottom()
            }
        } completion: { [weak self] completed in
            if completed {
                completion()
            }
        }
    }
    
    public func reactionDeleted(indexPath: IndexPath, reaction: Reaction) {
        log("reaciton deleted")
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionDeleted(reaction)
            tableView.endUpdates()
        }
    }
    
    public func reactionAdded(indexPath: IndexPath, reaction: Reaction) {
        log("reaction added")
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionAdded(reaction)
            tableView.endUpdates()
        }
    }
    
    public func reactionReplaced(indexPath: IndexPath, reaction: Reaction) {
        log("reaction replaced")
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionReplaced(reaction)
            tableView.endUpdates()
        }
    }
    
    func moveToOffset(_ offset: CGFloat) {
        tableView.setContentOffset(.init(x: 0, y: offset), animated: false)
    }
    
    func isCellFullyVisible(at indexPath: IndexPath, bottomPadding: CGFloat) -> Bool {
        let bottom = vc.contentInsetManager.bottomContainerHeight()
        return historyTableView.isCellFullyVisible(indexPath, topInset: tableView.contentInset.top, bottomInset: bottom)
    }
    
    /// Call this method to update the geometry of the previous last message
    /// Note: If the previous last message was a multiline message,
    /// we need to update the geometry after setting botttom constraint.
    func updateTableViewGeometry() {
        UIView.performWithoutAnimation { [weak self] in
            guard let self = self else { return }
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    private func cellFor(indexPath: IndexPath) -> (vm: MessageRowViewModel, cell: MessageBaseCell)?  {
        guard let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell else { return nil }
        guard let vm = sections.viewModelWith(indexPath) else { return nil }
        return (vm, cell)
    }
    
    private func log(_ message: String) {
        Logger.log(title: "ThreadViewController", message: "\(message)")
    }
}

// MARK: ThreadViewDelegate
extension ThreadHistoryDelegateImplentation {
    
    func showMoveToBottom(show: Bool) {
        moveToBottom.show(show)
    }
    
    func isMoveToBottomOnScreen() -> Bool {
        return !moveToBottom.isHidden
    }
    
    func onUnreadCountChanged() {
#if DEBUG
        print("onUnreadCountChanged \(viewModel.thread.unreadCount)")
#endif
        moveToBottom.updateUnreadCount()
    }

    func onChangeUnreadMentions() {
        unreadMentionsButton.onChangeUnreadMentions()
    }
    
    func setTableRowSelected(_ indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }

    func setSelection(_ value: Bool) {
        if !value {
            viewModel.selectedMessagesViewModel.clearSelection()
        }
        setTapGesture(enable: !value)
        viewModel.selectedMessagesViewModel.setInSelectionMode(value)
        if value {
            viewModel.sendContainerViewModel.showEmojiKeybaord = false
        }
        tableView.allowsMultipleSelection = value
        tableView.visibleCells.compactMap{$0 as? MessageBaseCell}.forEach { cell in
            cell.setInSelectionMode(value)
        }
        
        // Assure that the previous resuable rows items are in select mode or not
        for indexPath in viewModel.historyVM.prevouisVisibleIndexPath() {
            if let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
                cell.setInSelectionMode(value)
            }
        }

        // Assure that the next resuable rows items are in select mode or not
        for indexPath in viewModel.historyVM.nextVisibleIndexPath() ?? [] {
            if let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
                cell.setInSelectionMode(value)
            }
        }

        showSelectionBar(value)
        // We need a delay to show selection view to calculate height of sendContainer then update to the last Message if it is visible
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { [weak self] in
                await self?.moveTolastMessageIfVisible()
            }
        }
    }

    func updateSelectionView() {
        sendContainer.updateSelectionBar()
    }

    func lastMessageAppeared(_ appeared: Bool) {
        self.moveToBottom.show(!appeared)
        if self.viewModel.scrollVM.isAtBottomOfTheList == true {
            self.tableView.tableFooterView = nil
        }
    }
    
    func startTopAnimation(_ animate: Bool) {
        self.tableView.tableHeaderView?.isHidden = !animate
        UIView.animate(withDuration: 0.25) {
            self.tableView.tableHeaderView?.layoutIfNeeded()
        }
        self.loadingManager.startTopAnimation(animate)
    }
    
    func startCenterAnimation(_ animate: Bool) {
        self.loadingManager.startCenterAnimation(animate)
    }

    func startBottomAnimation(_ animate: Bool) {
        self.tableView.tableFooterView = animate ? self.loadingManager.getBottomLoadingContainer() : nil
        self.tableView.tableFooterView?.isHidden = !animate
        UIView.animate(withDuration: 0.25) {
            self.tableView.tableFooterView?.layoutIfNeeded()
        }
        self.loadingManager.startBottomAnimation(animate)
    }

    func openShareFiles(urls: [URL], title: String?, sourceView: UIView?) {
        guard let first = urls.first else { return }
        let vc = UIActivityViewController(activityItems: [LinkMetaDataManager(url: first, title: title)], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = sourceView
        self.vc.present(vc, animated: true)
    }

    func onMentionListUpdated() {
        sendContainer.updateMentionList()
        setTapGesture(enable: viewModel.mentionListPickerViewModel.mentionList.count == 0)
    }

    func updateAvatar(image: UIImage, participantId: Int) {
        tableView.visibleCells
            .compactMap({$0 as? PartnerMessageCell})
            .filter{$0.viewModel?.message.participant?.id == participantId}
            .forEach { cell in
                cell.setImage(image)
            }
    }

    func edited(_ indexPath: IndexPath) {
        if let cell = historyTableView.baseCell(indexPath) {
            tableView.performBatchUpdates {
                cell.edited()
            }
        }
    }

    func pinChanged(_ indexPath: IndexPath, pin: Bool) {
        if let cell = historyTableView.baseCell(indexPath) {
            cell.pinChanged(pin: pin)
        }
    }

    func sent(_ indexPath: IndexPath) {
        if let cell = historyTableView.baseCell(indexPath) {
            cell.sent()
        }
    }

    func delivered(_ indexPath: IndexPath) {
        if let cell = historyTableView.baseCell(indexPath) {
            cell.delivered()
        }
    }

    func seen(_ indexPath: IndexPath) {
        if let cell = historyTableView.baseCell(indexPath) {
            cell.seen()
        }
    }

    public func updateTitleTo(_ title: String?) {
        topThreadToolbar.updateTitleTo(title)
    }

    public func updateSubtitleTo(_ subtitle: String?, _ smt: SMT?) {
        topThreadToolbar.updateSubtitleTo(subtitle, smt)
    }

    public func updateImageTo(_ image: UIImage?) {
        topThreadToolbar.updateImageTo(image)
    }

    public func refetchImageOnUpdateInfo() {
        topThreadToolbar.refetchImageOnUpdateInfo()
    }

    func setHighlightRowAt(_ indexPath: IndexPath, highlight: Bool) {
        if let cell = historyTableView.baseCell(indexPath) {
            cell.setHighlight()
        } else if let cell = tableView.cellForRow(at: indexPath) as? CallEventCell {
            cell.setHighlight(highlight: highlight)
        } else if let cell = tableView.cellForRow(at: indexPath) as? ParticipantsEventCell {
            cell.setHighlight(highlight: highlight)
        }
    }

    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        contextMenuContainer.setContentView(contentView, indexPath: indexPath)
        contextMenuContainer.show()
    }

    func dismissContextMenu(indexPath: IndexPath?) {
        contextMenuContainer.hide()
        if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            cell.messageContainer.resetOnDismiss()
        }
    }

    func onUpdatePinMessage() {
        topThreadToolbar.updatePinMessage()
    }

    func onConversationClosed() {
        sendContainer.onConversationClosed()
    }
    
    func visibleIndexPaths() -> [IndexPath] {
        tableView.indexPathsForVisibleRows ?? []
    }
    
    func lastMessageIndexPathIfVisible() -> IndexPath? {
        guard viewModel.scrollVM.isAtBottomOfTheList == true else { return nil }
        return tableView.indexPathsForVisibleRows?.last
    }
    
    func setTapGesture(enable: Bool) {
        tapGestureManager.setEnable(enable)
    }
}

extension ThreadHistoryDelegateImplentation: BottomToolbarDelegate {
    
    func showMainButtons(_ show: Bool) {
        sendContainer.showMainButtons(show)
    }

    func showSelectionBar(_ show: Bool) {
        sendContainer.showSelectionBar(show)
        showMainButtons(!show)
    }

    func showPickerButtons(_ show: Bool) {
        sendContainer.showPickerButtons(show)
        dimView.attachToParent(parent: view, bottomYAxis: sendContainer.topAnchor)
        dimView.show(show)
    }

    func showRecording(_ show: Bool) {
        sendContainer.openRecording(show)
        cancelAudioRecordingButton.setIsHidden(!show)
    }

    func openEditMode(_ message: HistoryMessageType?) {
        // We only check if we select a message to edit. For closing and sending message where message is nil we leave the focus remain on the textfield to send further messages.
        if message != nil {
            focusOnTextView(focus: true)
            openReplyMode(nil)
        }
    }

    func openReplyMode(_ message: HistoryMessageType?) {
        // We only check if we select a message to reply. For closing and sending message where message is nil we leave the focus remain on the textfield to send further messages.
        if message != nil {
            focusOnTextView(focus: true)
        }
        viewModel.replyMessage = message as? Message
        sendContainer.openReplyMode(message)
        viewModel.scrollVM.disableExcessiveLoading()
        let scrollPosition: UITableView.ScrollPosition = keyboardManager.hasExternalKeyboard ? .none : .middle
        scrollTo(uniqueId: message?.uniqueId ?? "", messageId: message?.id ?? -1, position: scrollPosition)
    }

    func focusOnTextView(focus: Bool) {
        sendContainer.focusOnTextView(focus: focus)
    }

    func showForwardPlaceholder(show: Bool) {
        sendContainer.showForwardPlaceholder(show: show)
    }

    func showReplyPrivatelyPlaceholder(show: Bool) {
        sendContainer.showReplyPrivatelyPlaceholder(show: show)
    }

    func muteChanged() {
        sendContainer.muteChanged()
    }
}

// MARK: Sheets Delegate
extension ThreadHistoryDelegateImplentation: SheetsDelegate {
    func openForwardPicker(messages: [Message]) {
        let vc = ForwardPickerViewController { [weak self] (conversation, contact) in
            self?.viewModel.sendMessageViewModel.openDestinationConversationToForward(conversation, contact, messages)
        } onDisappear: { [weak self] in
            self?.vc.isViewControllerVisible = true
        }
        vc.modalPresentationStyle = .formSheet
        self.vc.isViewControllerVisible = false
        self.vc.present(vc, animated: true)
    }

    func openMoveToDatePicker() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
            DatePickerWrapper(hideControls: false) { [weak self] date in
                self?.viewModel.historyVM.moveToTimeByDate(time: UInt(date.millisecondsSince1970))
                AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
            }
            .frame(width: AppState.shared.windowMode.isInSlimMode ? 310 : 320, height: 420)
        )
    }
}

extension ThreadHistoryDelegateImplentation {
    func showReplyOnOpen() {
        if let replyMessage = sendVM?.getDraftReplyMessage() {
            self.viewModel.replyMessage = replyMessage
            openReplyMode(replyMessage)
        }
    }
}

extension ThreadHistoryDelegateImplentation {
    private func showEmptyThread(show: Bool) {
        /// We only need to set to false for the first time, after that it will be removed
        /// or add to view.
        if show {
            emptyThreadView.isHidden = false
        }
        emptyThreadView.show(show, parent: view)
        if show {
            self.unreadMentionsButton.showWithAniamtion(false)
            self.moveToBottom.show(false)
            view.bringSubviewToFront(vStackOverlayButtons)
            view.bringSubviewToFront(sendContainer)
        }
    }
}
