//
//  MessageRowImageView.swift
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

struct MessageRowImageView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        ZStack {
            if showImage {
                Image(uiImage: viewModel.calculatedMessage.image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: viewModel.sizes.imageWidth, maxHeight: viewModel.sizes.imageHeight)
                    .clipped()
                    .zIndex(0)
                    .background(gradient)
                    .blur(radius: viewModel.sizes.blurRadius ?? 0, opaque: false)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
                    .onTapGesture {
                        viewModel.onTap()
                    }
                if let downloadVM = viewModel.downloadFileVM, downloadVM.state != .completed {
                    OverlayDownloadImageButton(message: message)
                        .environmentObject(downloadVM)
                }
            }

            if showUpload {
                UploadMessageImageView(viewModel: viewModel)
            }
        }
        .padding(.top, viewModel.sizes.paddings.fileViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        .clipped()
    }

    private var showImage: Bool {
        (message.uploadFile == nil || viewModel.uploadViewModel?.state == .completed) && !viewModel.state.isPreparingThumbnailImageForUploadedImage
    }

    private var showUpload: Bool {
        message.uploadFile?.uploadImageRequest != nil || viewModel.state.isPreparingThumbnailImageForUploadedImage
    }

    private static let clearGradient = LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
    private static let emptyImageGradient = LinearGradient(
        colors: [
            Color.App.bgPrimary.opacity(0.2),
            Color.App.bgPrimary.opacity(0.3),
            Color.App.bgPrimary.opacity(0.4),
            Color.App.bgPrimary.opacity(0.5),
            Color.App.bgPrimary.opacity(0.6),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private var gradient: LinearGradient {
        let clearState = viewModel.downloadFileVM?.state == .completed || viewModel.downloadFileVM?.state == .thumbnail
        return clearState ? MessageRowImageView.clearGradient : MessageRowImageView.emptyImageGradient
    }
}

struct OverlayDownloadImageButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @EnvironmentObject var messageRowVM: MessageRowViewModel
    let message: Message?
    private var percent: Int64 { viewModel.downloadPercent }
    private var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        if viewModel.state != .completed {
            Button {
                manageDownload()
            } label: {
                HStack {
                    ZStack {
                        iconView
                        progress
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.App.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius:(18)))
                    sizeView
                }
                .frame(height: 36)
                .frame(minWidth: 76)
                .padding(4)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
            .animation(.easeInOut, value: stateIcon)
            .animation(.easeInOut, value: percent)
            .buttonStyle(.borderless)
        }
    }

    private var iconView: some View {
        Image(systemName: stateIcon)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .font(.system(size: 14, design: .rounded))
            .fontWeight(viewModel.state == .downloading ? .semibold : .regular)
            .frame(width: 14, height: 14)
            .foregroundStyle(Color.App.textPrimary)
    }

    private var progress: some View {
        Circle()
            .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.App.white)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 34, height: 34)
            .rotateAnimtion(pause: viewModel.state == .paused)
    }

    @ViewBuilder private var sizeView: some View {
        if let fileSize = messageRowVM.calculatedMessage.computedFileSize {
            Text(fileSize)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption2)
                .foregroundColor(Color.App.textPrimary)
        }
    }

    private func manageDownload() {
        if viewModel.state == .paused {
            viewModel.resumeDownload()
        } else if viewModel.state == .downloading {
            viewModel.pauseDownload()
        } else {
            viewModel.startDownload()
        }
    }
}

public struct UploadMessageImageView: View {
    let viewModel: MessageRowViewModel
    var message: Message { viewModel.message }

    public var body: some View {
        ZStack {
            if let data = message.uploadFile?.uploadImageRequest?.dataToSend, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFill()
                    .frame(width: viewModel.sizes.imageWidth, height: viewModel.sizes.imageHeight)
                    .blur(radius: 16, opaque: false)
                    .clipped()
                    .zIndex(0)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
            }
            if let uploadViewModel = viewModel.uploadViewModel {
                OverladUploadImageButton(messageRowVM: viewModel)
                    .environmentObject(uploadViewModel)
            }
        }
        .task {
            viewModel.uploadViewModel?.startUploadImage()
        }
    }
}

struct OverladUploadImageButton: View {
    let messageRowVM: MessageRowViewModel
    @EnvironmentObject var viewModel: UploadFileViewModel
    var message: Message { messageRowVM.message }
    var percent: Int64 { viewModel.uploadPercent }
    var stateIcon: String {
        if viewModel.state == .uploading {
            return "xmark"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.up"
        }
    }

    var body: some View {
        if viewModel.state != .completed {
            Button {
                manageUpload()
            } label: {
                HStack {
                    ZStack {
                        iconView
                        progress
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.App.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius:(18)))
                    sizeView
                }
                .frame(height: 36)
                .frame(minWidth: 76)
                .padding(4)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
            .animation(.easeInOut, value: stateIcon)
            .animation(.easeInOut, value: percent)
            .buttonStyle(.borderless)
        }
    }

    private var iconView: some View {
        Image(systemName: stateIcon)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .font(.system(size: 8, design: .rounded).bold())
            .frame(width: 14, height: 14)
            .foregroundStyle(Color.App.textPrimary)
    }

    private var progress: some View {
        Circle()
            .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.App.white)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 34, height: 34)
            .rotateAnimtion(pause: viewModel.state == .paused)
    }

    @ViewBuilder private var sizeView: some View {
        let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
        let realServerFileSize = messageRowVM.calculatedMessage.fileMetaData?.file?.size
        if let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale) {
            Text(fileSize)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption2)
                .foregroundColor(Color.App.textPrimary)
        }
    }
    
    private func manageUpload() {
        if viewModel.state == .paused {
            viewModel.resumeUpload()
        } else if viewModel.state == .uploading {
            viewModel.cancelUpload()
        }
    }
}

struct MessageRowImageDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageView()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
