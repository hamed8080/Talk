//
//  MessageRowImageDownloader.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import Chat

struct MessageRowImageDownloader: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var uploadCompleted: Bool { message.uploadFile == nil || viewModel.uploadViewModel?.state == .completed }

    var body: some View {
        if !viewModel.isMapType, message.isImage, uploadCompleted, let downloadVM = viewModel.downloadFileVM {
            ZStack {
                if viewModel.downloadFileVM?.state != .completed {
                    PlaceholderImageView(width: viewModel.imageWidth, height: viewModel.imageHeight)
                    BlurThumbnailView(width: viewModel.imageWidth, height: viewModel.imageHeight, viewModel: downloadVM)
                    OverlayDownloadImageButton(message: message)
                } else {
                    RealDownloadedImage(width: viewModel.imageWidth, height: viewModel.imageHeight)
                }
            }
            .environmentObject(downloadVM)
            .clipped()
            .onReceive(NotificationCenter.default.publisher(for: .upload)) { notification in
                onUploadEventUpload(notification)
            }
            .onReceive(downloadVM.objectWillChange) { _ in
                viewModel.animateObjectWillChange()
            }
            .task {
                manageDownload()
            }
        }
    }

    private func onUploadEventUpload(_ notification: Notification) {
        guard
            let event = notification.object as? UploadEventTypes,
            case .completed(uniqueId: _, fileMetaData: _, data: _, error: _) = event,
            let downloadVM = viewModel.downloadFileVM,
            !downloadVM.isInCache,
            downloadVM.thumbnailData == nil || downloadVM.fileURL == nil
        else { return }
        downloadBlurImageWithDelay(downloadVM)
    }

    private func downloadBlurImageWithDelay(delay: TimeInterval = 1.0, _ downloadVM: DownloadFileViewModel) {
        /// We wait for 2 seconds to download the thumbnail image.
        /// If we upload the image for the first time we have to wait, due to a server process to make a thumbnail.
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            downloadVM.downloadBlurImage()
        }
    }

    private func manageDownload() {
        guard let downloadVM = viewModel.downloadFileVM else { return }
        if !downloadVM.isInCache, downloadVM.thumbnailData == nil {
            downloadVM.downloadBlurImage()
        } else if downloadVM.isInCache {
            downloadVM.state = .completed // it will set the state to complete and then push objectWillChange to call onReceive and start scale the image on the background thread
            downloadVM.animateObjectWillChange()
            viewModel.animateObjectWillChange()
        }
    }
}

struct PlaceholderImageView: View {
    let width: CGFloat
    let height: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel
    static let emptyImageGradient = LinearGradient(colors: [Color.App.bgInput, Color.App.bgInputDark], startPoint: .top, endPoint: .bottom)

    var body: some View {
        if viewModel.thumbnailData == nil, viewModel.state != .completed, let emptyImage = UIImage(named: "empty_image") {
            Image(uiImage: emptyImage)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .zIndex(0)
                .background(PlaceholderImageView.emptyImageGradient)
                .clipShape(RoundedRectangle(cornerRadius:(8)))
        }
    }
}

struct BlurThumbnailView: View {
    let width: CGFloat
    let height: CGFloat
    static let clearGradient = LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
    let viewModel: DownloadFileViewModel
    @State var hasShown: Bool = false

    var body: some View {
        /// Never delete this line hasShown is essential here we should always show the thumbnail image, whether we are downloading or showing the thumbnail.
        /// We use hasShown as a trick to force SwiftUI to redraw.
        Image(uiImage: hasShown ? image : image)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .blur(radius: 16, opaque: false)
            .clipped()
            .zIndex(0)
            .background(BlurThumbnailView.clearGradient)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .onReceive(viewModel.objectWillChange) { newValue in
                if hasShown == false, viewModel.state == .downloading || viewModel.state == .thumbnail, viewModel.thumbnailData != nil {
                    self.hasShown = true
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                AppState.shared.objectsContainer.appOverlayVM.galleryMessage = viewModel.message
            }
    }

    var image: UIImage {
        UIImage(data: viewModel.thumbnailData ?? Data()) ?? UIImage()
    }
}

struct RealDownloadedImage: View {
    let width: CGFloat
    let height: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @State var image = UIImage()

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: viewModel.state != .completed ? 0 : width, height: viewModel.state != .completed ? 0 : height)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .clipped()
            .onReceive(viewModel.objectWillChange) { _ in
                setImageOnBackground()
            }
            .task {
                setImageOnBackground()
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                AppState.shared.objectsContainer.appOverlayVM.galleryMessage = viewModel.message
            }
    }

    private func setImageOnBackground() {
        Task.detached {
            if await viewModel.state == .completed, let cgImage = await viewModel.fileURL?.imageScale(width: 420)?.image {
                await MainActor.run {
                    self.image = UIImage(cgImage: cgImage)
                }
            }
        }
    }
}

struct OverlayDownloadImageButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @EnvironmentObject var messageRowVM: MessageRowViewModel
    let message: Message?
    private var percent: Int64 { viewModel.downloadPercent }
    private var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        if viewModel.state != .completed {
            HStack {
                ZStack {
                    iconView
                    progress
                }
                .frame(width: 26, height: 26)
                .background(Color.App.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius:(13)))
                sizeView
            }
            .frame(height: 30)
            .frame(minWidth: 76)
            .padding(4)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius:(18)))
            .animation(.easeInOut, value: stateIcon)
            .animation(.easeInOut, value: percent)
            .onTapGesture {
                if viewModel.state == .paused {
                    viewModel.resumeDownload()
                } else if viewModel.state == .downloading {
                    viewModel.pauseDownload()
                } else {
                    viewModel.startDownload()
                }
            }
        }
    }

    private var iconView: some View {
        Image(systemName: stateIcon)
            .resizable()
            .scaledToFit()
            .font(.system(size: 8, design: .rounded).bold())
            .frame(width: 8, height: 8)
            .foregroundStyle(Color.App.text)
    }

    private var progress: some View {
        Circle()
            .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.App.white)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 18, height: 18)
    }

    @ViewBuilder private var sizeView: some View {
        if let fileSize = computedFileSize {
            Text(fileSize)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption2)
                .foregroundColor(Color.App.text)
        }
    }

    private var computedFileSize: String? {
        let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
        let realServerFileSize = messageRowVM.fileMetaData?.file?.size
        let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale)
        return fileSize
    }
}

struct MessageRowImageDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageDownloader()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
