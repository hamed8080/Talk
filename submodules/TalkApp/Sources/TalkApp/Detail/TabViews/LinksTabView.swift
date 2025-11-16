//
//  LinksTabView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions

struct LinksTabView: View {
    @StateObject var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: ChatModels.MessageType) {
        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, messageType: messageType, tabName: "Link"))
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
    @EnvironmentObject var threadDetailVM: ThreadDetailViewModel
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @State var viewWidth: CGFloat = 0

    var body: some View {
        ForEach(viewModel.messagesModels) { model in
            LinkRowView()
                .environmentObject(model)
                .overlay(alignment: .bottom) {
                    if model.id != viewModel.messagesModels.last?.id {
                        Rectangle()
                            .fill(Color.App.textSecondary.opacity(0.3))
                            .frame(height: 0.5)
                            .padding(.leading)
                    }
                }
                .background(frameReader)
                .appyDetailViewContextMenu(LinkRowView().background(MixMaterialBackground()), model, threadDetailVM)
                .onAppear {
                    if model.id == viewModel.messagesModels.last?.id {
                        viewModel.loadMore()
                    }
                }                
        }
        DetailLoading()
    }

    private var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                self.viewWidth = reader.size.width
            }
        }
    }
}

struct LinkRowView: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @EnvironmentObject var rowModel: TabRowModel

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
                if let smallText = rowModel.smallText {
                    Text(smallText)
                        .font(Font.normal(.body))
                        .foregroundStyle(Color.App.textPrimary)
                        .lineLimit(1)
                }
                ForEach(rowModel.links, id: \.self) { link in
                    Text(verbatim: link)
                        .font(Font.normal(.body))
                        .foregroundStyle(Color.App.accent)
                }
            }
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            rowModel.moveToMessage(viewModel)
        }
    }
}

#if DEBUG
struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        LinksTabView(conversation: MockData.thread, messageType: .link)
    }
}
#endif
