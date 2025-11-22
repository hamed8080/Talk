//
//  ThreadsTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels
import TalkUI
import Lottie

class ThreadsTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ThreadsListSection, CalculatedConversation>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ThreadsViewModel
    static let resuableIdentifier = "CONCERSATION-ROW"
    public var contextMenuContainer: ContextMenuContainerView?
    private let threadsToolbar = ThreadsTopToolbarView()
    private var searchListVC: UIViewController? = nil
    private let bottomLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: 52, height: 52))
    private let centerAnimation = LottieAnimationView(fileName: "talk_logo_animation.json")
    private let bottomAnimation = LottieAnimationView(fileName: "dots_loading.json", color: Color.App.textPrimaryUIColor ?? .black)
    
    init(viewModel: ThreadsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ThreadsTableViewController.resuableIdentifier)
        configureView()
        configureDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 96
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = Color.App.bgPrimaryUIColor
        tableView.separatorStyle = .none
        tableView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        bottomAnimation.translatesAutoresizingMaskIntoConstraints = false
        bottomAnimation.accessibilityIdentifier = "bottomLoadingThreadsTableViewController"
        bottomAnimation.isHidden = true
        bottomAnimation.contentMode = .scaleAspectFit
        bottomLoadingContainer.addSubview(self.bottomAnimation)
        
        tableView.tableFooterView = bottomLoadingContainer
        view.addSubview(tableView)
        
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
        
        /// Toolbar
        threadsToolbar.translatesAutoresizingMaskIntoConstraints = false
        threadsToolbar.onSearchChanged = { [weak self] isInSearchMode in
            Task { @MainActor [weak self] in
                self?.configureUISearchListView(show: isInSearchMode)
            }
        }
        view.addSubview(threadsToolbar)
        tableView.contentInset = .init(top: ToolbarButtonItem.buttonWidth, left: 0, bottom: ConstantSizes.bottomToolbarSize, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        
        centerAnimation.translatesAutoresizingMaskIntoConstraints = false
        centerAnimation.isHidden = false
        centerAnimation.play()
        view.addSubview(centerAnimation)
        
        NSLayoutConstraint.activate([
            centerAnimation.widthAnchor.constraint(equalToConstant: 52),
            centerAnimation.heightAnchor.constraint(equalToConstant: 52),
            centerAnimation.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerAnimation.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            
            bottomAnimation.widthAnchor.constraint(equalToConstant: 52),
            bottomAnimation.heightAnchor.constraint(equalToConstant: 52),
            bottomAnimation.centerXAnchor.constraint(equalTo: bottomLoadingContainer.centerXAnchor),
            bottomAnimation.centerYAnchor.constraint(equalTo: bottomLoadingContainer.centerYAnchor),
            
            /// Toolbar
            threadsToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            threadsToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            threadsToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        if viewModel.isArchive == true {
            threadsToolbar.removeFromSuperview()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contextMenuContainer = .init(delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        /// Update content inset once player is appeared or disappeared
        UIView.animate(withDuration: 0.15) { [weak self] in
            guard let self = self else { return }
            if viewModel.isArchive == true {
                /// 8 for top and 8 for bottom padding in arhchive normalToolbar
                tableView.contentInset.top = ToolbarButtonItem.buttonWidth + 16
                tableView.contentInset.bottom = 0
            } else {
                tableView.contentInset.top = threadsToolbar.frame.height
            }
            tableView.scrollIndicatorInsets = tableView.contentInset
        }
    }
}

extension ThreadsTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, conversation) -> UITableViewCell? in
            guard let self = self else { return nil }
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ThreadsTableViewController.resuableIdentifier,
                for: indexPath
            ) as? ConversationCell
            
            // Set properties
            cell?.setConversation(conversation: conversation)
            let id = conversation.id ?? -1
            cell?.onContextMenu = { [weak self] sender in
                if sender.state == .began {
                    /// We have to fetch new indexPath the above index path is the old one if we pin/unpin a thread
                    if let index = self?.viewModel.firstIndex(id) {
                        self?.showContextMenu(IndexPath(row: index, section: indexPath.section), contentView: UIView())
                    }
                }
            }
            return cell
        }
    }
    
    @objc private func onRefresh() {
        Task {
            await viewModel.refresh()
            tableView.refreshControl?.endRefreshing()
        }
    }
}

