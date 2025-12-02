//
//  VideosTabView.swift
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

struct VideosTabView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel
    
    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        let vm = DetailTabDownloaderViewModel(conversation: conversation, messageType: messageType, tabName: "Video")
        _viewModel = StateObject(wrappedValue: vm)
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
                MessageListVideoView()
                    .padding(.top, 8)
                    .environmentObject(viewModel)
            } else {
                EmptyResultViewInTabs()
            }
        }
    }
}

struct MessageListVideoView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: ThreadDetailViewModel

    var body: some View {
        ForEach(viewModel.messagesModels) { model in
            VideoRowView(viewModel: detailViewModel, isContextMenu: false)
                .environmentObject(model)
                .appyDetailViewContextMenu(contextMenuView, model, detailViewModel)
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
    
    private var contextMenuView: some View {
        VideoRowView(viewModel: detailViewModel, isContextMenu: true)
    }
}

struct VideoRowView: View {
    @EnvironmentObject var rowModel: TabRowModel
    let viewModel: ThreadDetailViewModel
    let isContextMenu: Bool
   
    var body: some View {
        if isContextMenu {
            bodyContainer
        } else {
            bodyContainerWithFullScreenCoverView
        }
    }
    
    private var bodyContainer: some View {
        HStack {
            TabDownloadProgressButton()
            TabDetailsText(rowModel: rowModel)
            Spacer()
        }
        .padding(.all)
        .contentShape(Rectangle())
        .background(Color.App.bgPrimary)
        .onTapGesture {
            rowModel.onTap(viewModel: viewModel)
        }
    }
    
    private var bodyContainerWithFullScreenCoverView: some View {
        bodyContainer
            .fullScreenCover(isPresented: $rowModel.showFullScreen) {
                /// On dismiss
                rowModel.playerVM?.player?.pause()
            } content: {
                if let player = rowModel.playerVM?.player {
                    PlayerViewRepresentable(player: player, showFullScreen: $rowModel.showFullScreen)
                }
            }
    }
}

#if DEBUG
struct VideoView_Previews: PreviewProvider {
    static let thread = MockData.thread

    static var previews: some View {
        VideosTabView(conversation: thread, messageType: .file)
    }
}
#endif
