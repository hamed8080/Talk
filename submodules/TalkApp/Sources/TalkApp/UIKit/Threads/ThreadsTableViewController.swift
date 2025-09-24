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

class ThreadsTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ThreadsListSection, CalculatedConversation>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ThreadsViewModel
    static let resuableIdentifier = "CONCERSATION-ROW"
    
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
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 96
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = Color.App.bgPrimaryUIColor
        tableView.separatorStyle = .none
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
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
            cell?.setConversation(conversation: conversation, viewModel: viewModel)
            
            return cell
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
        dataSource.apply(snapshot, animatingDifferences: animation)
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
            .setConversation(conversation: conversation, viewModel: viewModel)
    }
    
    func selectionChanged(conversation: CalculatedConversation) {
        cell(id: conversation.id ?? -1)?.selectionChanged(conversation: conversation)
    }
    
    func unreadCountChanged(conversation: CalculatedConversation) {
        cell(id: conversation.id ?? -1)?.unreadCountChanged(conversation: conversation)
    }
}

extension ThreadsTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        onTapped(conversation: conversation)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "") { [weak self] action, view, success in

            self?.onSwipeDelete(indexPath)
            success(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = UIColor.red
        
        let editAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.onSwipeEdit(indexPath)
            success(true)
        }
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = UIColor.gray
        
        let config = UISwipeActionsConfiguration(actions: [editAction, deleteAction])
        return config
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        Task {
            await viewModel.loadMore(id: conversation.id ?? -1)
        }
    }
}

extension ThreadsTableViewController {
    func onSwipeDelete(_ indexPath: IndexPath) {
//        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
//        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 1)
//        viewModel.addToSelctedContacts(contact)
//        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
//            DeleteContactView()
//                .environmentObject(viewModel)
//                .onDisappear {
//                    self.viewModel.removeToSelctedContacts(contact)
//                }
//        )
    }
    
    func onSwipeEdit(_ indexPath: IndexPath) {
//        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
//        viewModel.editContact = contact
//        
//        if #available(iOS 16.4, *) {
//            let rootView = AddOrEditContactView()
//                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
//                .environmentObject(viewModel)
//                .onDisappear { [weak self] in
//                    guard let self = self else { return }
//                    /// Clearing the view for when the user cancels the sheet by dropping it down.
//                    viewModel.successAdded = false
//                    viewModel.addContact = nil
//                    viewModel.editContact = nil
//                }
//            var sheetVC = UIHostingController(rootView: rootView)
//            sheetVC.modalPresentationStyle = .formSheet
//            self.present(sheetVC, animated: true)
//        }
    }
    
    func onSwipeBlock(_ indexPath: IndexPath) {
//        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
//        if contact.blocked == true, let contactId = contact.id {
//            viewModel.unblockWith(contactId)
//        } else {
//            viewModel.block(contact)
//        }
    }
    
    func onTapped(conversation: CalculatedConversation) {
        /// Ignore opening the same thread on iPad/MacOS, if so it will lead to a bug.
        if conversation.id == AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.threadId { return }
        
        if AppState.shared.objectsContainer.navVM.canNavigateToConversation() {
            /// to update isSeleted for bar and background color
            viewModel.setSelected(for: conversation.id ?? -1, selected: true, isArchive: conversation.isArchive == true)
            AppState.shared.objectsContainer.navVM.switchFromThreadList(thread: conversation.toStruct())
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
