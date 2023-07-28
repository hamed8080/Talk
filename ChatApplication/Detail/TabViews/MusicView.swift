//
//  MusicView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MusicView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        MessageListMusicView()
            .environmentObject(viewModel)
    }
}

struct MessageListMusicView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            MusicRowView(message: message)
                .onAppear {
                    if message == viewModel.messages.last {
                        viewModel.loadMore()
                    }
                }
        }
        if viewModel.isLoading {
            LoadingView()
        }
    }
}

struct MusicRowView: View {
    let message: Message
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(message.fileMetaData?.name ?? message.messageTitle)
                        .font(.iransansTitle)
                    Text(message.fileMetaData?.file?.size?.toSizeString ?? "")
                        .foregroundColor(.secondaryLabel)
                        .font(.iransansSubtitle)
                }
                Spacer()
                DownloadMusicButtonView()
                    .environmentObject(DownloadFileViewModel(message: message))
            }
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding([.leading, .trailing])
        .onTapGesture {
            threadVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
        }
    }
}

struct DownloadMusicButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    static var config: DownloadFileViewConfig = {
        var config: DownloadFileViewConfig = .small
        config.circleConfig.forgroundColor = .green
        config.iconColor = .orange
        return config
    }()

    var body: some View {
        DownloadFileView(viewModel: veiwModel, config: DownloadFileButtonView.config)
            .frame(width: 72, height: 72)
    }
}

struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        MusicView(conversation: MockData.thread, messageType: .podSpaceSound)
    }
}
