//
//  MessageReactionDetailView.swift
//  Talk
//
//  Created by hamed on 8/13/23.
//

import Chat
import TalkUI
import TalkViewModels
import SwiftUI
import TalkExtensions
import TalkModels

struct MessageReactionDetailView: View {
    let message: any HistoryMessageProtocol 
    private let row: ReactionRowsCalculated.Row
    private var messageId: Int { message.id ?? -1 }
    @EnvironmentObject var tabVM: ReactionTabParticipantsViewModel

    init(message: any HistoryMessageProtocol, row: ReactionRowsCalculated.Row) {
        self.message = message
        self.row = row
    }

    var body: some View {
        TabContainerView(
            selectedId: row.selectedEmojiTabId,
            tabs: tabs,
            config: .init(alignment: .top, scrollable: true)
        ) { selectedTab in
            tabVM.setActiveTab(tabId: selectedTab)
        }
        .background(Color.App.bgPrimary)
        .navigationTitle("Reactions to: \(message.messageTitle.trimmingCharacters(in: .whitespacesAndNewlines))")
        .onAppear {
            tabVM.setActiveTab(tabId: row.selectedEmojiTabId)
        }
    }

    var tabs: [TabItem] {
        if summaryTabs.count > 0 {
            var tabs = summaryTabs
            tabs.insert(allTab, at: 0)
            return tabs
        } else {
            return []
        }
    }

    var allTab: TabItem {
        return TabItem(
            tabContent: ParticiapntsPageSticker(tabId: "General.all").environmentObject(tabVM),
            title: "General.all",
            showSelectedDivider: true
        )
    }

    var summaryTabs: [TabItem] {
        ChatManager.activeInstance?.reaction.inMemoryReaction.summary(for: messageId)
            .compactMap { reaction in
                let countText = reaction.count?.localNumber(locale: Language.preferredLocale) ?? ""
                let title = "\(reaction.sticker?.emoji ?? "all") \(countText)"
                return TabItem(
                    tabContent: ParticiapntsPageSticker(tabId: title).environmentObject(tabVM),
                    title: title,
                    showSelectedDivider: true
                )
            } ?? []
    }
}

struct ParticiapntsPageSticker: View {
    let tabId: ReactionTabId
    @EnvironmentObject var viewModel: ReactionTabParticipantsViewModel

    var body: some View {
        List {
            let reactions = viewModel.participants(for: tabId)
            ForEach(reactions) { reaction in
                ReactionParticipantRow(reaction: reaction)
                    .listRowBackground(Color.App.bgPrimary)
                    .onAppear {
                        if reactions.last == reaction {
                             viewModel.loadMoreParticipants()
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

struct ReactionParticipantRow: View {
    let reaction: Reaction

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                ImageLoaderView(participant: reaction.participant)
                    .scaledToFit()
                    .id(reaction.participant?.id)
                    .font(.iransansBoldCaption2)
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color(uiColor: String.getMaterialColorByCharCode(str: reaction.participant?.name ?? "")))
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
                Circle()
                    .fill(.red)
                    .frame(width: 28, height: 28)
                    .offset(x: 0, y: 26)
                    .blendMode(.destinationOut)
                    .overlay {
                        Text(verbatim: reaction.reaction?.emoji ?? "")
                            .font(.system(size: 13))
                            .frame(width: 22, height: 22)
                            .background(Color.App.accent.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius:(18)))
                            .offset(x: 0, y: 26)

                    }
            }
            .compositingGroup()
            .opacity(0.9)

            VStack(alignment: .leading, spacing: 4) {
                Text(reaction.participant?.name ?? "")
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .font(.iransansBody)
                if let time = reaction.time {
                    Text(time.date.localFormattedTime ?? "")
                        .padding(.leading, 4)
                        .font(.iransansCaption3)
                        .foregroundColor(Color.App.textSecondary)
                }
            }
        }
    }
}

struct MessageReactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let row = ReactionRowsCalculated.Row(reactionId: 0,
                                             edgeInset: .zero,
                                             sticker: .happy,
                                             emoji: "😂",
                                             countText: "1",
                                             isMyReaction: true,
                                             hasReaction: true,
                                             selectedEmojiTabId: "")
        MessageReactionDetailView(message: Message(id: 1, message: "TEST", conversation: Conversation(id: 1)), row: row)

        ReactionParticipantRow(reaction: .init(id: 1, reaction: .like, participant: .init(image: "https://imgv3.fotor.com/images/cover-photo-image/a-beautiful-girl-with-gray-hair-and-lucxy-neckless-generated-by-Fotor-AI.jpg"), time: nil))
            .frame(width: 300, height: 300)
    }
}
