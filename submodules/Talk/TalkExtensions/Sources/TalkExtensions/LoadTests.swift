//
//  LoadTests.swift
//  TalkExtensions
//
//  Created by hamed on 3/29/23.
//

import Foundation
import Chat

public class LoadTests {
    public class func rapidSend(threadId: Int,
                                messageTempelate: String,
                                start: Int,
                                end: Int,
                                duration: TimeInterval = 3) {
#if DEBUG
        var start = start
        Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { timer in
            if start < end {
                let req = SendTextMessageRequest(threadId: threadId,
                                                 textMessage: String(format: messageTempelate, start) ,
                                                 messageType: .text)
                ChatManager.activeInstance?.message.send(req)
                start += 1
            }
        }
#endif
    }

    public static let longMessage = """
Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test Test long test %d
"""
    public static let smallMessage = "small txet %d"
}
