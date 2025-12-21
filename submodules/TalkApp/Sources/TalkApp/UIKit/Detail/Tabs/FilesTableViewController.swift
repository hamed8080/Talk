//
//  FilesTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels

class FilesTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<FilesListSection, FileItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: DetailTabDownloaderViewModel
    static let resuableIdentifier = "VOICE-ROW"
    static let nothingFoundIdentifier = "NOTHING-FOUND-VOICE-ROW"
    private let onSelect: @Sendable (TabRowModel) -> Void
    
    init(viewModel: DetailTabDownloaderViewModel, onSelect: @Sendable @escaping (TabRowModel) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        viewModel.filesDelegate = self
        tableView.register(VoiceCell.self, forCellReuseIdentifier: FilesTableViewController.resuableIdentifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: FilesTableViewController.nothingFoundIdentifier)
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
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.loadMore()
    }
}

extension FilesTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: FilesTableViewController.resuableIdentifier,
                    for: indexPath
                ) as? FileCell
                
                // Set properties
                cell?.setItem(item)
                return cell
            case .noResult:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: FilesTableViewController.nothingFoundIdentifier,
                    for: indexPath
                ) as? NothingFoundCell
                return cell
            }
        }
    }
}

extension FilesTableViewController: UIFilesViewControllerDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<FilesListSection, FileItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func cell(id: Int) -> FileCell? {
        guard let index = viewModel.messagesModels.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FileCell
    }
}

extension FilesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .item(let item) = item {
            onSelect(item)
            dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath),
              indexPath.row >= viewModel.messagesModels.count - 10
        else { return }
        Task {
            try await viewModel.loadMore()
        }
    }
}

class FileCell: UITableViewCell {
    private let titleLabel = UILabel()
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func configureView() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        /// Title of the conversation.
        titleLabel.font = UIFont.normal(.subheadline)
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.accessibilityIdentifier = "ConversationCell.titleLable"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.bottomAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
    }
    
    public func setItem(_ item: TabRowModel) {
        titleLabel.text = item.links.joined(separator: "\n")
    }
}

//
//struct FilesTabView: View {
//    @StateObject var viewModel: DetailTabDownloaderViewModel
//
//    init(conversation: Conversation, messageType: ChatModels.MessageType) {
//        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "File"))
//    }
//
//    var body: some View {
//        LazyVStack {
//            ThreadTabDetailStickyHeaderSection(header: "", height:  4)
//                .onAppear {
//                    if viewModel.messagesModels.count == 0 {
//                        viewModel.loadMore()
//                    }
//                }
//            if viewModel.isLoading || viewModel.messagesModels.count > 0 {
//                MessageListFileView()
//                    .padding(.top, 8)
//                    .environmentObject(viewModel)
//            } else {
//                EmptyResultViewInTabs()
//            }
//        }
//    }
//}
//
//struct MessageListFileView: View {
//    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
//    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
//
//    var body: some View {
//        ForEach(viewModel.messagesModels) { model in
//            FileRowView(viewModel: detailViewModel)
//                .environmentObject(model)
//                .appyDetailViewContextMenu(FileRowView(viewModel: detailViewModel), model, detailViewModel)
//                .overlay(alignment: .bottom) {
//                    if model.message != viewModel.messagesModels.last?.message {
//                        Rectangle()
//                            .fill(Color.App.dividerPrimary)
//                            .frame(height: 0.5)
//                            .padding(.leading)
//                    }
//                }
//                .onAppear {
//                    if model.message == viewModel.messagesModels.last?.message {
//                        viewModel.loadMore()
//                    }
//                }
//        }
//        DetailLoading()
//    }
//}
//
//struct FileRowView: View {
//    @EnvironmentObject var rowModel: TabRowModel
//    let viewModel: ThreadDetailViewModel
//
//    var body: some View {
//        HStack {
//            TabDownloadProgressButton()
//            TabDetailsText(rowModel: rowModel)
//            Spacer()
//        }
//        .padding(.all)
//        .background(Color.App.bgPrimary)
//        .contentShape(Rectangle())
//        .sheet(isPresented: $rowModel.shareDownloadedFile) {
//            if let tempURL = rowModel.tempShareURL {
//                ActivityViewControllerWrapper(activityItems: [tempURL], title: rowModel.metadata?.file?.originalName)
//            }
//        }
//        .onTapGesture {
//            rowModel.onTap(viewModel: viewModel)
//        }
//    }
//}
//
//#if DEBUG
//struct FileView_Previews: PreviewProvider {
//    static let thread = MockData.thread
//
//    static var previews: some View {
//        FilesTabView(conversation: thread, messageType: .file)
//    }
//}
//#endif
