//
//  LinksTableViewController.swift
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

class LinksTableViewController: UIViewController, TabControllerDelegate {
    var dataSource: UITableViewDiffableDataSource<LinksListSection, LinkItem>!
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
        viewModel.linksDelegate = self
        tableView.register(LinkCell.self, forCellReuseIdentifier: LinkCell.identifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: NothingFoundCell.identifier)
        tableView.contentInset = .init(top: 0, left: 0, bottom: 128, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
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
        contextMenuContainer = .init(delegate: self)
        viewModel.loadMore()
    }
}

extension LinksTableViewController: UIViewControllerScrollDelegate {
    func getInternalScrollView() -> UIScrollView {
        return tableView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.onChildViewDidScrolled(scrollView)
    }
}

extension LinksTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: LinkCell.identifier,
                    for: indexPath
                ) as? LinkCell
                
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

extension LinksTableViewController: UILinksViewControllerDelegate {
   
    func apply(snapshot: NSDiffableDataSourceSnapshot<LinksListSection, LinkItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func cell(id: Int) -> LinkCell? {
        guard let index = viewModel.messagesModels.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? LinkCell
    }
}

extension LinksTableViewController: UITableViewDelegate {
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

extension LinksTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .item(model) = item
        else { return }
        let newCell = LinkCell(frame: .zero)
        newCell.setItem(model)
        GeneralRowContextMenuUIKit.showGeneralContextMenuRow(newCell: newCell,
                                                             tb: tableView,
                                                             model: model,
                                                             detailVM: detailVM,
                                                             contextMenuContainer: contextMenuContainer,
                                                             showFileShareSheet: false,
                                                             parentVC: self,
                                                             indexPath: indexPath
        )
    }
    
    func dismissContextMenu(indexPath: IndexPath?) {
        
    }
}

/// Bottom Loading
extension LinksTableViewController: TabLoadingDelegate {
    func startBottomAnimation(_ animate: Bool) {
        loadingManager.startBottomAnimation(animate)
    }
}

//
//struct LinksTabView: View {
//    @StateObject var viewModel: DetailTabDownloaderViewModel
//
//    init(conversation: Conversation, messageType: ChatModels.MessageType) {
//        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "Link"))
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
//                MessageListLinkView()
//                    .padding(.top, 8)
//                    .environmentObject(viewModel)
//            } else {
//                EmptyResultViewInTabs()
//            }
//        }
//    }
//}
//
//struct MessageListLinkView: View {
//    @EnvironmentObject var threadDetailVM: ThreadDetailViewModel
//    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
//    @State var viewWidth: CGFloat = 0
//
//    var body: some View {
//        ForEach(viewModel.messagesModels) { model in
//            LinkRowView()
//                .environmentObject(model)
//                .overlay(alignment: .bottom) {
//                    if model.id != viewModel.messagesModels.last?.id {
//                        Rectangle()
//                            .fill(Color.App.textSecondary.opacity(0.3))
//                            .frame(height: 0.5)
//                            .padding(.leading)
//                    }
//                }
//                .background(frameReader)
//                .appyDetailViewContextMenu(LinkRowView().background(MixMaterialBackground()), model, threadDetailVM)
//                .onAppear {
//                    if model.id == viewModel.messagesModels.last?.id {
//                        viewModel.loadMore()
//                    }
//                }
//        }
//        DetailLoading()
//    }
//
//    private var frameReader: some View {
//        GeometryReader { reader in
//            Color.clear.onAppear {
//                self.viewWidth = reader.size.width
//            }
//        }
//    }
//}
//
//struct LinkRowView: View {
//    @EnvironmentObject var viewModel: ThreadDetailViewModel
//    @EnvironmentObject var rowModel: TabRowModel
//
//    var body: some View {
//        HStack {
//            Rectangle()
//                .fill(Color.App.textSecondary)
//                .frame(width: 36, height: 36)
//                .clipShape(RoundedRectangle(cornerRadius:(8)))
//                .overlay(alignment: .center) {
//                    Image(systemName: "link")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 16, height: 16)
//                        .foregroundStyle(Color.App.textPrimary)
//                }
//            VStack(alignment: .leading, spacing: 2) {
//                if let smallText = rowModel.smallText {
//                    Text(smallText)
//                        .font(.fBody)
//                        .foregroundStyle(Color.App.textPrimary)
//                        .lineLimit(1)
//                }
//                ForEach(rowModel.links, id: \.self) { link in
//                    Text(verbatim: link)
//                        .font(.fBody)
//                        .foregroundStyle(Color.App.accent)
//                }
//            }
//            Spacer()
//        }
//        .padding()
//        .contentShape(Rectangle())
//        .onTapGesture {
//            rowModel.moveToMessage(viewModel)
//        }
//    }
//}
//
//#if DEBUG
//struct LinkView_Previews: PreviewProvider {
//    static var previews: some View {
//        LinksTabView(conversation: MockData.thread, messageType: .link)
//    }
//}
//#endif
