//
//  MessagePaddingCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessagePaddingCalculator {
    private let message: HistoryMessageType
    private let calculatedMessage: MessageRowCalculatedData
    
    public init(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData) {
        self.message = message
        self.calculatedMessage = calculatedMessage
    }
    
    public func paddings() -> MessagePaddings {
        var paddings = MessagePaddings()
        paddings.textViewSpacingTop = (calculatedMessage.groupMessageParticipantName != nil || message.replyInfo != nil || message.forwardInfo != nil) ? 10 : 0
        paddings.replyViewSpacingTop = calculatedMessage.groupMessageParticipantName != nil ? 10 : 0
        paddings.forwardViewSpacingTop = calculatedMessage.groupMessageParticipantName != nil ? 10 : 0
        paddings.fileViewSpacingTop = (calculatedMessage.groupMessageParticipantName != nil || message.replyInfo != nil || message.forwardInfo != nil) ? 10 : 0
        paddings.radioPadding = UIEdgeInsets(top: 0, left: calculatedMessage.isMe ? 8 : 0, bottom: 8, right: calculatedMessage.isMe ? 8 : 0)
        paddings.mapViewSapcingTop =  (calculatedMessage.groupMessageParticipantName != nil || message.replyInfo != nil || message.forwardInfo != nil) ? 10 : 0
        let hasAlreadyPadding = message.replyInfo != nil || message.forwardInfo != nil
        let padding: CGFloat = hasAlreadyPadding ? 0 : 4
        paddings.groupParticipantNamePadding = .init(top: padding, left: padding, bottom: 0, right: padding)
        return paddings
    }
    
    public func textViewEdgeInset() -> UIEdgeInsets {
        return UIEdgeInsets(top: !message.isImage && message.replyInfo == nil && message.forwardInfo == nil ? 6 : 0,
                            left: 6,
                            bottom: 0,
                            right: 6)
    }
}
