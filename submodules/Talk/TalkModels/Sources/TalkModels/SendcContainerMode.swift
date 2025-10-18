import Foundation
import Chat

public struct SendcContainerMode {
    public let type: ModeType
    public var editMessage: Message?
    public var replyMessage: Message?

    public enum ModeType {
        case voice
        case video
        case showButtonsPicker
        case edit
    }
    
    public init(type: ModeType, editMessage: Message? = nil, replyMessage: Message? = nil) {
        self.type = type
        self.editMessage = editMessage
        self.replyMessage = replyMessage
    }
}
