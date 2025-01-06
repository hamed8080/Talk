import TalkExtensions
import SwiftUI
import Chat
import TalkViewModels
import TalkModels

extension Conversation {
    public typealias MessageIconStatus = (icon: UIImage, fgColor: Color)
    public func messageStatusIcon(currentUserId: Int?) -> MessageIconStatus? {
        if group == true || type == .selfThread { return nil }
        if !isLastMessageMine(currentUserId: currentUserId) { return nil }
        let lastID = lastMessageVO?.id ?? 0
        if let partnerLastSeenMessageId = partnerLastSeenMessageId, partnerLastSeenMessageId == lastID {
            return (MessageHistoryStatics.seenImage!, Color.App.accent)
        } else if let partnerLastDeliveredMessageId = partnerLastDeliveredMessageId, partnerLastDeliveredMessageId == lastID {
            return (MessageHistoryStatics.sentImage!, Color.App.textSecondary)
        } else if lastID > partnerLastSeenMessageId ?? 0 {
            return (MessageHistoryStatics.sentImage!, Color.App.textSecondary)
        } else { return nil }
    }
}
