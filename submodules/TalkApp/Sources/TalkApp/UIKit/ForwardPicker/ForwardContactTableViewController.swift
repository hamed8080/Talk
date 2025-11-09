//
//  ForwardContactTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels

class ForwardContactTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ContactListSection, Contact>?
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ThreadOrContactPickerViewModel
    static let resuableIdentifier = "CONTACT-ROW"
    private let onSelect: @Sendable (Conversation?, Contact?) -> Void
    
    init(viewModel: ThreadOrContactPickerViewModel, onSelect: @Sendable @escaping (Conversation?, Contact?) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        viewModel.contactsDelegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: ForwardContactTableViewController.resuableIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        tableView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 96
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = Color.App.bgPrimaryUIColor
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
        
        /// Update the UI for the first time,
        /// if we have fetched all the contacts before opening the contacts tab for the first time on open.
        viewModel.updateContactUI(animation: false)
        
        for contact in viewModel.contacts {
            viewModel.addImageLoader(contact)
        }
    }
}

extension ForwardContactTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, contact) -> UITableViewCell? in
            guard let self = self else { return nil }
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ForwardContactTableViewController.resuableIdentifier,
                for: indexPath
            ) as? ContactCell
            
            // Set properties
            cell?.setContact(contact: contact, viewModel: nil)
            let vm = viewModel.contactsImages[contact.id ?? -1]
            cell?.setImage(vm?.isImageReady == true ? vm?.image : nil)
            return cell
        }
    }
}

extension ForwardContactTableViewController: UIForwardContactsViewControllerDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<TalkViewModels.ContactListSection, ChatModels.Contact>, animatingDifferences: Bool) {
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.setImage(image)
    }
    
    private func cell(id: Int) -> ContactCell? {
        guard let index = viewModel.contacts.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ContactCell
    }
}

extension ForwardContactTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let contact = dataSource?.itemIdentifier(for: indexPath) else { return }
        onSelect(nil, contact)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let contact = dataSource?.itemIdentifier(for: indexPath) else { return }
        if contact.id == viewModel.contacts.last?.id {
            Task {
                try await viewModel.loadMoreContacts()
            }
        }
    }
}

struct ForwardContactTableViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ThreadOrContactPickerViewModel
    let onSelect: (Conversation?, Contact?) -> Void
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ForwardContactTableViewController(viewModel: viewModel, onSelect: onSelect)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
