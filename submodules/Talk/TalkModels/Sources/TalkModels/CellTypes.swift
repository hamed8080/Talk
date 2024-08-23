import Foundation

public enum CellTypes: String {
    case call = "CallEventUITableViewCell"
    case partnerMessage = "TextMessagePartnerCellType"
    case meMessage = "TextMessageMeCellType"
    case participants = "ParticipantsEventUITableViewCell"
    case unreadBanner = "UnreadMessageBubbleUITableViewCell"
    case unknown
}
