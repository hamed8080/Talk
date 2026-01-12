//
//  SingleEmojiCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels

public final class MessageSingleEmojiCalculator {
    private let message: HistoryMessageType
    
    public init(message: HistoryMessageType) {
        self.message = message
    }
    
    func isSingleEmoji() -> Bool {
        message.message?.isEmoji == true &&
        message.message?.isEmpty == false &&
        message.replyInfo == nil &&
        message.message?.count ?? 0 == 1
    }
}
