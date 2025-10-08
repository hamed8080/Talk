//
//  PicturesTabView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions
import TalkModels

struct PicturesTabView: View {
    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
    @StateObject var viewModel: DetailTabDownloaderViewModel
    let maxWidth: CGFloat

    init(conversation: Conversation, messageType: ChatModels.MessageType, maxWidth: CGFloat) {
        self.maxWidth = maxWidth
        let vm = DetailTabDownloaderViewModel(conversation: conversation, messageType: messageType, tabName: "Picture")
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
            ForEach(viewModel.messagesModels) { model in
                PictureRowView(itemWidth: itemWidth)
                    .environmentObject(model)
                    .appyDetailViewContextMenu(PictureRowView(itemWidth: itemWidth), model, detailViewModel)
                    .id(model.id)
                    .frame(width: itemWidth, height: itemWidth)
                    .onAppear {
                        if viewModel.isCloseToLastThree(model.message) {
                            viewModel.loadMore()
                        }
                    }
            }
        }
        .frame(maxWidth: maxWidth)
        .environment(\.layoutDirection, .leftToRight)
        .padding(padding)
        .environmentObject(viewModel)
        .overlay(alignment: .top) {
            if isEmptyTab {
                EmptyResultViewInTabs()
                    .padding(.top, 10)
            }
        }
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                HStack {
                    DetailLoading()
                        .environmentObject(viewModel)
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            onLoad() //it is essential to kick of onload
        }
    }

    private var columns: Array<GridItem> {
        let flexible = GridItem.Size.flexible(minimum: itemWidth, maximum: itemWidth)
        let item = GridItem(flexible,spacing: spacing)
        return Array(repeating: item, count: viewModel.itemCount)
    }

    private var spacing: CGFloat {
        return 8
    }

    private var padding: CGFloat {
        return isEmptyTab ? 0 : 16
    }

    private var itemWidth: CGFloat {
        let viewWidth = maxWidth - padding
        let itemWidthWithouthSpacing = viewModel.itemWidth(readerWidth: viewWidth)
        let itemWidth = itemWidthWithouthSpacing - spacing
        return itemWidth
    }

    private func onLoad() {
        if viewModel.messagesModels.count == 0 {
            viewModel.loadMore()
        }
    }

    private var isEmptyTab: Bool {
        !viewModel.isLoading && viewModel.messagesModels.count == 0 && (!viewModel.hasNext || detailViewModel.threadVM?.isSimulatedThared == true)
    }
}

struct PictureRowView: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @EnvironmentObject var rowModel: TabRowModel

    let itemWidth: CGFloat
    var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        thumbnailImageView
            .frame(width: itemWidth, height: itemWidth)
            .clipped()
            .onTapGesture {
                rowModel.onTap(viewModel: viewModel)
            }
    }
    
    private var thumbnailImageView: some View {
        Image(uiImage: rowModel.thumbnailImage ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: itemWidth, height: itemWidth)
            .clipped()
            .background(Color.App.dividerSecondary)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .transition(.opacity)
            .animation(.easeInOut, value: rowModel.thumbnailImage)
            .task {
                await rowModel.prepareThumbnail()
            }
            .overlay(alignment: .center) {
                if rowModel.thumbnailImage == nil {
                    emptyImageView
                }
            }
    }
    
    private var emptyImageView: some View {
        Rectangle()
            .fill(Color.App.bgSecondary)
            .frame(width: itemWidth, height: itemWidth)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .transition(.opacity)
    }
}

#if DEBUG
struct PictureView_Previews: PreviewProvider {
    static var previews: some View {
        PicturesTabView(conversation: MockData.thread, messageType: .podSpacePicture, maxWidth: 500)
    }
}
#endif
