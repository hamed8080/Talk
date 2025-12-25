//
//  VoicesTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels

class VoicesTableViewController: UIViewController, TabControllerDelegate {
    var dataSource: UITableViewDiffableDataSource<VoicesListSection, VoiceItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: DetailTabDownloaderViewModel
    static let resuableIdentifier = "VOICE-ROW"
    static let nothingFoundIdentifier = "NOTHING-FOUND-VOICE-ROW"
    
    private var contextMenuContainer: ContextMenuContainerView?
    
    weak var detailVM: ThreadDetailViewModel?
    public weak var onSelectDelegate: TabRowItemOnSelectDelegate?
    
    init(viewModel: DetailTabDownloaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.voicesDelegate = self
        tableView.register(VoiceCell.self, forCellReuseIdentifier: VoicesTableViewController.resuableIdentifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: VoicesTableViewController.nothingFoundIdentifier)
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
        contextMenuContainer = .init(delegate: self)
        viewModel.loadMore()
    }
}

extension VoicesTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: VoicesTableViewController.resuableIdentifier,
                    for: indexPath
                ) as? VoiceCell
                
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
                    withIdentifier: VoicesTableViewController.nothingFoundIdentifier,
                    for: indexPath
                ) as? NothingFoundCell
                return cell
            }
        }
    }
}

extension VoicesTableViewController: UIVoicesViewControllerDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<VoicesListSection, VoiceItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateProgress(item: TabRowModel) {
        if let cell = cell(id: item.id) {
            cell.updateProgress(item)
        }
    }
    
    private func cell(id: Int) -> VoiceCell? {
        guard let index = viewModel.messagesModels.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? VoiceCell
    }
}

extension VoicesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .item(let item) = item {
            onSelectDelegate?.onSelect(item: item)
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

extension VoicesTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .item(model) = item
        else { return }
        let newCell = VoiceCell(frame: .zero)
        newCell.setItem(model)
        GeneralRowContextMenuUIKit.showGeneralContextMenuRow(newCell: newCell,
                                                             tb: tableView,
                                                             model: model,
                                                             detailVM: detailVM,
                                                             contextMenuContainer: contextMenuContainer,
                                                             showFileShareSheet: model.state.state == .completed,
                                                             parentVC: self,
                                                             indexPath: indexPath
        )
    }
    
    func dismissContextMenu(indexPath: IndexPath?) {
        
    }
}

//
//struct VoicesTabView: View {
//    @StateObject var viewModel: DetailTabDownloaderViewModel
//
//    init(conversation: Conversation, messageType: ChatModels.MessageType) {
//        _viewModel =  StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "Voice"))
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
//
//            if viewModel.isLoading || viewModel.messagesModels.count > 0 {
//                MessageListVoiceView()
//                    .padding(.top, 8)
//                    .environmentObject(viewModel)
//            } else {
//                EmptyResultViewInTabs()
//            }
//        }
//    }
//}
//
//struct MessageListVoiceView: View {
//    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
//    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
//
//    var body: some View {
//        ForEach(viewModel.messagesModels) { model in
//            VoiceRowView(viewModel: detailViewModel)
//                .environmentObject(model)
//                .appyDetailViewContextMenu(VoiceRowView(viewModel: detailViewModel), model, detailViewModel)
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
//struct VoiceRowView: View {
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
//        .contentShape(Rectangle())
//        .background(Color.App.bgPrimary)
//        .onTapGesture {
//            rowModel.onTap(viewModel: viewModel)
//        }
//    }
//}
//
//#if DEBUG
//struct VoiceView_Previews: PreviewProvider {
//    static var previews: some View {
//        VoicesTabView(conversation: MockData.thread, messageType: .podSpaceVoice)
//    }
//}
//#endif
