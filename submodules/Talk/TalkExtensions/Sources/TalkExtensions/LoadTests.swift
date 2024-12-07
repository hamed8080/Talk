//
//  LoadTests.swift
//  TalkExtensions
//
//  Created by hamed on 3/29/23.
//

import Foundation
import Chat

public class LoadTests {
    nonisolated(unsafe) static var start = 0
    public class func rapidSend(threadId: Int,
                                messageTempelate: String,
                                start: Int,
                                end: Int,
                                duration: TimeInterval = 3) {
#if DEBUG
        self.start = start
        Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { timer in
            if start < end {
                let req = SendTextMessageRequest(threadId: threadId,
                                                 textMessage: String(format: messageTempelate, start) ,
                                                 messageType: .text)
                Task { @ChatGlobalActor in
                    await ChatManager.activeInstance?.message.send(req)
                }
                self.start += 1
            }
        }
#endif
    }

    public static let longMessage = """
Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test %d
"""
    public static let smallMessage = "small txet %d"
}
