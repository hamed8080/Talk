//
//  FilesTabView.swift
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

struct FilesTabView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "File"))
    }

    var body: some View {
        LazyVStack {
            ThreadTabDetailStickyHeaderSection(header: "", height:  4)
                .onAppear {
                    if viewModel.messagesModels.count == 0 {
                        viewModel.loadMore()
                    }
                }
            if viewModel.isLoading || viewModel.messagesModels.count > 0 {
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
        ForEach(viewModel.messagesModels) { model in
            FileRowView(viewModel: detailViewModel)
                .environmentObject(model)
                .appyDetailViewContextMenu(FileRowView(viewModel: detailViewModel), model, detailViewModel)
                .overlay(alignment: .bottom) {
                    if model.message != viewModel.messagesModels.last?.message {
                        Rectangle()
                            .fill(Color.App.dividerPrimary)
                            .frame(height: 0.5)
                            .padding(.leading)
                    }
                }
                .onAppear {
                    if model.message == viewModel.messagesModels.last?.message {
                        viewModel.loadMore()
                    }
                }
        }
        DetailLoading()
    }
}

struct FileRowView: View {
    @EnvironmentObject var rowModel: TabRowModel
    let viewModel: ThreadDetailViewModel

    var body: some View {
        HStack {
            TabDownloadProgressButton()
            TabDetailsText(rowModel: rowModel)
            Spacer()
        }
        .padding(.all)
        .background(Color.App.bgPrimary)
        .contentShape(Rectangle())
        .sheet(isPresented: $rowModel.shareDownloadedFile) {
            if let tempURL = rowModel.tempShareURL {
                ActivityViewControllerWrapper(activityItems: [tempURL], title: rowModel.metadata?.file?.originalName)
            }
        }
        .onTapGesture {
            rowModel.onTap(viewModel: viewModel)
        }
    }
}

#if DEBUG
struct FileView_Previews: PreviewProvider {
    static let thread = MockData.thread

    static var previews: some View {
        FilesTabView(conversation: thread, messageType: .file)
    }
}
#endif
