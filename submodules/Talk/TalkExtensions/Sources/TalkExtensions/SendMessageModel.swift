//
//  SendMessageModel.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import Chat

public struct SendMessageModel {
    public var textMessage: String
    public var replyMessage: Message?
    public var threadId: Int
    public var userGroupHash: String?
    public var uploadFileIndex: Int?
    public var conversation: Conversation?
    public var meId: Int?
    public var replyPrivatelyMessage: Message?

    public init(textMessage: String = "", replyMessage: Message? = nil, meId: Int? = nil, conversation: Conversation? = nil, threadId: Int, userGroupHash: String? = nil, uploadFileIndex: Int? = nil, replyPrivatelyMessage: Message? = nil) {
        self.textMessage = textMessage
        self.replyMessage = replyMessage
        self.threadId = threadId
        self.userGroupHash = userGroupHash
        self.uploadFileIndex = uploadFileIndex
        self.conversation = conversation
        self.meId = meId
        self.replyPrivatelyMessage = replyPrivatelyMessage
    }
}
