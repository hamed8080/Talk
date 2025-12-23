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
    var dataSource: UICollectionViewDiffableDataSource<PicturesListSection, PictureItem>!
    var cv: UICollectionView!
    let viewModel: DetailTabDownloaderViewModel
    static let resuableIdentifier = "PICTURE-ROW"
    static let nothingFoundIdentifier = "NOTHING-FOUND-PICTURE-ROW"
    private let onSelect: @Sendable (TabRowModel) -> Void
    
    init(viewModel: DetailTabDownloaderViewModel, onSelect: @Sendable @escaping (TabRowModel) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        cv = UICollectionView(frame: .zero, collectionViewLayout: createlayout())
        viewModel.picturesDelegate = self
        cv.register(PictureCell.self, forCellWithReuseIdentifier: PicturesCollectionViewController.resuableIdentifier)
//        cv.register(NothingFoundCell.self, forCellReuseIdentifier: PicturesCollectionViewController.nothingFoundIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        cv.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.allowsMultipleSelection = false
        cv.backgroundColor = .clear
        cv.isUserInteractionEnabled = true
        cv.allowsMultipleSelection = false
        cv.allowsSelection = true
        cv.showsHorizontalScrollIndicator = false
//        cv.contentInset = .init(top: 48, left: 0, bottom: 64, right: 0)
        
        view.addSubview(cv)
        
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.loadMore()
    }
    
    private func createlayout() -> UICollectionViewLayout {
        let fraction = 1.0 / 4.0

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(fraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(4)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        section.contentInsets = .zero
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension PicturesCollectionViewController {
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<PicturesListSection, PictureItem>(collectionView: cv) { [weak self] cv, indexPath, item -> UICollectionViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: PicturesCollectionViewController.resuableIdentifier,
                                                  for: indexPath) as? PictureCell
                
                // Set properties
                cell?.setItem(item)
                return cell
            case .noResult:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: PicturesCollectionViewController.nothingFoundIdentifier,
                                                  for: indexPath) as? NothingFoundCollectionViewCell
                return cell
            }
        }
    }
}

extension PicturesCollectionViewController: UIPicturesViewControllerDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<PicturesListSection, PictureItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateImage(id: Int, image: UIImage?) {
        if let cell = cell(id: id), let item = viewModel.messagesModels.first(where: { $0.id == id }) {
            cell.setItem(item)
        }
    }
    
    private func cell(id: Int) -> PictureCell? {
        guard let index = viewModel.messagesModels.firstIndex(where: { $0.id == id }) else { return nil }
        return cv.cellForItem(at: IndexPath(row: index, section: 0)) as? PictureCell
    }
}

extension PicturesCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .item(let item) = item {
            onSelect(item)
            dismiss(animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            let conversation = dataSource.itemIdentifier(for: indexPath),
            indexPath.row >= viewModel.messagesModels.count - 10
        else { return }
        Task {
            try await viewModel.loadMore()
        }
    }
}

class PictureCell: UICollectionViewCell {
    private var pictureView = UIImageView()
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func configureView() {
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        /// Title of the conversation.
        pictureView.translatesAutoresizingMaskIntoConstraints = false
        pictureView.accessibilityIdentifier = "PictureCell.pictureView"
        pictureView.contentMode = .scaleAspectFill
        pictureView.clipsToBounds = true
        contentView.addSubview(pictureView)
        
        NSLayoutConstraint.activate([
            pictureView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pictureView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pictureView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pictureView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    public func setItem(_ item: TabRowModel) {
        pictureView.image = item.thumbnailImage
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
