//
//  FileView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import Combine
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import ActionableContextMenu

struct FileView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "File"))
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
                MessageListFileView()
                    .padding(.top, 8)
                    .environmentObject(viewModel)
            } else {
                EmptyResultViewInTabs()
            }
        }
    }
}

struct MessageListFileView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: ThreadDetailViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            FileRowView(message: message)
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

struct FileRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State var shareDownloadedFile = false
    @EnvironmentObject var downloadViewModel: DownloadFileViewModel
    @State private var tempURL: URL?
    @State private var fileMetaData: FileMetaData?

    var body: some View {
        HStack {
            DownloadFileButtonView()
            VStack(alignment: .leading) {
                Text(message.fileMetaData?.name ?? message.messageTitle)
                    .font(.fBody)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack {
                    Text(message.time?.date.localFormattedTime ?? "" )
                        .foregroundColor(Color.App.textSecondary)
                        .font(.fCaption2)
                    Spacer()
                    Text(message.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) ?? "")
                        .foregroundColor(Color.App.textSecondary)
                        .font(.fCaption3)
                }
            }
            Spacer()
        }
        .padding(.all)
        .background(Color.App.bgPrimary)
        .contentShape(Rectangle())
        .sheet(isPresented: $shareDownloadedFile) {
            if let tempURL = tempURL {
                ActivityViewControllerWrapper(activityItems: [tempURL], title: fileMetaData?.file?.originalName)
            }
        }
        .task {
            let metaData = await getFileMetaData(message: message)
            self.fileMetaData = metaData
        }
        .onAppear {
            Task {
                await downloadVM.setup()
            }
        }
        .onTapGesture {
            if downloadViewModel.state == .completed {
                Task { @AppBackgroundActor in
                    _ = await message.makeTempURL()
                    let tempURL = message.tempURL
                    await MainActor.run {
                        self.tempURL = tempURL
                        shareDownloadedFile.toggle()
                    }
                }
            } else {
                downloadViewModel.startDownload()
            }
        }
        .newCustomContextMenu {
            FileRowView(message: message)
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
    
    @AppBackgroundActor
    private func getFileMetaData(message: Message?) -> FileMetaData? {
        message?.fileMetaData
    }
}

struct DownloadFileButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    var body: some View {
        DownloadFileView(viewModel: veiwModel)
            .frame(width: 42, height: 42)
            .padding(4)
            .clipped()
            .cornerRadius(4) /// We round the corner of the file is an image we show a thumbnail of the file not the icon.
    }
}

#if DEBUG
struct FileView_Previews: PreviewProvider {
    static let thread = MockData.thread

    static var previews: some View {
        FileView(conversation: thread, messageType: .file)
    }
}
#endif
