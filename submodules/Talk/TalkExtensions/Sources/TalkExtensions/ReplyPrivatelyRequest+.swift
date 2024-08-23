//
//  ReplyPrivatelyRequest+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension ReplyPrivatelyRequest {

    init?(model: SendMessageModel) {
        guard let replyMessage = model.replyPrivatelyMessage, let replyMessageId = replyMessage.id, let fromConversationId = replyMessage.conversation?.id else { return nil }
        self.init(
            repliedTo: replyMessageId,
            messageType: .text,
            content: .init(text: model.textMessage,
                           targetConversationId: model.threadId,
                           fromConversationId: fromConversationId)
        )
    }
}
