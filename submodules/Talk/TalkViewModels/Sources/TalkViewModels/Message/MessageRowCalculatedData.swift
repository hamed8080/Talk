//
//  MessageRowCalculatedData.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import SwiftUI
import TalkModels
import Chat

public struct MessageRowCalculatedData: @unchecked Sendable {
    nonisolated(unsafe) public static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Language.preferredLocale
        return formatter
    }()

    public var isCalculated = false
    public var timeString: String = ""
    public var isMe: Bool = false
    public var fileMetaData: FileMetaData?
    public var isEnglish = true
    public var isReplyImage: Bool = false
    public var callAttributedString: NSAttributedString?
    public var replyLink: String?
    public var participantColor: UIColor? = nil
    public var computedFileSize: String? = nil
    public var extName: String? = nil
    public var fileName: String? = nil
    public var addOrRemoveParticipantsAttr: NSAttributedString? = nil
    public var avatarColor: UIColor = .blue
    public var avatarSplitedCharaters = ""
    public var isInTwoWeekPeriod: Bool = false
    public var replyFileName: String? = nil
    public var attributedString: NSAttributedString?
    public var rangeCodebackground: [Range<String.Index>]?
    public var isFirstMessageOfTheUser: Bool = false
    public var isLastMessageOfTheUser: Bool = false
    public var canShowIconFile: Bool = false
    public var groupMessageParticipantName: String?
    public var avPlayerItem: AVAudioPlayerItem?
    public var canEdit: Bool = false
    public var scrollViewReactionWidth: CGFloat? = nil
    // Disk file path
    public var fileURL: URL?
//    public var textLayer: CATextLayer?
    public var textRect: CGRect?

    public var sizes = ConstantSizes()
    public var state = MessageRowState()
    public var rowType = MessageViewRowType()
    
    public init() {}
}
