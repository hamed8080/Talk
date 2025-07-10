//
//  VoicesTabView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct VoicesTabView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        _viewModel =  StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "Voice"))
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
        ForEach(viewModel.messagesModels) { model in
            VoiceRowView(viewModel: detailViewModel)
                .environmentObject(model)
                .appyDetailViewContextMenu(VoiceRowView(viewModel: detailViewModel), model, detailViewModel)
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

struct VoiceRowView: View {
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
        .onTapGesture {
            rowModel.onTap(viewModel: viewModel)
        }
    }
}

#if DEBUG
struct VoiceView_Previews: PreviewProvider {
    static var previews: some View {
        VoicesTabView(conversation: MockData.thread, messageType: .podSpaceVoice)
    }
}
#endif
