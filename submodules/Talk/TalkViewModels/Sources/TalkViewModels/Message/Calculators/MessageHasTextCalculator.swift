//
//  MessageHasTextCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageHasTextCalculator {
    private let message: HistoryMessageType
    private let isSingleEmoji: Bool
    
    public init(message: HistoryMessageType, isSingleEmoji: Bool) {
        self.message = message
        self.isSingleEmoji = isSingleEmoji
    }

    public func hasText() -> Bool {
        if isSingleEmoji { return false }
        if (message as? UploadFileMessage)?.locationRequest?.textMessage != nil { return true }
        
        if let text = message.message, !text.isEmpty {
            return true
        } else if let text = (message as? UploadFileMessage)?.replyRequest?.textMessage, !text.isEmpty {
            return true
        } else {
            return false
        }
    }
}
