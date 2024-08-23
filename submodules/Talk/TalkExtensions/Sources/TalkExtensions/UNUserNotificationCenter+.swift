//
//  UNUserNotificationCenter+.swift
//  TalkExtensions
//
//  Created by hamed on 3/14/23.
//

import Foundation
import NotificationCenter
import Chat
import TalkModels

public extension UNUserNotificationCenter {
    class func localNewMessageNotif(_ message: any HistoryMessageProtocol, showName: Bool = true) {
        let content = UNMutableNotificationContent()
        content.badge = NSNumber(value: message.conversation?.unreadCount ?? 0)
        if showName {
            content.title = message.participant?.name ?? ""
        }
        content.body = message.messageTitle
        content.threadIdentifier = "\(message.conversation?.id ?? 0)"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request)
    }
}
