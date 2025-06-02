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
import OSLog

@MainActor
class UIHistoryTableView: UITableView {
    private weak var viewModel: ThreadViewModel?
    private let revealAnimation = RevealAnimation()
    private var sections: ContiguousArray<MessageSection> { viewModel?.historyVM.sectionsHolder.sections ?? [] }

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
#if DEBUG
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Talk-App")
        Task.detached {
            logger.info("\(string, privacy: .sensitive)")
        }
#endif
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

    @MainActor
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
        Task { @HistoryActor [weak self] in
            await self?.viewModel?.scrollVM.lastContentOffsetY = scrollView.contentOffset.y
        }
        Task(priority: .userInitiated) { @DeceleratingActor [weak self] in
            await self?.viewModel?.scrollVM.isEndedDecelerating = false
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        log("deceleration ended has been called")
        Task(priority: .userInitiated) { @DeceleratingActor [weak self] in
            await self?.viewModel?.scrollVM.isEndedDecelerating = true
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            log("stop immediately with no deceleration")
            Task(priority: .userInitiated) { @DeceleratingActor [weak self] in
                await self?.viewModel?.scrollVM.isEndedDecelerating = true
            }
        }
    }
}
