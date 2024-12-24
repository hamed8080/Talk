//
//  VoiceView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import ActionableContextMenu

struct VoiceView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        _viewModel =  StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "Voice"))
    }

    var body: some View {
        LazyVStack {
            ThreadTabDetailStickyHeaderSection(header: "", height:  4)
                .onAppear {
                    if viewModel.messages.count == 0 {
                        viewModel.loadMore()
                    }
                }

            if viewModel.isLoading || viewModel.messages.count > 0 {
                MessageListVoiceView()
                    .padding(.top, 8)
                    .environmentObject(viewModel)
            } else {
                EmptyResultViewInTabs()
            }
        }
    }
}

struct MessageListVoiceView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: ThreadDetailViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            VoiceRowView(message: message)
                .environmentObject(viewModel.downloadVM(message: message))
                .overlay(alignment: .bottom) {
                    if message != viewModel.messages.last {
                        Rectangle()
                            .fill(Color.App.dividerPrimary)
                            .frame(height: 0.5)
                            .padding(.leading)
                    }
                }
                .onAppear {
                    if message == viewModel.messages.last {
                        viewModel.loadMore()
                    }
                }
        }
        DetailLoading()
    }
}

struct VoiceRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State var shareDownloadedFile = false
    @EnvironmentObject var downloadViewModel: DownloadFileViewModel
    @EnvironmentObject var audioVM: AVAudioPlayerViewModel

    var body: some View {
        HStack {
            if downloadViewModel.state == .completed, let fileURL = downloadViewModel.fileURL {
                DownloadedVoicePlayer(message: message, fileURL: fileURL)
            } else {
                DownloadVoiceButtonView()
                    .frame(width: 48, height: 48)
                    .padding(4)
            }
            VStack(alignment: .leading) {
                Text(message.fileMetaData?.file?.originalName ?? message.messageTitle)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack {
                    Text(message.time?.date.localFormattedTime ?? "" )
                        .foregroundColor(Color.App.textSecondary)
                        .font(.iransansCaption2)
                    Spacer()
                    Text(message.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) ?? "")
                        .foregroundColor(Color.App.textSecondary)
                        .font(.iransansCaption3)
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        .contentShape(Rectangle())
        .background(Color.App.bgPrimary)
        .onTapGesture {
            if downloadViewModel.state != .completed {
                downloadViewModel.startDownload()
            } else {
                AppState.shared.objectsContainer.audioPlayerVM.toggle()
            }
        }
        .onAppear {
            Task {
                await downloadVM.setup()
            }
        }
        .newCustomContextMenu {
            VoiceRowView(message: message)
                .disabled(true)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } menus: {
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
}

struct DownloadedVoicePlayer: View {
    let message: Message
    let fileURL: URL
    @EnvironmentObject var viewModel: AVAudioPlayerViewModel
    var isSameFile: Bool { 
        if isSameFileConverted { return true }
        return viewModel.fileURL?.absoluteString == fileURL.absoluteString
    }

    var isSameFileConverted: Bool {
        message.convertedFileURL != nil && viewModel.fileURL?.absoluteString == message.convertedFileURL?.absoluteString
    }

    @State var failed = false
    
    var icon: String {
        if failed {
            return "exclamationmark.circle.fill"
        } else {
            return viewModel.isPlaying && isSameFile ? "pause.fill" : "play.fill"
        }
    }

    var body: some View {
        Button {
            do {
                let convrtedURL = message.convertedFileURL
                let convertedExist = FileManager.default.fileExists(atPath: convrtedURL?.path() ?? "")
                try viewModel.setup(message: message,
                                    fileURL: (convertedExist ? convrtedURL : fileURL) ?? fileURL,
                                    ext: convertedExist ? "mp4" : message.fileMetaData?.file?.mimeType?.ext,
                                    title: message.fileMetaData?.name,
                                    subtitle: message.fileMetaData?.file?.originalName ?? "")
                viewModel.toggle()
            } catch {
                failed = true
            }
        } label: {
            ZStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.App.textPrimary)

                Circle()
                    .trim(from: 0.0, to: isSameFile ? min(viewModel.currentTime / viewModel.duration, 1.0) : 0)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.App.textPrimary)
                    .rotationEffect(Angle(degrees: 270))
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 36, height: 36)
            .background(failed ? Color.App.red : Color.App.accent)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .contentShape(Rectangle())
        }
        .frame(width: 48, height: 48)
        .padding(4)
    }
}

struct DownloadVoiceButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    var body: some View {
        DownloadFileView(viewModel: veiwModel)
            .frame(width: 48, height: 48)
            .padding(4)
    }
}

struct VoiceView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceView(conversation: MockData.thread, messageType: .podSpaceVoice)
    }
}
