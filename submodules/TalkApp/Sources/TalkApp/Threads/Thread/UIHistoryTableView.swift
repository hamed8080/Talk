//
//  UIHistoryTableView.swift
//  Talk
//
//  Created by hamed on 6/30/24.
//

import Foundation
import UIKit
import SwiftUI
import TalkViewModels
import TalkModels
import Chat
import Logger

@MainActor
class UIHistoryTableView: UITableView {
    private weak var viewModel: ThreadViewModel?
    private let revealAnimation = RevealAnimation()
    private var sections: ContiguousArray<MessageSection> { viewModel?.historyVM.sections ?? [] }

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero, style: .plain)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configure() {
        if semanticContentAttribute == .unspecified {
            semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        }
        delegate = self
        dataSource = self
        estimatedRowHeight = 128
        sectionHeaderHeight = 28
        rowHeight = UITableView.automaticDimension
        tableFooterView = UIView()
        separatorStyle = .none
        backgroundColor = .clear
        prefetchDataSource = self
        allowsMultipleSelection = false // Prevent the user select things when open the thread
        allowsSelection = false // Prevent the user select things when open the thread
        sectionHeaderTopPadding = 0
        showsVerticalScrollIndicator = false
        insetsContentViewsToSafeArea = true
        ConversationHistoryCellFactory.registerCellsAndHeader(self)
        translatesAutoresizingMaskIntoConstraints = false
        accessibilityIdentifier = "tableViewThreadViewController"
        let bgView = ChatBackgroundView(frame: .zero)
        backgroundView = bgView
        backgroundColor = Color.App.bgPrimaryUIColor
    }
    
    private func log(_ string: String) {
        Logger.log(title: "UIHistoryTableView", message: string)
    }
}

// MARK: TableView DataSource
extension UIHistoryTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].vms.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
}