extension ThreadsTableViewController: UIThreadsViewControllerDelegate {
    var contentSize: CGSize { tableView.contentSize }

    var contentOffset: CGPoint { tableView.contentOffset }

    func setContentOffset(offset: CGPoint) {
        tableView.contentOffset = offset
    }

    func apply(snapshot: NSDiffableDataSourceSnapshot<ThreadsListSection, CalculatedConversation>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            self?.showCenterAnimation(show: false)
            self?.showBottomAnimation(show: false)
        }
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.setImage(image)
    }
    
    private func cell(id: Int) -> ConversationCell? {
        guard let index = viewModel.threads.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ConversationCell
    }
    
    func reloadCellWith(conversation: CalculatedConversation) {
        cell(id: conversation.id ?? -1)?
            .setConversation(conversation: conversation)
    }
    
    func setImageFor(id: Int, image: UIImage?) {
        cell(id: id)?.setImage(image)
    }
    
    func selectionChanged(conversation: CalculatedConversation) {
        cell(id: conversation.id ?? -1)?.selectionChanged(conversation: conversation)
    }
    
    func unreadCountChanged(conversation: CalculatedConversation) {
        cell(id: conversation.id ?? -1)?.unreadCountChanged(conversation: conversation)
    }
    
    func setEvent(smt: SMT?, conversation: CalculatedConversation) {
        cell(id: conversation.id ?? -1)?.setEvent(smt, conversation)
    }
    
    func indexPath<T: UITableViewCell>(for cell: T) -> IndexPath? {
        tableView.indexPath(for: cell)
    }
    
    func dataSourceItem(for indexPath: IndexPath) -> CalculatedConversation? {
        dataSource?.itemIdentifier(for: indexPath)
    }
    
    func scrollToFirstIndex() {
        guard !viewModel.threads.isEmpty && tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 else { return }
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func createThreadViewController(conversation: Conversation) -> UIViewController {
        let vc = ThreadViewController()
        vc.viewModel = ThreadViewModel(thread: conversation)
        return vc
    }
    
    func showCenterAnimation(show: Bool) {
        centerAnimation.isHidden = !show
        centerAnimation.isUserInteractionEnabled = show
        if show {
            centerAnimation.play()
        } else {
            centerAnimation.stop()
        }
    }
    
    func showBottomAnimation(show: Bool) {
        bottomAnimation.isHidden = !show
        bottomAnimation.isUserInteractionEnabled = show
        if show {
            tableView.tableFooterView = bottomLoadingContainer
            bottomAnimation.play()
        } else {
            tableView.tableFooterView = UIView()
            bottomAnimation.stop()
        }
    }
}

extension ThreadsTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let conversation = dataSource.itemIdentifier(for: indexPath)
        else { return }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        let cell = tableView.cellForRow(at: indexPath) as? ConversationCell
        let contentView = ThreadRowContextMenuUIKit(conversation: conversation, image: cell?.avatar.image, container: contextMenuContainer)
        contextMenuContainer?.setContentView(contentView, indexPath: indexPath)
        contextMenuContainer?.show()
    }
    
    func dismissContextMenu(indexPath: IndexPath?) {
        
    }
}

