//
//  Notification.Name+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import Chat

@MainActor
public extension Notification.Name {
    static let onRequestTimer = Notification.Name("onRequestTimer")
    static let download = Notification.Name("download")
    static let upload = Notification.Name("upload")
    static let assistant = Notification.Name("assistant")
    static let file = Notification.Name("file")
    static let bot = Notification.Name("bot")
    static let participant = Notification.Name("participant")
    static let tag = Notification.Name("tag")
    static let reaction = Notification.Name("reaction")
    static let user = Notification.Name("user")
    static let draft = Notification.Name("draft")
    static let connect = Notification.Name("connect")
    static let message = Notification.Name("message")
    static let system = Notification.Name("system")
    static let thread = Notification.Name("thread")
    static let contact = Notification.Name("contact")
    static let call = Notification.Name("call")
    static let login = Notification.Name("login")
    static let windowMode = Notification.Name("windowMode")
    static let closeSideBar = Notification.Name("closeSideBar")
    static let galleryDownload = Notification.Name("galleryDownload")
    static let selectTab = Notification.Name("selectTab")
    static let appSettingsModel = Notification.Name("appSettingsModel")
    static let cancelSearch = Notification.Name("cancelSearch")
    static let forceSearch = Notification.Name("forceSearch")
    static let error = Notification.Name("error")
}

@MainActor
public extension NotificationCenter {
    static let onRequestTimer = NotificationCenter()
    static let download = NotificationCenter()
    static let upload = NotificationCenter()
    static let assistant = NotificationCenter()
    static let file = NotificationCenter()
    static let bot = NotificationCenter()
    static let participant = NotificationCenter()
    static let tag = NotificationCenter()
    static let map = NotificationCenter()
    static let reaction = NotificationCenter()
    static let user = NotificationCenter()
    static let draft = NotificationCenter()
    static let connect = NotificationCenter()
    static let message = NotificationCenter()
    static let system = NotificationCenter()
    static let thread = NotificationCenter()
    static let contact = NotificationCenter()
    static let call = NotificationCenter()
    static let login = NotificationCenter()
    static let logs = NotificationCenter()
    static let windowMode = NotificationCenter()
    static let closeSideBar = NotificationCenter()
    static let galleryDownload = NotificationCenter()
    static let selectTab = NotificationCenter()
    static let appSettingsModel = NotificationCenter()
    static let cancelSearch = NotificationCenter()
    static let forceSearch = NotificationCenter()
    static let error = NotificationCenter()

    class func post(event: ChatEventType) {
        switch event {
        case let .bot(botEventTypes):
            Self.bot.post(name: .bot, object: botEventTypes)
        case let .contact(contactEventTypes):
            Self.contact.post(name: .contact, object: contactEventTypes)
        case let .download(downloadEventTypes):
            Self.download.post(name: .download, object: downloadEventTypes)
        case let .upload(uploadEventTypes):
            Self.upload.post(name: .upload, object: uploadEventTypes)
        case let .system(systemEventTypes):
            if case .error(let chatResponse) = systemEventTypes {
                Self.error.post(name: .error, object: chatResponse)
            }
            Self.system.post(name: .system, object: systemEventTypes)
        case let .message(messageEventTypes):
            Self.message.post(name: .message, object: messageEventTypes)
        case let .thread(threadEventTypes):
            Self.thread.post(name: .thread, object: threadEventTypes)
        case let .user(userEventTypes):
            Self.user.post(name: .user, object: userEventTypes)
        case let .assistant(assistantEventTypes):
            Self.assistant.post(name: .assistant, object: assistantEventTypes)
        case let .tag(tagEventTypes):
            Self.tag.post(name: .tag, object: tagEventTypes)
        case let .call(callEventTypes):
            Self.call.post(name: .call, object: callEventTypes)
        case let .participant(participantEventTypes):
            Self.participant.post(name: .participant, object: participantEventTypes)
        case let .reaction(reactionEventTypes):
            Self.reaction.post(name: .reaction, object: reactionEventTypes)
        }
    }
}
