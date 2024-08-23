//
//  UnreadMessage.swift
//  TalkModels
//
//  Created by hamed on 3/9/23.
//

import Foundation
import Chat

public protocol UnreadMessageProtocol {}

public class UnreadMessage: HistoryMessageBaseCalss, UnreadMessageProtocol {

    public init(id: Int, time: UInt, uniqueId: String) {
        let message = Message(id: id, time: time, uniqueId: uniqueId)
        super.init(message: message)
    }
}
