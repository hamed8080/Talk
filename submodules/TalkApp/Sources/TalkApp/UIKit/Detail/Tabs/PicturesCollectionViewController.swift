//
//  PicturesCollectionViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels

class PicturesCollectionViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<PicturesListSection, PictureItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: DetailTabDownloaderViewModel
    static let resuableIdentifier = "PICTURE-ROW"
    static let nothingFoundIdentifier = "NOTHING-FOUND-PICTURE-ROW"
    private let onSelect: @Sendable (TabRowModel) -> Void
    
    init(viewModel: DetailTabDownloaderViewModel, onSelect: @Sendable @escaping (TabRowModel) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        viewModel.picturesDelegate = self
        tableView.register(PictureCell.self, forCellReuseIdentifier: PicturesCollectionViewController.resuableIdentifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: PicturesCollectionViewController.nothingFoundIdentifier)
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

extension PicturesCollectionViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: PicturesCollectionViewController.resuableIdentifier,
                    for: indexPath
                ) as? PictureCell
                
                // Set properties
                cell?.setItem(item)
                return cell
            case .noResult:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: PicturesCollectionViewController.nothingFoundIdentifier,
                    for: indexPath
                ) as? NothingFoundCell
                return cell
            }
        }
    }
}

extension PicturesCollectionViewController: UIPicturesViewControllerDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<PicturesListSection, PictureItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func cell(id: Int) -> PictureCell? {
        guard let index = viewModel.messagesModels.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PictureCell
    }
}

extension PicturesCollectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .item(let item) = item {
            onSelect(item)
            dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        Task {
            try await viewModel.loadMore()
        }
    }
}

class PictureCell: UITableViewCell {
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
        titleLabel.font = UIFont.fSubheadline
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
//struct PicturesTabView: View {
//    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
//    @StateObject var viewModel: DetailTabDownloaderViewModel
//    let maxWidth: CGFloat
//
//    init(conversation: Conversation, messageType: ChatModels.MessageType, maxWidth: CGFloat) {
//        self.maxWidth = maxWidth
//        let vm = DetailTabDownloaderViewModel(conversation: conversation, messageType: messageType, tabName: "Picture")
//        _viewModel = StateObject(wrappedValue: vm)
//    }
//
//    var body: some View {
//        StickyHeaderSection(header: "", height:  4)
//        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
//            ForEach(viewModel.messagesModels) { model in
//                PictureRowView(itemWidth: itemWidth)
//                    .environmentObject(model)
//                    .appyDetailViewContextMenu(PictureRowView(itemWidth: itemWidth), model, detailViewModel)
//                    .id(model.id)
//                    .frame(width: itemWidth, height: itemWidth)
//                    .onAppear {
//                        if viewModel.isCloseToLastThree(model.message) {
//                            viewModel.loadMore()
//                        }
//                    }
//            }
//        }
//        .frame(maxWidth: maxWidth)
//        .environment(\.layoutDirection, .leftToRight)
//        .padding(padding)
//        .environmentObject(viewModel)
//        .overlay(alignment: .top) {
//            if isEmptyTab {
//                EmptyResultViewInTabs()
//                    .padding(.top, 10)
//            }
//        }
//        .overlay(alignment: .center) {
//            if viewModel.isLoading {
//                HStack {
//                    DetailLoading()
//                        .environmentObject(viewModel)
//                }
//                .padding(.top, 16)
//            }
//        }
//        .onAppear {
//            onLoad() //it is essential to kick of onload
//        }
//    }
//
//    private var columns: Array<GridItem> {
//        let flexible = GridItem.Size.flexible(minimum: itemWidth, maximum: itemWidth)
//        let item = GridItem(flexible,spacing: spacing)
//        return Array(repeating: item, count: viewModel.itemCount)
//    }
//
//    private var spacing: CGFloat {
//        return 8
//    }
//
//    private var padding: CGFloat {
//        return isEmptyTab ? 0 : 16
//    }
//
//    private var itemWidth: CGFloat {
//        let viewWidth = maxWidth - padding
//        let itemWidthWithouthSpacing = viewModel.itemWidth(readerWidth: viewWidth)
//        let itemWidth = itemWidthWithouthSpacing - spacing
//        return itemWidth
//    }
//
//    private func onLoad() {
//        if viewModel.messagesModels.count == 0 {
//            viewModel.loadMore()
//        }
//    }
//
//    private var isEmptyTab: Bool {
//        !viewModel.isLoading && viewModel.messagesModels.count == 0 && (!viewModel.hasNext || detailViewModel.threadVM?.isSimulatedThared == true)
//    }
//}
//
//struct PictureRowView: View {
//    @EnvironmentObject var viewModel: ThreadDetailViewModel
//    @EnvironmentObject var rowModel: TabRowModel
//
//    let itemWidth: CGFloat
//    var threadVM: ThreadViewModel? { viewModel.threadVM }
//
//    var body: some View {
//        thumbnailImageView
//            .frame(width: itemWidth, height: itemWidth)
//            .clipped()
//            .onTapGesture {
//                rowModel.onTap(viewModel: viewModel)
//            }
//    }
//    
//    private var thumbnailImageView: some View {
//        Image(uiImage: rowModel.thumbnailImage ?? UIImage())
//            .resizable()
//            .scaledToFill()
//            .frame(width: itemWidth, height: itemWidth)
//            .clipped()
//            .background(Color.App.dividerSecondary)
//            .clipShape(RoundedRectangle(cornerRadius:(8)))
//            .contentShape(RoundedRectangle(cornerRadius: 8))
//            .transition(.opacity)
//            .animation(.easeInOut, value: rowModel.thumbnailImage)
//            .task {
//                await rowModel.prepareThumbnail()
//            }
//            .overlay(alignment: .center) {
//                if rowModel.thumbnailImage == nil {
//                    emptyImageView
//                }
//            }
//    }
//    
//    private var emptyImageView: some View {
//        Rectangle()
//            .fill(Color.App.bgSecondary)
//            .frame(width: itemWidth, height: itemWidth)
//            .clipShape(RoundedRectangle(cornerRadius:(8)))
//            .contentShape(RoundedRectangle(cornerRadius: 8))
//            .transition(.opacity)
//    }
//}
//
//#if DEBUG
//struct PictureView_Previews: PreviewProvider {
//    static var previews: some View {
//        PicturesTabView(conversation: MockData.thread, messageType: .podSpacePicture, maxWidth: 500)
//    }
//}
//#endif
