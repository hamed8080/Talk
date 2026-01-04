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

class PicturesCollectionViewController: UIViewController, TabControllerDelegate {
    var dataSource: UICollectionViewDiffableDataSource<PicturesListSection, PictureItem>!
    var cv: UICollectionView!
    var flowLayoutManager: PictureCollectionViewLayout
    let viewModel: DetailTabDownloaderViewModel
    
    private var contextMenuContainer: ContextMenuContainerView?
    
    weak var detailVM: ThreadDetailViewModel?
    public weak var scrollDelegate: UIChildViewScrollDelegate?
    public weak var onSelectDelegate: TabRowItemOnSelectDelegate?
    
    init(viewModel: DetailTabDownloaderViewModel) {
        self.viewModel = viewModel
        self.flowLayoutManager = .init(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
        cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayoutManager.createlayout())
        viewModel.picturesDelegate = self
        cv.contentInset = .init(top: 8, left: 0, bottom: 132, right: 0)
        cv.scrollIndicatorInsets = cv.contentInset
        cv.register(PictureCell.self, forCellWithReuseIdentifier: PictureCell.identifier)
        cv.register(NothingFoundCollectionViewCell.self, forCellWithReuseIdentifier: NothingFoundCollectionViewCell.identifier)
        cv.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.identifier
        )
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
        cv.allowsSelection = true
        cv.showsHorizontalScrollIndicator = false
        
        view.addSubview(cv)
        
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
        ])
        configureDataSource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contextMenuContainer = .init(delegate: self, vc: parentVC)
        viewModel.loadMore()
    }
}

extension PicturesCollectionViewController: UIViewControllerScrollDelegate {
    func getInternalScrollView() -> UIScrollView {
        return cv
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.onChildViewDidScrolled(scrollView)
    }
    
    func setBottomInset(_ inset: CGFloat) {
        cv.contentInset.bottom = inset
    }
}

extension PicturesCollectionViewController {
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<PicturesListSection, PictureItem>(collectionView: cv) { [weak self] cv, indexPath, item -> UICollectionViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .item(let item):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: PictureCell.identifier,
                                                  for: indexPath) as? PictureCell
                
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
                let cell = cv.dequeueReusableCell(withReuseIdentifier: NothingFoundCollectionViewCell.identifier,
                                                  for: indexPath) as? NothingFoundCollectionViewCell
                return cell
            }
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (cv, kind, indexPath) -> UICollectionReusableView? in
            guard kind == UICollectionView.elementKindSectionFooter else { return UICollectionReusableView() }
            return cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingFooterView.identifier, for: indexPath)
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
            onSelectDelegate?.onSelect(item: item)
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

extension PicturesCollectionViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .item(model) = item,
            let cell = cv.cellForItem(at: indexPath) as? PictureCell
        else { return }
        
        let pictureView = cell.makePictureView()
        GeneralRowContextMenuUIKit.showGeneralContextMenuRow(view: pictureView,
                                                             model: model,
                                                             detailVM: detailVM,
                                                             contextMenuContainer: contextMenuContainer,
                                                             showFileShareSheet: true,
                                                             parentVC: parentVC,
                                                             indexPath: indexPath
        )
    }
    
    func dismissContextMenu(indexPath: IndexPath?) {
        
    }
    
    private var parentVC: UIViewController {
        let isCollapsed = AppState.shared.objectsContainer.navVM.splitVC?.isCollapsed == true
        let parent = isCollapsed ? AppState.shared.objectsContainer.navVM.splitVC ?? self : self
        return parent
    }
}

extension PicturesCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        viewModel.isLoading ? CGSize(width: collectionView.bounds.width, height: 44) : .zero
    }
}

/// Bottom Loading
extension PicturesCollectionViewController: TabLoadingDelegate {
    func startBottomAnimation(_ animate: Bool) {
        if animate {
            cv.performBatchUpdates {
                  // no-op: forces layout refresh
              }
        }
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
