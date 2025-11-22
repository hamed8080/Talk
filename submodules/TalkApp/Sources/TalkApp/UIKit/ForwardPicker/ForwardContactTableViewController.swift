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
import Lottie

class ForwardContactTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ContactListSection, Contact>?
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ThreadOrContactPickerViewModel
    static let resuableIdentifier = "CONTACT-ROW"
    private let onSelect: @Sendable (Conversation?, Contact?) -> Void
    private let centerLoading = LottieAnimationView(fileName: "talk_logo_animation.json")
    private let bottomLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: 52, height: 52))
    private let bottomAnimation = LottieAnimationView(fileName: "dots_loading.json", color: Color.App.textPrimaryUIColor ?? .black)
    
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
        
        bottomAnimation.translatesAutoresizingMaskIntoConstraints = false
        bottomAnimation.accessibilityIdentifier = "bottomLoadingForwardContactTableViewController"
        bottomAnimation.isHidden = true
        bottomAnimation.contentMode = .scaleAspectFit
        bottomLoadingContainer.addSubview(self.bottomAnimation)
        
        tableView.tableFooterView = bottomLoadingContainer
        view.addSubview(tableView)
        
        centerLoading.translatesAutoresizingMaskIntoConstraints = false
        centerLoading.isHidden = false
        centerLoading.play()
        view.addSubview(centerLoading)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            centerLoading.widthAnchor.constraint(equalToConstant: 52),
            centerLoading.heightAnchor.constraint(equalToConstant: 52),
            centerLoading.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerLoading.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            
            bottomAnimation.widthAnchor.constraint(equalToConstant: 52),
            bottomAnimation.heightAnchor.constraint(equalToConstant: 52),
            bottomAnimation.centerXAnchor.constraint(equalTo: bottomLoadingContainer.centerXAnchor),
            bottomAnimation.centerYAnchor.constraint(equalTo: bottomLoadingContainer.centerYAnchor),
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
        centerLoading.isHidden = true
        centerLoading.stop()
        showBottomAnimation(show: false)
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.setImage(image)
    }
    
    private func cell(id: Int) -> ContactCell? {
        guard let index = viewModel.contacts.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ContactCell
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
