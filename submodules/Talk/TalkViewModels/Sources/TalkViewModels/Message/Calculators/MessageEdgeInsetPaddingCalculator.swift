//
//  MessageEdgeInsetPaddingCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageEdgeInsetPaddingCalculator {
    private let message: HistoryMessageType
    private let calculatedMessage: MessageRowCalculatedData
    private let isImage: Bool
    
    public init(message: HistoryMessageType, calculatedMessage: MessageRowCalculatedData, isImage: Bool) {
        self.message = message
        self.calculatedMessage = calculatedMessage
        self.isImage = isImage
    }
    
    public func edgeInset() -> UIEdgeInsets {
        let isReplyOrForward = (message.forwardInfo != nil || message.replyInfo != nil) && !isImage
        let tailWidth: CGFloat = 6
        let paddingLeading = isReplyOrForward ? (calculatedMessage.isMe ? 10 : 16) : (calculatedMessage.isMe ? 4 : 4 + tailWidth)
        let paddingTrailing: CGFloat = isReplyOrForward ? (calculatedMessage.isMe ? 16 : 10) : (calculatedMessage.isMe ? 4 + tailWidth : 4)
        let paddingTop: CGFloat = isReplyOrForward ? 10 : 4
        let paddingBottom: CGFloat = 4
        return UIEdgeInsets(top: paddingTop, left: paddingLeading, bottom: paddingBottom, right: paddingTrailing)
    }
}
