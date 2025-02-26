import Foundation
import SwiftUI
import Chat

public struct ReactionRowsCalculated: Sendable {
    public var rows: [Row]

    public init(rows: [Row] = []) {
        self.rows = rows
    }

    public struct Row: Identifiable, Sendable {
        public var id: String { "\(emoji) \(countText)" }
        public var myReactionId: Int?
        public let edgeInset: EdgeInsets
        public let sticker: Sticker?
        public let emoji: String
        public var countText: String
        public var count: Int
        public var isMyReaction: Bool
        public var selectedEmojiTabId: String
        public let width: CGFloat

        public init(
            myReactionId: Int?,
            edgeInset: EdgeInsets,
            sticker: Sticker?,
            emoji: String,
            countText: String,
            count: Int,
            isMyReaction: Bool,
            selectedEmojiTabId: String,
            width: CGFloat
        ) {
            self.myReactionId = myReactionId
            self.edgeInset = edgeInset
            self.sticker = sticker
            self.emoji = emoji
            self.countText = countText
            self.count = count
            self.isMyReaction = isMyReaction
            self.selectedEmojiTabId = selectedEmojiTabId
            self.width = width
        }
    }
    
    public mutating func sortReactions() {
        let sorted = rows.sorted(by: { $0.count > $1.count }).sorted(by: { $0.isMyReaction && !$1.isMyReaction })
        self.rows = sorted
    }
}

public extension EdgeInsets {
    static let zeroReaction = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    static let defaultReaction = EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
}

public extension ReactionRowsCalculated.Row {
    
    static let moreReactionRow: ReactionRowsCalculated.Row = .init(
        myReactionId: nil,
        edgeInset: .zeroReaction,
        sticker: nil,
        emoji: "",
        countText: "",
        count: 0,
        isMyReaction: false,
        selectedEmojiTabId: "General.all",
        width: 0
    )
    
    static func firstReaction(_ reaction: Reaction, _ myId: Int, _ emoji: String) -> ReactionRowsCalculated.Row {
        let isMyReeaction = reaction.participant?.id == myId
        return ReactionRowsCalculated.Row(myReactionId: isMyReeaction ? reaction.id : nil,
                                          edgeInset: .defaultReaction,
                                          sticker: reaction.reaction,
                                          emoji: emoji,
                                          countText: 1.localNumber(locale: Language.preferredLocale) ?? "",
                                          count: 1,
                                          isMyReaction: isMyReeaction,
                                          selectedEmojiTabId: "\(emoji) \(1.localNumber(locale: Language.preferredLocale) ?? "")",
                                          width: 64)
    }
}
