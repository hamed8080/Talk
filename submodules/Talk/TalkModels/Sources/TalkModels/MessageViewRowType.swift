import Foundation

public struct MessageViewRowType {
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