// MARK: TableView Delegate
extension UIHistoryTableView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let viewModel = viewModel else { return nil }
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionHeaderView.self)) as? SectionHeaderView {
            let sectionVM = sections[section]
            headerView.delegate = viewModel.delegate
            headerView.set(sectionVM)
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        revealAnimation.reveal(for: view)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        ConversationHistoryCellFactory.reuse(tableView, indexPath, viewModel)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        revealAnimation.reveal(for: cell)
        sections[indexPath.section].vms[indexPath.row].calMessage.sizes.estimatedHeight = cell.bounds.height
        
        /// To set initial state of the move to bottom visibility once opening the thread.
        if !isDragging && !isDecelerating {
            changeLastMessageIfNeeded(isVisible: sections[indexPath.section].vms[indexPath.row].message.id == viewModel?.thread.lastMessageVO?.id)
        }
        Task { [weak self] in
            await self?.viewModel?.historyVM.willDisplay(indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        Task { [weak self] in
            await self?.viewModel?.historyVM.didEndDisplay(indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            cell.select()
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            cell.deselect()
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell
        return cell != nil
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        makeReplyButton(indexPath: indexPath, isLeading: false)
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        makeReplyButton(indexPath: indexPath, isLeading: true)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return sections[indexPath.section].vms[indexPath.row].calMessage.sizes.estimatedHeight
    }

    public func resetSelection() {
        indexPathsForSelectedRows?.forEach{ indexPath in
            deselectRow(at: indexPath, animated: false)
        }
    }
}

// MARK: Prefetch
extension UIHistoryTableView: UITableViewDataSourcePrefetching {
    // start potentially long-running data operations early.
    // Prefetch images and long running task before the cell appears on the screen.
    // Tip: Do all the job here on the background thread.
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {

    }

    // Cancel long running task if user scroll fast or to another position.
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {

    }
}

// Reply leading/trailing button
extension UIHistoryTableView {
    func makeReplyButton(indexPath: IndexPath, isLeading: Bool) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        let sections = sections
        guard sections.indices.contains(indexPath.section), sections[indexPath.section].vms.indices.contains(indexPath.row) else { return nil }
        let vm = sections[indexPath.section].vms[indexPath.row]
        if viewModel.thread.admin == false && viewModel.thread.type?.isChannelType == true { return nil }
        if vm.message.id == LocalId.unreadMessageBanner.rawValue { return nil }
        if !vm.message.reactionableType { return nil }
        if isLeading && !vm.calMessage.isMe { return nil }
        if !isLeading && vm.calMessage.isMe { return nil }
        let replyAction = UIContextualAction(style: .normal, title: "") { action, view, success in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 1)
            viewModel.delegate?.openReplyMode(vm.message)
            success(true)
        }
        replyAction.image = UIImage(systemName: "arrowshape.turn.up.left.circle")
        replyAction.backgroundColor = UIColor.clear.withAlphaComponent(0.001)
        let config = UISwipeActionsConfiguration(actions: [replyAction])
        return config
    }
}

// MARK: ScrollView delegate
extension UIHistoryTableView {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Task {
            if viewModel?.scrollVM.getIsProgramaticallyScrolling() == true {
                log("Reject did scroll to, isProgramaticallyScroll is true")
                return
            }
            await viewModel?.historyVM.didScrollTo(scrollView.contentOffset, scrollView.contentSize)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel?.scrollVM.lastContentOffsetY = scrollView.contentOffset.y
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        log("deceleration ended has been called")
        
        let isLastMessageVisible = isLastMessageVisible()
        changeLastMessageIfNeeded(isVisible: isLastMessageVisible)
        if !isLastMessageVisible, let message = topVisibleMessage() {
            saveScrollPosition(message)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            log("stop immediately with no deceleration")
            
            let isLastMessageVisible = isLastMessageVisible()
            changeLastMessageIfNeeded(isVisible: isLastMessageVisible)
            if !isLastMessageVisible, let message = topVisibleMessage() {
                saveScrollPosition(message)
            }
        }
    }
    
    private func saveScrollPosition(_ message: Message) {
        let vm = viewModel?.threadsViewModel?.saveScrollPositionVM
        guard let threadId = viewModel?.id else { return }
        vm?.saveScrollPosition(threadId: threadId, message: message, topOffset: contentOffset.y)
    }
}

extension UIHistoryTableView {
    public func baseCell(_ indexPath: IndexPath) -> MessageBaseCell? {
        if let cell = cellForRow(at: indexPath) as? MessageBaseCell {
            return cell
        }
        return nil
    }
    
    public func isVisible(_ indexPath: IndexPath) -> Bool {
        indexPathsForVisibleRows?.contains(where: {$0 == indexPath}) == true
    }
    
    public func prevouisVisibleIndexPath() -> [MessageBaseCell] {
        guard let firstVisibleIndexPath = indexPathsForVisibleRows?.first else { return [] }
        var cells: [MessageBaseCell] = []
        let indexPaths = sections.indexPathsBefore(indexPath: firstVisibleIndexPath, n: 5)
        for i in indexPaths {
            if let cell = cellForRow(at: i) as? MessageBaseCell {
                cells.append(cell)
            }
        }
        return cells
    }
    
    public func nextVisibleIndexPath() -> [MessageBaseCell] {
        guard let lastVisibleIndexPath = indexPathsForVisibleRows?.last else { return [] }
        var cells: [MessageBaseCell] = []
        let indexPaths = sections.indexPathsAfter(indexPath: lastVisibleIndexPath, n: 5)
        for i in indexPaths {
            if let cell = cellForRow(at: i) as? MessageBaseCell {
                cells.append(cell)
            }
        }
        return cells
    }
}

// MARK: Top visible message and IndexPath
extension UIHistoryTableView {
    private func topVisibleMessage() -> Message? {
        guard let indexPath = topVisibleIndexPath() else { return nil }
        return sections[indexPath.section].vms[indexPath.row].message as? Message
    }
    
    private func topVisibleIndexPath() -> IndexPath? {
        guard let visibleRows = indexPathsForVisibleRows else { return nil }
        for indexPath in visibleRows {
            if isCellFullyVisible(indexPath, topInset: contentInset.top, bottomInset: contentInset.bottom) {
                return indexPath
            }
        }
        return nil
    }
  
    private func isCellFullyVisible(_ indexPath: IndexPath, topInset: CGFloat = 0, bottomInset: CGFloat = 0) -> Bool {
        guard let cell = cellForRow(at: indexPath) else {
            // The cell is not visible at all
            return false
        }
        
        // Convert the cell's frame to the tableView's coordinate space
        let cellRect = rectForRow(at: indexPath)
        
        // The visible area of the table view, excluding insets (like nav bar, tool bar, etc.)
        let visibleRect = CGRect(
            x: contentOffset.x,
            y: contentOffset.y,
            width: bounds.width,
            height: bounds.height
        ).inset(by: safeAreaInsets).inset(by: .init(top: topInset, left: 0, bottom: bottomInset, right: 0))
        
        return visibleRect.contains(cellRect)
    }
    
    private func isLastMessageVisible() -> Bool {
        guard let indexPaths = indexPathsForVisibleRows else { return false }
        var result = false
        /// We use suffix to get a small amount of last two items,
        /// because if we delete or add a message lastMessageVO.id
        /// is not equal with last we have to check it with two last item two find it.
        for indexPath in indexPaths.suffix(2) {
            var isVisible = sections[indexPath.section].vms[indexPath.row].message.id == viewModel?.thread.lastMessageVO?.id ?? 0
            
            /// We reduce 16 from contentInset bottom to sort of accept it as fully visible
            if isVisible, isCellFullyVisible(indexPath, topInset: contentInset.top, bottomInset: contentInset.bottom - 16) {
                result = true
                break /// No need to fully check because we found it.
            }
        }
        return result
    }
    
    private func changeLastMessageIfNeeded(isVisible: Bool) {
        /// prevent multiple call
        if isVisible == viewModel?.scrollVM.isAtBottomOfTheList && viewModel?.delegate?.isMoveToBottomOnScreen() ?? false != isVisible {
            return
        }
        
        viewModel?.scrollVM.isAtBottomOfTheList = isVisible
        viewModel?.delegate?.lastMessageAppeared(isVisible)
        
        if isVisible {
            removeSaveScrollPosition()
        }
    }
    
    /// Clear save position if last message is visible.
    private func removeSaveScrollPosition() {
        if let threadId = viewModel?.thread.id {
            viewModel?.threadsViewModel?.saveScrollPositionVM.remove(threadId)
        }
    }
}
