//
//  ContactTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI

class ContactTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ContactListSection, Contact>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ContactsViewModel
    static let resuableIdentifier = "CONTACTROW"
    
    init(viewModel: ContactsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: ContactTableViewController.resuableIdentifier)
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
        
        tableView.sectionHeaderTopPadding = 0
        let header = ContactsTableViewHeader()
        header.startLoading()
        header.viewController = self
        header.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = header
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            header.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            header.heightAnchor.constraint(equalToConstant: 140),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
    }
}

extension ContactTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, contact) -> UITableViewCell? in
            guard let self = self else { return nil }
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactTableViewController.resuableIdentifier,
                for: indexPath
            ) as? ContactCell
            
            // Set properties
            cell?.setContact(contact: contact, viewModel: viewModel)
            
            return cell
        }
    }
}

extension ContactTableViewController: UIContactsViewControllerDelegate {
    func updateUI(animation: Bool, reloadSections: Bool) {
        (tableView.tableHeaderView as? ContactsTableViewHeader)?.removeLoading()
        
        /// Create
        var snapshot = NSDiffableDataSourceSnapshot<ContactListSection, Contact>()
        
        /// Configure
        snapshot.appendSections([.main])
        snapshot.appendItems(list, toSection: .main)
        if reloadSections {
            snapshot.reloadSections([.main])
        }
        
        /// Apply
        dataSource.apply(snapshot, animatingDifferences: animation)
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.setImage(image)
    }
    
    private func cell(id: Int) -> ContactCell? {
        guard let index = list.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ContactCell
    }
    
    private var isInSearch: Bool {
        viewModel.searchedContacts.count > 0 && !viewModel.searchContactString.isEmpty
    }
    
    private var list: [Contact] {
        let list = isInSearch ? viewModel.searchedContacts : viewModel.contacts
        return Array(list)
    }
}

extension ContactTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        if viewModel.isInSelectionMode {
            viewModel.toggleSelectedContact(contact: contact)
        } else {
            Task {
                try await AppState.shared.objectsContainer.navVM.openThread(contact: contact)
            }
        }
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
        
        let isBlocked = dataSource.itemIdentifier(for: indexPath)?.blocked == true
        let blockAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.onSwipeBlock(indexPath)
            success(true)
        }
        blockAction.image = UIImage(systemName: isBlocked ? "hand.raised.slash.fill" : "hand.raised.fill")
        blockAction.backgroundColor = UIColor.darkGray
        
        let config = UISwipeActionsConfiguration(actions: [editAction, blockAction, deleteAction])
        return config
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.loadMore(id: contact.id)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !isInSearch { return 0 }
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !isInSearch { return nil }
        let view = SectionHeaderTitleView(
            frame: .init(x: 0, y: 0, width: view.frame.width, height: 16),
            text: "Contacts.searched".bundleLocalized()
        )
        return view
    }
}

extension ContactTableViewController {
    func onSwipeDelete(_ indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 1)
        viewModel.addToSelctedContacts(contact)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
            DeleteContactView()
                .environmentObject(viewModel)
                .onDisappear {
                    self.viewModel.removeToSelctedContacts(contact)
                }
        )
    }
    
    func onSwipeEdit(_ indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.editContact = contact
        
        if #available(iOS 16.4, *) {
            let rootView = AddOrEditContactView()
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .environmentObject(viewModel)
                .onDisappear { [weak self] in
                    guard let self = self else { return }
                    /// Clearing the view for when the user cancels the sheet by dropping it down.
                    viewModel.successAdded = false
                    viewModel.addContact = nil
                    viewModel.editContact = nil
                }
            var sheetVC = UIHostingController(rootView: rootView)
            sheetVC.modalPresentationStyle = .formSheet
            self.present(sheetVC, animated: true)
        }
    }
    
    func onSwipeBlock(_ indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        if contact.blocked == true, let contactId = contact.id {
            viewModel.unblockWith(contactId)
        } else {
            viewModel.block(contact)
        }
    }
}

struct ContactsViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ContactsViewModel
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ContactTableViewController(viewModel: viewModel)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
