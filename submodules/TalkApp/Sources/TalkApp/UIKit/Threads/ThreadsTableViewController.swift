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

class ThreadsTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ThreadsListSection, CalculatedConversation>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ThreadsViewModel
    static let resuableIdentifier = "CONCERSATION-ROW"
    public var contextMenuContainer: ContextMenuContainerView?
    private let threadsToolbar = ThreadsTopToolbarView()
    
    init(viewModel: ThreadsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ThreadsTableViewController.resuableIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 96
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = Color.App.bgPrimaryUIColor
        tableView.separatorStyle = .none
        tableView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        view.addSubview(tableView)
        
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
        
        /// Toolbar
        threadsToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(threadsToolbar)
        tableView.contentInset = .init(top: ToolbarButtonItem.buttonWidth, left: 0, bottom: 0, right: 0)
        
        NSLayoutConstraint.activate([
            /// Toolbar
            threadsToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            threadsToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            threadsToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contextMenuContainer = .init(delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset.top = threadsToolbar.frame.height
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
            cell?.delegate = self
            
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
    func updateUI(animation: Bool, reloadSections: Bool) {
        /// Create
        var snapshot = NSDiffableDataSourceSnapshot<ThreadsListSection, CalculatedConversation>()
        
        /// Configure
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(viewModel.threads), toSection: .main)
        if reloadSections {
            snapshot.reloadSections([.main])
        }
        
        /// Apply
        Task { @AppBackgroundActor in
            await dataSource?.apply(snapshot, animatingDifferences: animation)
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
    
    func scrollToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }
    
    func createThreadViewController(conversation: Conversation) -> UIViewController {
        let vc = ThreadViewController()
        vc.viewModel = ThreadViewModel(thread: conversation)
        return vc
    }
}

extension ThreadsTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let conversation = dataSource.itemIdentifier(for: indexPath)
        else { return }
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
            vc.navigationController?.setNavigationBarHidden(true, animated: false)
            // iPhone — push onto the existing navigation stack
            viewModel.onTapped(viewController: vc, conversation: conversation.toStruct())
        } else {
            // iPad — show in secondary column
            let nav = FastNavigationController(rootViewController: vc)
            nav.setNavigationBarHidden(true, animated: false)
            viewModel.onTapped(viewController: nav, conversation: conversation.toStruct())
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return nil }
        var arr: [UIContextualAction] = []
        
        let muteAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.viewModel.toggleMute(conversation.toStruct())
            success(true)
        }
        muteAction.image = UIImage(systemName: conversation.mute == true ? "speaker" : "speaker.slash")
        muteAction.backgroundColor = UIColor.gray
        arr.append(muteAction)
        
        let hasSpaceToAddMorePin = viewModel.serverSortedPins.count < 5
        let pinAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            if !hasSpaceToAddMorePin {
                /// Show dialog
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(WarningDialogView(message: "Errors.warningCantAddMorePinThread".bundleLocalized()))
                return
            }
            self?.viewModel.togglePin(conversation.toStruct())
            success(true)
        }
        pinAction.image = UIImage(systemName: conversation.pin == true ? "pin.slash.fill" : "pin")
        pinAction.backgroundColor = UIColor.darkGray
        arr.append(pinAction)
        
        let archiveImage = conversation.isArchive == true ?  "tray.and.arrow.up" : "tray.and.arrow.down"
        let archiveAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.viewModel.toggleArchive(conversation.toStruct())
            success(true)
        }
        archiveAction.image = UIImage(systemName: archiveImage)
        archiveAction.backgroundColor = Color.App.color5UIColor
        arr.append(archiveAction)
    
        return UISwipeActionsConfiguration(actions: arr)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        Task {
            await viewModel.loadMore(id: conversation.id ?? -1)
        }
    }
}

struct ThreadsTableViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ThreadsViewModel
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ThreadsTableViewController(viewModel: viewModel)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
