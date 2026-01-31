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
import TalkUI
import Lottie

class FilesTableViewController: UIViewController, TabControllerDelegate {
    var dataSource: UITableViewDiffableDataSource<FilesListSection, FileItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: DetailTabDownloaderViewModel
    private let loadingManager = TabLoadingManager()
    
    private var contextMenuContainer: ContextMenuContainerView?
    
    weak var detailVM: ThreadDetailViewModel?
    public weak var scrollDelegate: UIChildViewScrollDelegate?
    public weak var onSelectDelegate: TabRowItemOnSelectDelegate?
    
    init(viewModel: DetailTabDownloaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.filesDelegate = self
        tableView.contentInset = .init(top: 0, left: 0, bottom: 128, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.register(FileCell.self, forCellReuseIdentifier: FileCell.identifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: NothingFoundCell.identifier)
        loadingManager.configureBottomLoading(tableView)
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
        contextMenuContainer = .init(delegate: self, vc: parentVC)
        viewModel.loadMore()
    }
}

extension FilesTableViewController: UIViewControllerScrollDelegate {
    func getInternalScrollView() -> UIScrollView {
        return tableView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.onChildViewDidScrolled(scrollView)
    }
    
    func setBottomInset(_ inset: CGFloat) {
        tableView.contentInset.bottom = inset
    }
}

extension FilesTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: FileCell.identifier,
                    for: indexPath
                ) as? FileCell
                
                // Set properties
                cell?.setItem(item)
                cell?.onContextMenu = { [weak self] sender in
                    guard let self = self else { return }
                    if sender.state == .began {
                        let index = viewModel.messagesModels.firstIndex(where: { $0.id == item.id })
                        if let index = index, viewModel.messagesModels[index].id != AppState.shared.user?.id {
                            showContextMenu(IndexPath(row: index, section: indexPath.section), contentView: UIView())
                        }
                    }
                }
                return cell
            case .noResult:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: NothingFoundCell.identifier,
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
    
    func updateProgress(item: TabRowModel) {
        if let cell = cell(id: item.id) {
            cell.updateProgress(item)
        }
    }
    
    private func cell(id: Int) -> FileCell? {
        guard let index = viewModel.messagesModels.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FileCell
    }
    
    func startBottomAnimation(_ animate: Bool) {
        loadingManager.startBottomAnimation(animate)
    }
}

extension FilesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .item(let model) = item {
            if model.state.state == .completed {
                Task { await model.presentShareSheet(parentVC: self) }
            } else {
                onSelectDelegate?.onSelect(item: model)
            }
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

extension FilesTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .item(model) = item
        else { return }
        let newCell = FileCell(frame: .zero)
        newCell.setItem(model)
        GeneralRowContextMenuUIKit.showGeneralContextMenuRow(newCell: newCell,
                                                             tb: tableView,
                                                             model: model,
                                                             detailVM: detailVM,
                                                             contextMenuContainer: contextMenuContainer,
                                                             showFileShareSheet: model.state.state == .completed,
                                                             parentVC: parentVC,
                                                             indexPath: indexPath
        )
    }
    
    private var parentVC: UIViewController {
        return AppState.shared.objectsContainer.navVM.splitVC ?? self
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
