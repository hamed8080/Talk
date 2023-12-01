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
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var uploadCompleted: Bool { message.uploadFile == nil || viewModel.uploadViewModel?.state == .completed }

    var body: some View {
        if message.isImage, uploadCompleted, let downloadVM = viewModel.downloadFileVM {
            ZStack {
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                let width = max(128, (viewModel.maxWidth ?? 0)) - (8 + MessageRowBackground.tailSize.width)
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                /// We use min to prevent the image gets bigger than 320 if it's bigger.
                let height = min(320, max(128, (viewModel.maxWidth ?? 0)))
                PlaceholderImageView(width: width, height: height)
                    .environmentObject(downloadVM)
                BlurThumbnailView(width: width, height: height, viewModel: downloadVM)
                    .environmentObject(downloadVM)
                RealDownloadedImage(width: width, height: height)
                    .environmentObject(downloadVM)
                OverlayDownloadImageButton(message: message)
                    .environmentObject(downloadVM)
            }
            .onTapGesture {
                AppState.shared.objectsContainer.appOverlayVM.galleryMessage = message
            }
            .onReceive(NotificationCenter.default.publisher(for: .upload)) { notification in
                guard
                    let event = notification.object as? UploadEventTypes,
                    case .completed(uniqueId: _, fileMetaData: _, data: _, error: _) = event,
                    !downloadVM.isInCache,
                    downloadVM.thumbnailData == nil || downloadVM.fileURL == nil
                else { return }
                downloadBlurImageWithDelay(downloadVM)
            }
            .task {
                if !downloadVM.isInCache, downloadVM.thumbnailData == nil {
                    downloadVM.downloadBlurImage(quality: 0.5, size: .SMALL)
                }
            }
        }
    }

    private func downloadBlurImageWithDelay(delay: TimeInterval = 2.0, _ downloadVM: DownloadFileViewModel) {
        /// We wait for 2 seconds to download the thumbnail image.
        /// If we upload the image for the first time we have to wait, due to a server process to make a thumbnail.
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            downloadVM.downloadBlurImage(quality: 0.5, size: .SMALL)
        }
    }
}

struct PlaceholderImageView: View {
    let width: CGFloat
    let height: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel
    private static let emptyImageGradient = LinearGradient(colors: [Color.App.bgInput, Color.App.bgInputDark], startPoint: .top, endPoint: .bottom)

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
    }

    var image: UIImage {
        UIImage(data: viewModel.thumbnailData ?? Data()) ?? UIImage()
    }
}

struct RealDownloadedImage: View {
    let width: CGFloat
    let height: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel

    var body: some View {
        if viewModel.state == .completed, let cgImage = viewModel.fileURL?.imageScale(width: 420)?.image {
            Image(uiImage: UIImage(cgImage: cgImage))
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius:(8)))
                .clipped()
        }
    }
}

struct OverlayDownloadImageButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    let message: Message?
    var percent: Int64 { viewModel.downloadPercent }
    var stateIcon: String {
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
                    Image(systemName: stateIcon)
                        .resizable()
                        .scaledToFit()
                        .font(.system(size: 8, design: .rounded).bold())
                        .frame(width: 8, height: 8)
                        .foregroundStyle(Color.App.text)

                    Circle()
                        .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.App.white)
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: 18, height: 18)
                }
                .frame(width: 26, height: 26)
                .background(Color.App.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius:(13)))

                let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
                let realServerFileSize = message?.fileMetaData?.file?.size
                if let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale) {
                    Text(fileSize)
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldCaption2)
                        .foregroundColor(Color.App.text)
                }
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
}

struct MessageRowImageDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageDownloader(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}