//
//  MusicsTabView.swift
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

struct MusicsTabView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel
    
    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "Music"))
    }
    
    var body: some View {
        VStack {
            ThreadTabDetailStickyHeaderSection(header: "", height:  4)
                .onAppear {
                    if viewModel.messagesModels.count == 0 {
                        viewModel.loadMore()
                    }
                }
            if viewModel.isLoading || viewModel.messagesModels.count > 0 {
                MessageListMusicView()
                    .padding(.top, 8)
                    .environmentObject(viewModel)
            } else {
                EmptyResultViewInTabs()
            }
        }
    }
}

struct MessageListMusicView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
    
    var body: some View {
        ForEach(viewModel.messagesModels) { model in
            MusicRowView()
                .environmentObject(model)
                .appyDetailViewContextMenu(MusicRowView(), model, detailViewModel)
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

struct MusicRowView: View {
    @EnvironmentObject var rowModel: TabRowModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    
    var body: some View {
        HStack {
            TabDownloadProgressButton()
            
            VStack(alignment: .leading) {
                Text(rowModel.fileName)
                    .font(.fBody)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack {
                    Text(rowModel.time)
                        .foregroundColor(Color.App.textSecondary)
                        .font(.fCaption2)
                    Spacer()
                    Text(rowModel.fileSizeString)
                        .foregroundColor(Color.App.textSecondary)
                        .font(.fCaption3)
                }
            }
            Spacer()
        }
        .padding(.all)
        .contentShape(Rectangle())
        .background(Color.App.bgPrimary)
        .onTapGesture {
            rowModel.onTap(viewModel: viewModel)
        }
    }
}

#if DEBUG
struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        MusicsTabView(conversation: MockData.thread, messageType: .podSpaceSound)
    }
}
#endif
