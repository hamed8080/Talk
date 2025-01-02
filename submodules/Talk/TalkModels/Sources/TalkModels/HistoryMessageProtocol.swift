import Foundation
import ChatModels

public protocol HistoryMessageProtocol: Hashable, Sendable {
    var deletable: Bool? { get set }
    var delivered: Bool? { get set }
    var editable: Bool? { get set }
    var edited: Bool? { get set }
    var id: Int? { get set }
    var mentioned: Bool? { get set }
    var message: String? { get set }
    var messageType: MessageType? { get set }
    var metadata: String? { get set }
    var ownerId: Int? { get set }
    var pinned: Bool? { get set }
    var previousId: Int? { get set }
    var seen: Bool? { get set }
    var systemMetadata: String? { get set }
    var threadId: Int? { get set }
    var time: UInt? { get set }
    var timeNanos: UInt? { get set }
    var uniqueId: String? { get set }
    var conversation: Conversation? { get set }
    var forwardInfo: ForwardInfo? { get set }
    var participant: Participant? { get set }
    var replyInfo: ReplyInfo? { get set }
    var pinTime: UInt? { get set }
    var pinNotifyAll: Bool? { get set }
    var callHistory: CallHistory? { get set }
}

public typealias HistoryMessageType = any HistoryMessageProtocol

public class HistoryMessageBaseCalss: HistoryMessageProtocol, @unchecked Sendable {
    public static func == (lhs: HistoryMessageBaseCalss, rhs: HistoryMessageBaseCalss) -> Bool {
        lhs.uniqueId == rhs.uniqueId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueId)
    }

    public var deletable: Bool?
    public var delivered: Bool?
    public var editable: Bool?
    public var edited: Bool?
    public var id: Int?
    public var mentioned: Bool?
    public var message: String?
    public var messageType: MessageType?
    public var metadata: String?
    public var ownerId: Int?
    public var pinned: Bool?
    public var previousId: Int?
    public var seen: Bool?
    public var systemMetadata: String?
    public var threadId: Int?
    public var time: UInt?
    public var timeNanos: UInt?
    public var uniqueId: String?
    public var conversation: Conversation?
    public var forwardInfo: ForwardInfo?
    public var participant: Participant?
    public var replyInfo: ReplyInfo?
    public var pinTime: UInt?
    public var pinNotifyAll: Bool?
    public var callHistory: CallHistory?

    public init(message: Message) {
        deletable = message.deletable
        delivered = message.delivered
        editable = message.editable
        edited = message.edited
        id = message.id
        mentioned = message.mentioned
        self.message = message.message
        messageType = message.messageType
        metadata = message.metadata
        ownerId = message.ownerId
        pinned = message.pinned
        previousId = message.previousId
        seen = message.seen
        systemMetadata = message.systemMetadata
        threadId = message.threadId
        time = message.time
        timeNanos = message.timeNanos
        uniqueId = message.uniqueId
        conversation = message.conversation
        forwardInfo = message.forwardInfo
        participant = message.participant
        replyInfo = message.replyInfo
        pinTime = message.pinTime
        pinNotifyAll = message.pinNotifyAll
        callHistory = message.callHistory
    }
}
