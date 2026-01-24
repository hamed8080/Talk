//
//  VideosTableViewController.swift
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

class VideosTableViewController: UIViewController, TabControllerDelegate {
    var dataSource: UITableViewDiffableDataSource<VideosListSection, VideoItem>!
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
        viewModel.videosDelegate = self
        tableView.contentInset = .init(top: 0, left: 0, bottom: 128, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.register(VideoCell.self, forCellReuseIdentifier: VideoCell.identifier)
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

extension VideosTableViewController: UIViewControllerScrollDelegate {
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

extension VideosTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: VideoCell.identifier,
                    for: indexPath
                ) as? VideoCell
                
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

extension VideosTableViewController: UIVideosViewControllerDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<VideosListSection, VideoItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateProgress(item: TabRowModel) {
        if let cell = cell(id: item.id) {
            cell.updateProgress(item)
        }
    }
    
    private func cell(id: Int) -> VideoCell? {
        guard let index = viewModel.messagesModels.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? VideoCell
    }
}

extension VideosTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .item(let item) = item {
            
            if item.state.state == .completed, let fileURL = item.fileURL {
                let playerVM = VideoPlayerViewModel(fileURL: fileURL, ext: item.message.fileMetaData?.file?.mimeType?.ext)
                item.playerVM = playerVM
                item.playerVM?.toggle()
                item.playerVM?.animateObjectWillChange()
                if let player = playerVM.player {
                    let vc = UIHostingController(rootView: PlayerViewRepresentable(player: player, showFullScreen: .constant(true)))
                    vc.modalPresentationStyle = .fullScreen
                    present(vc, animated: true)
                }
            } else {
                onSelectDelegate?.onSelect(item: item)
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

extension VideosTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .item(model) = item
        else { return }
        let newCell = VideoCell(frame: .zero)
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

/// Bottom Loading
extension VideosTableViewController: TabLoadingDelegate {
    func startBottomAnimation(_ animate: Bool) {
        loadingManager.startBottomAnimation(animate)
    }
}

//
//struct VideosTabView: View {
//    @StateObject var viewModel: DetailTabDownloaderViewModel
//    
//    init(conversation: Conversation, messageType: ChatModels.MessageType) {
//        let vm = DetailTabDownloaderViewModel(conversation: conversation, messageType: messageType, tabName: "Video")
//        _viewModel = StateObject(wrappedValue: vm)
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
//                MessageListVideoView()
//                    .padding(.top, 8)
//                    .environmentObject(viewModel)
//            } else {
//                EmptyResultViewInTabs()
//            }
//        }
//    }
//}
//
//struct MessageListVideoView: View {
//    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
//    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
//
//    var body: some View {
//        ForEach(viewModel.messagesModels) { model in
//            VideoRowView(viewModel: detailViewModel)
//                .environmentObject(model)
//                .appyDetailViewContextMenu(VideoRowView(viewModel: detailViewModel), model, detailViewModel)
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
//struct VideoRowView: View {
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
//        .fullScreenCover(isPresented: $rowModel.showFullScreen) {
//            /// On dismiss
//            rowModel.playerVM?.player?.pause()
//        } content: {
//            if let player = rowModel.playerVM?.player {
//                PlayerViewRepresentable(player: player, showFullScreen: $rowModel.showFullScreen)
//            }
//        }
//        .onTapGesture {
//            rowModel.onTap(viewModel: viewModel)
//        }
//    }
//}
//
//#if DEBUG
//struct VideoView_Previews: PreviewProvider {
//    static let thread = MockData.thread
//
//    static var previews: some View {
//        VideosTabView(conversation: thread, messageType: .file)
//    }
//}
//#endif
