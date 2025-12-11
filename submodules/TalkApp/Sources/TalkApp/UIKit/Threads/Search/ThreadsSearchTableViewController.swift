//
//  ThreadsSearchTableViewController.swift
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

class ThreadsSearchTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ThreadsSearchListSection, ThreadSearchItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ThreadsSearchViewModel
    private let noResultView = NothingFoundView()
    static let conversationResuableIdentifier = "THREADS-SERARCH-CONCERSATION-ROW"
    static let contactResuableIdentifier = "CONTACTS-SERARCH-CONCERSATION-ROW"
    static let nothingFoundResuableIdentifier = "NOTHING-FOUND-SERARCH-CONCERSATION-ROW"
    private let centerAnimation = LottieAnimationView(fileName: "talk_logo_animation.json")
    
    init(viewModel: ThreadsSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ThreadsSearchTableViewController.conversationResuableIdentifier)
        tableView.register(ContactCell.self, forCellReuseIdentifier: ThreadsSearchTableViewController.contactResuableIdentifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: ThreadsSearchTableViewController.nothingFoundResuableIdentifier)
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
        tableView.sectionHeaderTopPadding = 0
        tableView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        view.addSubview(tableView)
        
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refresh

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
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension ThreadsSearchTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .contact(let contact):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ThreadsSearchTableViewController.contactResuableIdentifier,
                    for: indexPath
                ) as? ContactCell
                // Set properties
                cell?.setContact(contact: contact, viewModel: AppState.shared.objectsContainer.contactsVM)
                return cell
            case .conversation(let conversation):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ThreadsSearchTableViewController.conversationResuableIdentifier,
                    for: indexPath
                ) as? ConversationCell
                // Set properties
                cell?.setConversation(conversation: conversation)
                return cell
            case .noContactFound, .noConversationFound:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ThreadsSearchTableViewController.nothingFoundResuableIdentifier,
                    for: indexPath
                ) as? NothingFoundCell
                return cell
            }
            return nil
        }
    }
    
    @objc private func onRefresh() {
        Task {
//            await viewModel.refresh()
//            tableView.refreshControl?.endRefreshing()
        }
    }
}

extension ThreadsSearchTableViewController: UIThreadsSearchViewControllerDelegate {
    var contentSize: CGSize { tableView.contentSize }

    var contentOffset: CGPoint { tableView.contentOffset }

    func setContentOffset(offset: CGPoint) {
        tableView.contentOffset = offset
    }

    func apply(snapshot: NSDiffableDataSourceSnapshot<ThreadsSearchListSection, ThreadSearchItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            self?.centerAnimation(show: false)
        }
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.setImage(image)
    }
    
    private func cell(id: Int) -> ConversationCell? {
        guard let index = viewModel.searchedConversations.firstIndex(where: { $0.id == id }) else { return nil }
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
        let item = dataSource?.itemIdentifier(for: indexPath)
        if case .conversation(let calculatedConversation) = item {
            return calculatedConversation
        }
        return nil
    }
    
    func scrollToFirstIndex() {
        guard !viewModel.searchedConversations.isEmpty && tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 else { return }
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func createThreadViewController(conversation: Conversation) -> UIViewController {
        let vc = ThreadViewController()
        vc.viewModel = ThreadViewModel(thread: conversation)
        return vc
    }
}

extension ThreadsSearchTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let secondaryVC = splitViewController?.viewController(for: .secondary) as? UINavigationController
        let threadVC = secondaryVC?.viewControllers.last as? ThreadViewController
        
        switch item {
        case .contact(let contact):
            Task {
                try await AppState.shared.objectsContainer.navVM.openThread(contact: contact)
            }
        case .conversation(let conversation):
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
        case .noContactFound, .noConversationFound:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .conversation(let calculatedConversation) = item {
            Task {
                await viewModel.loadMore()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == ThreadsSearchListSection.conversations.rawValue {
            let view = SectionHeaderTitleView(
                frame: .init(x: 0, y: 0, width: view.frame.width, height: 16),
                text: "Tab.chats".bundleLocalized()
            )
            return view
        }
        
        if section == ThreadsSearchListSection.contacts.rawValue {
            let view = SectionHeaderTitleView(
                frame: .init(x: 0, y: 0, width: view.frame.width, height: 16),
                text: "Contacts.searched".bundleLocalized()
            )
            return view
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = dataSource.itemIdentifier(for: indexPath)
        switch item {
        case .conversation:
            return 96
        case .contact:
            return 96
        case .noContactFound, .noConversationFound:
            return 36
        case .none:
            return 96
        }
    }
}

extension ThreadsSearchTableViewController {
    private func centerAnimation(show: Bool) {
        centerAnimation.isHidden = !show
        centerAnimation.isUserInteractionEnabled = show
        if show {
            centerAnimation.play()
        } else {
            centerAnimation.stop()
        }
    }
}
