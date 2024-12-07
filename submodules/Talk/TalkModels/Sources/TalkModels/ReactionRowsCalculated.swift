import Foundation
import SwiftUI
import Chat

public struct ReactionRowsCalculated: Sendable {
    public var rows: [Row]
    public let topPadding: CGFloat
    public let myReactionSticker: Sticker?

    public init(rows: [Row] = [], topPadding: CGFloat = 0, myReactionSticker: Sticker? = nil) {
        self.rows = rows
        self.topPadding = topPadding
        self.myReactionSticker = myReactionSticker
    }

    public struct Row: Identifiable, Sendable {
        public var id: String { "\(emoji) \(countText)" }
        public let reactionId: Int
        public let edgeInset: EdgeInsets
        public let sticker: Sticker?
        public let emoji: String
        public let countText: String
        public let isMyReaction: Bool
        public let hasReaction: Bool
        public let selectedEmojiTabId: String

        public init(reactionId: Int, edgeInset: EdgeInsets, sticker: Sticker?, emoji: String, countText: String, isMyReaction: Bool, hasReaction: Bool, selectedEmojiTabId: String) {
            self.reactionId = reactionId
            self.edgeInset = edgeInset
            self.sticker = sticker
            self.emoji = emoji
            self.countText = countText
            self.isMyReaction = isMyReaction
            self.hasReaction = hasReaction
            self.selectedEmojiTabId = selectedEmojiTabId
        }
    }
}
