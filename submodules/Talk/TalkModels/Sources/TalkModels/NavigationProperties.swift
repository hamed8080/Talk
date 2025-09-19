//
//  NavigationProperties.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat

/// Properties that can transfer between each navigation page and stay alive unless manually destroyed.
public struct NavigationProperties: Sendable {
    public var userToCreateThread: Participant?
    public var replyPrivately: Message?
    public var forwardMessages: [Message]?
    public var forwardMessageRequest: ForwardMessageRequest?
    public var moveToMessageId: Int?
    public var moveToMessageTime: UInt?
    public var openURL: URL?
    public init() {}
}
