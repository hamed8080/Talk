//
//  ForwardConversationTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels

class ForwardConversationTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ThreadsListSection, CalculatedConversation>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ThreadOrContactPickerViewModel
    static let resuableIdentifier = "CONCERSATION-ROW"
    private let onSelect: @Sendable (Conversation?, Contact?) -> Void
    var contextMenuContainer: ContextMenuContainerView? = nil
    private var previousOffset: CGPoint? = nil
    private var previousContentSize: CGSize? = nil
    
    init(viewModel: ThreadOrContactPickerViewModel, onSelect: @Sendable @escaping (Conversation?, Contact?) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.start()
    }
}

extension ForwardConversationTableViewController {
    
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
}

extension ForwardConversationTableViewController: UIThreadsViewControllerDelegate {
    var contentSize: CGSize { tableView.contentSize }

    var contentOffset: CGPoint { tableView.contentOffset }

    func setContentOffset(offset: CGPoint) {
        tableView.contentOffset = offset
    }

    func apply(snapshot: NSDiffableDataSourceSnapshot<ThreadsListSection, CalculatedConversation>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.setImage(image)
    }
    
    private func cell(id: Int) -> ConversationCell? {
        guard let index = viewModel.conversations.firstIndex(where: { $0.id == id }) else { return nil }
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
    
    func scrollToFirstIndex() {
        guard !viewModel.conversations.isEmpty && tableView.numberOfRows(inSection: 0) > 0 else { return }
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func createThreadViewController(conversation: Conversation) -> UIViewController {
        let vc = ThreadViewController()
        vc.viewModel = ThreadViewModel(thread: conversation)
        return vc
    }
}

extension ForwardConversationTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
  
    }
    
    func dismissContextMenu(indexPath: IndexPath?) {
        
    }
}

extension ForwardConversationTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        onSelect(conversation.toStruct(), nil)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        Task {
            await viewModel.loadMore(id: conversation.id)
        }
    }
}

struct ForwardConversationTableViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ThreadOrContactPickerViewModel
    let onSelect: (Conversation?, Contact?) -> Void
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ForwardConversationTableViewController(viewModel: viewModel, onSelect: onSelect)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
