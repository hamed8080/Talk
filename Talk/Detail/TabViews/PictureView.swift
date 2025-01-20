//
//  PictureView.swift
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
import ActionableContextMenu
import TalkModels

struct PictureView: View {
    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
    @StateObject var viewModel: DetailTabDownloaderViewModel
    @State var viewWidth: CGFloat = 0

    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        let vm = DetailTabDownloaderViewModel(conversation: conversation, messageType: messageType, tabName: "Picture")
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
            if viewWidth != 0 {
                MessageListPictureView(itemWidth: abs(itemWidth))
            }
        }
        .padding(padding)
        .environmentObject(viewModel)
        .background(frameReader)
        .overlay(alignment: .top) {
            emptyTabView
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
        return 16
    }

    private var itemWidth: CGFloat {
        let viewWidth = viewWidth - padding
        let itemWidthWithouthSpacing = viewModel.itemWidth(readerWidth: viewWidth)
        let itemWidth = itemWidthWithouthSpacing - spacing
        return itemWidth
    }

    private func onLoad() {
        if viewModel.messages.count == 0 {
            viewModel.loadMore()
        }
    }

    private var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                self.viewWidth = reader.size.width
            }
        }
    }

    @ViewBuilder
    private var emptyTabView: some View {
        if isEmptyTab {
            HStack {
                Spacer()
                EmptyResultViewInTabs()
                    .padding(.top, 9)
                Spacer()
            }
        }
    }

    private var isEmptyTab: Bool {
        !viewModel.isLoading && viewModel.messages.count == 0 && (!viewModel.hasNext || detailViewModel.threadVM?.isSimulatedThared == true)
    }
}

struct MessageListPictureView: View {
    let itemWidth: CGFloat
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            PictureRowView(message: message, itemWidth: itemWidth)
                .environmentObject(viewModel.downloadVM(message: message))
                .id(message.id)
                .frame(width: itemWidth, height: itemWidth)
                .onAppear {
                    if viewModel.isCloseToLastThree(message) {
                        viewModel.loadMore()
                    }
                }
        }
        DetailLoading()
    }
}

struct PictureRowView: View {
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @EnvironmentObject var contextVM: ContextMenuModel

    let message: Message
    let itemWidth: CGFloat
    var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        DownloadPictureButtonView(itemWidth: itemWidth)
            .frame(width: itemWidth, height: itemWidth)
            .clipped()
            .onTapGesture {
                onTapped()
            }
            .newCustomContextMenu {
                PictureRowView(message: message, itemWidth: itemWidth)
                    .disabled(true)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } menus: {
                contextMenuView
            }
    }

    private func onTapped() {
        if !contextVM.isPresented {
            AppState.shared.objectsContainer.appOverlayVM.galleryMessage = message
        }
    }

    private var contextMenuView: some View {
        VStack {
            ContextMenuButton(title: "General.showMessage".bundleLocalized(), image: "message.fill") {
                Task {
                    await threadVM?.historyVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
                    viewModel.dismiss = true
                }
            }
        }
        .foregroundColor(.primary)
        .frame(width: 196)
        .background(MixMaterialBackground())
        .clipShape(RoundedRectangle(cornerRadius:((12))))
    }
}

struct DownloadPictureButtonView: View {
    let itemWidth: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel
    private var message: Message? { viewModel.message }
    @State private var scaledImage: UIImage?

    var body: some View {
        switch viewModel.state {
        case .completed:
            scaledImageView
        case .undefined, .thumbnail:
            thumbnailView
        default:
            emptyImageView
        }
    }

    @ViewBuilder
    private var scaledImageView: some View {
        Image(uiImage: scaledImage ?? UIImage())
            .resizable()
            .frame(width: itemWidth, height: itemWidth)
            .scaledToFit()
            .clipped()
            .transition(.opacity)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onAppear {
                /// After downloading the image inside the gallery,
                /// the scaledImage is nil and it shuould be calculate again.
                if scaledImage == nil {
                    Task {
                        await prepareThumbnail()
                    }
                }
            }
    }

    private var thumbnailView: some View {
        ZStack {
            if let data = viewModel.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: itemWidth, height: itemWidth)
                    .clipped()
                    .zIndex(0)
                    .background(Color.App.dividerSecondary)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
                    .contentShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: itemWidth, height: itemWidth)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .transition(.opacity)
        .task {
            await prepareThumbnail()
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

    private func prepareThumbnail() async {
        await viewModel.setup()
        if viewModel.isInCache {
            let scaledImage = await scaledImage(url: viewModel.fileURL)
            viewModel.state = .completed
            self.scaledImage = scaledImage
            viewModel.animateObjectWillChange()
        } else {
            if message?.isImage == true, !viewModel.isInCache, viewModel.thumbnailData == nil {
                viewModel.downloadBlurImage(quality: 1.0, size: .MEDIUM)
            }
        }
    }
    
    @AppBackgroundActor
    private func scaledImage(url: URL?) async -> UIImage? {
        if let fileURL = url, let scaledImage = fileURL.imageScale(width: 128)?.image {
            return UIImage(cgImage: scaledImage)
        }
        return nil
    }
}

struct PictureView_Previews: PreviewProvider {
    static var previews: some View {
        PictureView(conversation: MockData.thread, messageType: .podSpacePicture)
    }
}
