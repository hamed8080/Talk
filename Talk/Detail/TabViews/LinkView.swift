//
//  LinkView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions

struct LinkView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "Link"))
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
                MessageListLinkView()
                    .padding(.top, 8)
                    .environmentObject(viewModel)
            } else {
                EmptyResultViewInTabs()
            }
        }
    }
}

struct MessageListLinkView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            LinkRowView(message: message)
                .overlay(alignment: .bottom) {
                    if message != viewModel.messages.last {
                        Rectangle()
                            .fill(Color.App.textSecondary.opacity(0.3))
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

struct LinkRowView: View {
    let message: Message
    @State var smallText: String? = nil
    @State var links: [String] = []
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.App.textSecondary)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius:(8)))
                .overlay(alignment: .center) {
                    Image(systemName: "link")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.App.textPrimary)
                }
            VStack(alignment: .leading, spacing: 2) {
                if let smallText = smallText {
                    Text(smallText)
                        .font(.fBody)
                        .foregroundStyle(Color.App.textPrimary)
                        .lineLimit(1)
                }
                ForEach(links, id: \.self) { link in
                    Text(verbatim: link)
                        .font(.fBody)
                        .foregroundStyle(Color.App.accent)
                }
            }
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }.task {
            await calculateText(message: message.message)
        }
    }

    private func onTap() {
        Task {
            await threadVM?.historyVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
        }
    }

    private nonisolated func calculateText(message: String?) async {
        let smallText = String(message?.replacingOccurrences(of: "\n", with: " ").prefix(500) ?? "")
        var links: [String] = []
        message?.links().forEach { link in
            links.append(link)
        }
        await MainActor.run { [links] in
            self.smallText = smallText
            self.links = links
        }
    }
}

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        LinkView(conversation: MockData.thread, messageType: .link)
    }
}
