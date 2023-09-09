//
//  ReactionCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import ChatAppExtensions
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ReactionCountView: View {
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    @State var reactionCountList: [ReactionCount] = []

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                Spacer()
                ForEach(reactionCountList) { reactionCount in
                    ReactionCountRow(messageId: messageId, reactionCount: reactionCount)
                }
                Spacer()
            }
        }
        .animation(.easeInOut, value: reactionCountList.count)
        .onReceive(NotificationCenter.default.publisher(for: .reactionMessageUpdated)) { newValue in
            if newValue.object as? Int == messageId {
                reactionCountList = ReactionViewModel.shared.reactionCountList.first(where: { $0.messageId == messageId })?.reactionCounts ?? []
            }
        }
        .onAppear {
            if let reactionCountList = ReactionViewModel.shared.reactionCountList.first(where: { $0.messageId == messageId })?.reactionCounts {
                self.reactionCountList = reactionCountList
            }
        }
    }
}

struct ReactionCountRow: View {
    let messageId: Int
    @State var count: Int = 0
    let reactionCount: ReactionCount

    var body: some View {
        HStack {
            if count > 0 {
                if let sticker = reactionCount.sticker, let sticker = Emoji(rawValue: sticker) {
                    Text(verbatim: sticker.emoji)
                        .frame(width: 20, height: 20)
                        .font(.system(size: 14))
                }
                Text("\(count)")
                    .font(.iransansBody)
            }
        }
        .animation(.easeInOut, value: count)
        .padding([.leading, .trailing], count > 0 ? 8 : 0)
        .padding([.top, .bottom], count > 0 ? 6 : 0)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .onReceive(NotificationCenter.default.publisher(for: .reactionMessageUpdated)) { newValue in
            onNewValue(newValue.object as? Int)
        }
        .onAppear {
            count = reactionCount.count ?? 0
        }
        .onTapGesture {
            print("tapped on \(Emoji(rawValue: reactionCount.sticker ?? 1)?.emoji ?? "") with messageId: \(messageId)")
        }
    }

    func onNewValue(_ messageId: Int?) {
        if messageId == self.messageId {
            count = ReactionViewModel.shared.reactionCountList
                .first(where: { $0.messageId == messageId })?
                .reactionCounts?.first(where: { $0.sticker == reactionCount.sticker })?.count ?? 0
        }
    }
}

struct ReactionCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionCountView(message: .init(id: 1),
                          reactionCountList: [
                              .init(sticker: 1, count: 10),
                              .init(sticker: 2, count: 40),
                              .init(sticker: 3, count: 2),
                              .init(sticker: 4, count: 5),
                          ])
    }
}
