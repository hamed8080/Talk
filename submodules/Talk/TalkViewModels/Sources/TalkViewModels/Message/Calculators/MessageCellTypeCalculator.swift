//
//  MessageCellTypeCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels

public final class MessageCellTypeCalculator {
    private let message: HistoryMessageType
    private let isMe: Bool
    
    public init(message: HistoryMessageType, isMe: Bool) {
        self.isMe = isMe
        self.message = message
    }
    
    public func getType() -> CellTypes {
        let type = message.type
        let isUploading = message is UploadProtocol
        let isBareMessage = message.isTextMessageType || message.isUnsentMessage || isUploading
        switch type {
        case .endCall, .startCall:
            return .call
        case .participantJoin, .participantLeft:
            return .participants
        default:
            if message is UnreadMessageProtocol {
                return .unreadBanner
            } else if isMe, isBareMessage {
                return .meMessage
            } else if !isMe, isBareMessage {
                return .partnerMessage
            }
        }
        return .unknown
    }
}

