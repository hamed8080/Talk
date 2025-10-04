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
        sectionHeaderHeight = MessageRowSizes.sectionHeaderViewHeight
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
        let row = sections[indexPath.section].vms[indexPath.row]
        row.calMessage.sizes.estimatedHeight = cell.bounds.height
        
        log("[HEIGHT][WILL_DISPLAY] id: \(row.message.id ?? 0) heigth: \(row.calMessage.sizes.estimatedHeight) text:\(row.message.message ?? "") type: \(row.message.type ?? .unknown)")
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
        if viewModel?.selectedMessagesViewModel.isInSelectMode == true { return nil }
        return makeReplyButton(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].vms[indexPath.row]
        log("[HEIGHT][ESTIMATE] id: \(row.message.id ?? 0) heigth: \(row.calMessage.sizes.estimatedHeight) text:\(row.message.message ?? "") type: \(row.message.type ?? .unknown)")
        return sections[indexPath.section].vms[indexPath.row].calMessage.sizes.estimatedHeight
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
    func makeReplyButton(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        let sections = sections
        guard sections.indices.contains(indexPath.section), sections[indexPath.section].vms.indices.contains(indexPath.row) else { return nil }
        let vm = sections[indexPath.section].vms[indexPath.row]
        if viewModel.thread.admin == false && viewModel.thread.type?.isChannelType == true { return nil }
        if vm.message.id == LocalId.unreadMessageBanner.rawValue { return nil }
        if !vm.message.reactionableType { return nil }
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
        if viewModel?.scrollVM.getIsProgramaticallyScrolling() == true {
            log("Reject did scroll to, isProgramaticallyScroll is true")
            return
        }
        viewModel?.historyVM.didScrollTo(scrollView.contentOffset, scrollView.contentSize)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel?.scrollVM.lastContentOffsetY = scrollView.contentOffset.y
        Task(priority: .userInitiated) { @DeceleratingActor [weak self] in
            await self?.viewModel?.scrollVM.isEndedDecelerating = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewModel?.historyVM.didEndDecelerating(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewModel?.historyVM.didEndDragging(scrollView, decelerate)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        viewModel?.scrollVM.didEndScrollingAnimation = true
    }
}

extension UIHistoryTableView {
    public func baseCell(_ indexPath: IndexPath) -> MessageBaseCell? {
        if let cell = cellForRow(at: indexPath) as? MessageBaseCell {
            return cell
        }
        return nil
    }
    
    public func isCellFullyVisible(_ indexPath: IndexPath, topInset: CGFloat = 0, bottomInset: CGFloat = 0) -> Bool {
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
}
