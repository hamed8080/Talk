//
//  ReplyMessageRequest+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension ReplyMessageRequest {

    init(model: SendMessageModel) {
        self = ReplyMessageRequest(threadId: model.threadId,
                                   repliedTo: model.replyMessage?.id ?? -1,
                                   textMessage: model.textMessage,
                                   messageType: .text)
    }
}
