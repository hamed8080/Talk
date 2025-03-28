import Foundation

public struct MessageViewRowType: Sendable {
    public var isFile: Bool = false
    public var isImage: Bool = false
    public var isForward: Bool = false
    public var isAudio: Bool = false
    public var isVideo: Bool = false
    public var isPublicLink: Bool = false
    public var isReply: Bool = false
    public var isMap: Bool = false
    public var isUnSent: Bool = false
    public var cellType: CellTypes = .unknown
    public var hasText: Bool = false
    public var isSingleEmoji = false
    public init() {}
}

public extension MessageViewRowType {
    var isBareSingleEmoji: Bool {
        if isFile || isImage || isAudio || isMap || isReply || isVideo || isForward { return false }
        return true
    }
}
