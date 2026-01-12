//
//  MessageRowTypeCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/12/26.
//

import Foundation
import Chat
import TalkModels

public class MessageRowTypeCalculator {
    private let message: HistoryMessageType
    private let isMine: Bool
    private let fileMetaData: FileMetaData?
    private let joinLink: String
    private let isImage: Bool
    private let isAudio: Bool
    private let isVideo: Bool

    public init(message: HistoryMessageType, isMine: Bool, fileMetaData: FileMetaData?, joinLink: String) {
        self.message = message
        self.isMine = isMine
        self.fileMetaData = fileMetaData
        self.joinLink = joinLink
        self.isImage = message.isImage
        self.isAudio = message.isAudio
        self.isVideo = message.isVideo
    }
   
    public func rowType() -> MessageViewRowType {
        var rowType = MessageViewRowType()
        let isMap = fileMetaData?.mapLink != nil || fileMetaData?.latitude != nil || (message as? UploadFileMessage)?.locationRequest != nil
        let isSingleEmoji = MessageSingleEmojiCalculator(message: message).isSingleEmoji()
        rowType.isSingleEmoji = isSingleEmoji
        rowType.isImage = !isMap && isImage
        rowType.isVideo = isVideo
        rowType.isAudio = isAudio
        rowType.isForward = message.forwardInfo != nil
        rowType.isUnSent = message.isUnsentMessage
        rowType.hasText = MessageHasTextCalculator(message: message, isSingleEmoji: isSingleEmoji).hasText()
        rowType.cellType = MessageCellTypeCalculator(message: message, isMe: isMine).getType()
        rowType.isMap = isMap
        rowType.isPublicLink = message.isPublicLink(joinLink: joinLink)
        rowType.isFile = message.isFileType && !isMap && !isImage && !isAudio && !isVideo
        rowType.isReply = message.replyInfo != nil
        
        return rowType
    }
}