extension ThreadsTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        let secondaryVC = splitViewController?.viewController(for: .secondary) as? UINavigationController
        let threadVC = secondaryVC?.viewControllers.last as? ThreadViewController
        if let threadVC = threadVC, threadVC.viewModel?.thread.id == conversation.id {
            // Do nothing if the user tapped on the same conversation on iPadOS row.
            return
        }
        
        let vc = ThreadViewController()
        vc.viewModel = ThreadViewModel(thread: conversation.toStruct())
            
        // Check if container is iPhone navigation controller or iPad split view container or on iPadOS we are in a narrow window
        if splitViewController?.isCollapsed == true {
            // iPhone — push onto the existing navigation stack
            viewModel.onTapped(viewController: vc, conversation: conversation.toStruct())
        } else if conversation.isArchive == true {
            viewModel.onTapped(viewController: vc, conversation: conversation.toStruct())
        } else {
            // iPad — show in secondary column
            let nav = FastNavigationController(rootViewController: vc)
            nav.navigationBar.isHidden = true
            viewModel.onTapped(viewController: nav, conversation: conversation.toStruct())
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return nil }
        var arr: [UIContextualAction] = []
        
        let isArchivedVC = viewModel.isArchive == true
        let isSelfThread = conversation.type == .selfThread
        let isClosed = conversation.closed == true
        
        let muteAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.viewModel.toggleMute(conversation.toStruct())
            success(true)
        }
        muteAction.image = UIImage(systemName: conversation.mute == true ? "speaker" : "speaker.slash")
        muteAction.backgroundColor = UIColor.gray
        if !isSelfThread && !isArchivedVC && !isClosed {
            arr.append(muteAction)
        }
        
        let hasSpaceToAddMorePin = viewModel.serverSortedPins.count < 5
        let pinAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            let isPinAlready = conversation.pin == true
            if !hasSpaceToAddMorePin && !isPinAlready {
                /// Show dialog
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(WarningDialogView(message: "Errors.warningCantAddMorePinThread".bundleLocalized()))
                return
            }
            self?.viewModel.togglePin(conversation.toStruct())
            success(true)
        }
        pinAction.image = UIImage(systemName: conversation.pin == true ? "pin.slash.fill" : "pin")
        pinAction.backgroundColor = UIColor.darkGray
        
        /// We can unpin a closed pin thread
        let isClosedPin = isClosed && conversation.pin == true
        
        if (!isArchivedVC && !isClosed) || (isClosedPin) {
            arr.append(pinAction)
        }
        
        let archiveImage = conversation.isArchive == true ?  "tray.and.arrow.up" : "tray.and.arrow.down"
        let archiveAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.viewModel.toggleArchive(conversation.toStruct())
            success(true)
        }
        archiveAction.image = UIImage(systemName: archiveImage)
        archiveAction.backgroundColor = Color.App.color5UIColor
        if !isSelfThread, !isClosed {
            arr.append(archiveAction)
        }

        return UISwipeActionsConfiguration(actions: arr)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        Task {
            await viewModel.loadMore(id: conversation.id ?? -1)
        }
    }
}

/// Search UI configuration
extension ThreadsTableViewController {
    private func configureUISearchListView(show: Bool) {
        if show {
            let searchListVC = ThreadsSearchTableViewController(viewModel: AppState.shared.objectsContainer.searchVM)
            searchListVC.view.translatesAutoresizingMaskIntoConstraints = false
            searchListVC.view.backgroundColor = Color.App.bgPrimaryUIColor
            self.searchListVC = searchListVC
            
            // Embed properly in UIKit hierarchy
            addChild(searchListVC)
            view.addSubview(searchListVC.view)
            searchListVC.didMove(toParent: self)
            
            NSLayoutConstraint.activate([
                searchListVC.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
                searchListVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                searchListVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                searchListVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            searchListVC.tableView.contentInset.top = threadsToolbar.frame.height
            searchListVC.tableView.scrollIndicatorInsets = searchListVC.tableView.contentInset
            
            view.bringSubviewToFront(threadsToolbar)
            
            Task {
                /// Load on open the sheet.
                await AppState.shared.objectsContainer.searchVM.loadOnOpen()
            }
        } else {
            AppState.shared.objectsContainer.searchVM.closedSearchUI()
            
            searchListVC?.willMove(toParent: nil)
            searchListVC?.view.removeFromSuperview()
            searchListVC?.removeFromParent()
            searchListVC = nil
        }
    }
}
