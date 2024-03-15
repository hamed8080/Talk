//
//  LinkView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions

struct LinkView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
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
            MessageListLinkView()
                .padding(.top, 8)
                .environmentObject(viewModel)
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
                        .font(.iransansBody)
                        .foregroundStyle(Color.App.textPrimary)
                        .lineLimit(1)
                }
                ForEach(links, id: \.self) { link in
                    Text(verbatim: link)
                        .font(.iransansBody)
                        .foregroundStyle(Color.App.accent)
                }
            }
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            threadVM?.historyVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
        }.task {
            smallText = String(message.message?.replacingOccurrences(of: "\n", with: " ").prefix(500) ?? "")
            let string = message.message ?? ""
            if let linkRegex = NSRegularExpression.urlRegEx {
                let allRange = NSRange(string.startIndex..., in: string)
                linkRegex.enumerateMatches(in: string, range: allRange) { (result, flag, _) in
                    if let range = result?.range, let linkRange = Range(range, in: string) {
                        let link = string[linkRange]
                        if link == message.message ?? "" {
                            smallText = nil
                        }
                        links.append(String(link))
                    }
                }
            }
        }
    }
}

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        LinkView(conversation: MockData.thread, messageType: .link)
    }
}
