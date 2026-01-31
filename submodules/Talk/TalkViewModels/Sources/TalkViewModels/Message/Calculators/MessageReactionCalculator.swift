//
//  MessageReactionCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import ChatModels
import TalkModels
import UIKit

public final class MessageReactionCalculator {
    private let message: HistoryMessageType
    private let myId: Int
    
    public init(message: HistoryMessageType, myId: Int) {
        self.message = message
        self.myId = myId
    }
    
    public func updateReaction(_ calculated: ReactionRowsCalculated,
                                     _ index: Int,
                                     _ wasMySelf: Bool,
                                     _ isMyReaction: Bool,
                                     _ myReactionId: Int?,
                                     _ newValue: Int,
                                     _ emoji: String?) -> [ReactionRowsCalculated.Row] {
        var rows = calculated.rows
        rows[index].count = newValue
        rows[index].countText = reactionCountText(count: newValue)
        
        if wasMySelf {
            rows[index].isMyReaction = isMyReaction
            rows[index].myReactionId = isMyReaction ? myReactionId : nil
        }
        rows[index].selectedEmojiTabId = "\(emoji ?? "") \(newValue.localNumber(locale: Language.preferredLocale) ?? "")"
        return rows
    }
    
    public func reactionCountText(count: Int) -> String {
        if count > 99 {
            return "99+";
        } else {
            return count.localNumber(locale: Language.preferredLocale) ?? ""
        }
    }
    
    public func reactionReplaced(_ calculated: ReactionRowsCalculated, _ reaction: Reaction, oldSticker: Sticker) -> ReactionRowsCalculated {
        let wasMySelf = reaction.participant?.id == myId
        var newCalculated = calculated
        /// Reduce old reaction
        if let index = newCalculated.rows.firstIndex(where: {$0.sticker?.rawValue == oldSticker.rawValue}) {
            let newValue = newCalculated.rows[index].count - 1
            if newValue == 0 {
                newCalculated.rows.remove(at: index)
            } else {
                newCalculated.rows = updateReaction(newCalculated,
                                                    index,
                                                    wasMySelf,
                                                    false,
                                                    reaction.id,
                                                    newValue,
                                                    oldSticker.emoji)
            }
        }
        
        /// Increase new reaction
        if let index = newCalculated.rows.firstIndex(where: {$0.sticker?.rawValue == reaction.reaction?.rawValue}) {
            newCalculated.rows = updateReaction(newCalculated,
                                                index,
                                                wasMySelf,
                                                wasMySelf,
                                                reaction.id,
                                                newCalculated.rows[index].count + 1,
                                                reaction.reaction?.emoji ?? "")
        } else {
            newCalculated.rows.append(ReactionRowsCalculated.Row.firstReaction(reaction, myId, reaction.reaction?.emoji ?? ""))
        }
        newCalculated.sortReactions()
        return newCalculated
    }
    
    func calulateReactions(_ reactions: ReactionCountList) -> ReactionRowsCalculated {
        var rows: [ReactionRowsCalculated.Row] = []
        let summaries = reactions.reactionCounts?.sorted(by: {$0.count ?? 0 > $1.count ?? 0}) ?? []
        let myReaction = reactions.userReaction
        summaries.forEach { summary in
            var countText = reactionCountText(count: summary.count ?? 0)
            let emoji = summary.sticker?.emoji ?? ""
            let isMyReaction = myReaction?.reaction?.rawValue == summary.sticker?.rawValue
            let selectedEmojiTabId = "\(summary.sticker?.emoji ?? "all") \(countText)"
            let width = calculateReactionWidth(reactionText: selectedEmojiTabId)
            rows.append(.init(myReactionId: myReaction?.id,
                              edgeInset: .defaultReaction,
                              sticker: summary.sticker,
                              emoji: emoji,
                              countText: countText,
                              count: summary.count ?? 0,
                              isMyReaction: isMyReaction,
                              selectedEmojiTabId: selectedEmojiTabId,
                              width: width))
        }
        
        // Move my reaction to the first item without sorting reactions
        let myReactionRow = rows.first{$0.isMyReaction}
        if let myReactionRow = myReactionRow {
            rows.removeAll(where: {$0.isMyReaction})
            rows.insert(myReactionRow, at: 0)
        }
        let myReactionSticker = myReaction?.reaction
        return ReactionRowsCalculated(messageId: message.id ?? -1, rows: rows)
    }
    
    public func reactionDeleted(_ calculated: ReactionRowsCalculated, _ reaction: Reaction) -> ReactionRowsCalculated {
        var newCalculated = calculated
        let wasMySelf = reaction.participant?.id == myId
        if let index = newCalculated.rows.firstIndex(where: {$0.sticker?.rawValue == reaction.reaction?.rawValue}) {
            newCalculated.rows = updateReaction(calculated,
                                                index,
                                                wasMySelf,
                                                false,
                                                nil,
                                                newCalculated.rows[index].count - 1,
                                                reaction.reaction?.emoji ?? "")
            if newCalculated.rows[index].count == 0 {
                newCalculated.rows.remove(at: index)
            }
        }
        newCalculated.sortReactions()
        return newCalculated
    }
    
    public func reactionAdded(_ calculated: ReactionRowsCalculated, _ reaction: Reaction) -> ReactionRowsCalculated {
        var newCalculated = calculated
        let wasMySelf = reaction.participant?.id == myId
        if let index = calculated.rows.firstIndex(where: {$0.sticker?.rawValue == reaction.reaction?.rawValue}) {
            newCalculated.rows = updateReaction(calculated,
                                                index,
                                                wasMySelf,
                                                wasMySelf,
                                                reaction.id,
                                                calculated.rows[index].count + 1,
                                                reaction.reaction?.emoji ?? "")
        } else {
            newCalculated.rows.append(ReactionRowsCalculated.Row.firstReaction(reaction, myId, reaction.reaction?.emoji ?? ""))
        }
        newCalculated.sortReactions()
        return newCalculated
    }
    
    func calculateReactionWidth(reactionText: String) -> CGFloat {
        return reactionText.widthOfString(usingFont: UIFont.bold(.body)) + 16 + 4
    }
}
