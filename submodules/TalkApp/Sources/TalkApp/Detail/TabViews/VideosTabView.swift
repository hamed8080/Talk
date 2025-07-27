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
            VideoRowView(viewModel: detailViewModel)
                .environmentObject(model)
                .appyDetailViewContextMenu(VideoRowView(viewModel: detailViewModel), model, detailViewModel)
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

struct VideoRowView: View {
    @EnvironmentObject var rowModel: TabRowModel
    let viewModel: ThreadDetailViewModel
   
    var body: some View {
        HStack {
            TabDownloadProgressButton()
            TabDetailsText(rowModel: rowModel)
            Spacer()
        }
        .padding(.all)
        .contentShape(Rectangle())
        .background(Color.App.bgPrimary)
        .fullScreenCover(isPresented: $rowModel.showFullScreen) {
            /// On dismiss
            rowModel.playerVM?.player?.pause()
        } content: {
            if let player = rowModel.playerVM?.player {
                PlayerViewRepresentable(player: player, showFullScreen: $rowModel.showFullScreen)
            }
        }
        .onTapGesture {
            rowModel.onTap(viewModel: viewModel)
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
