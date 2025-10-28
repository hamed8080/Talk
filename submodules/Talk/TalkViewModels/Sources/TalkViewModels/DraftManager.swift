//
//  DraftManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat

public final class DraftManager: Sendable {
    private let contactKey = "contact-draft-"
    private let conversationKey = "conversation-draft-"
    private let eidtMessageKey = "edit-draft-"
    private let replyMessageKey = "reply-draft-"
    private init() {}

    public func get(threadId: Int) -> String? {
        UserDefaults.standard.string(forKey: getConversationKey(threadId: threadId))
    }

    public func get(contactId: Int) -> String? {
        UserDefaults.standard.string(forKey: getContactKey(contactId: contactId))
    }

    public func set(draftValue: String, threadId: Int) {
        if draftValue.isEmpty {
            clear(threadId: threadId)
        } else {
            UserDefaults.standard.setValue(draftValue, forKey: getConversationKey(threadId: threadId))
        }
        Task { @MainActor in
            let threadsVM = AppState.shared.objectsContainer.threadsVM
            if let conversation = threadsVM.threads.first(where: { $0.id == threadId}) {
                threadsVM.recalculateAndAnimate(conversation)
            }
            
            let archivesVM = AppState.shared.objectsContainer.archivesVM
            if let conversation = archivesVM.threads.first(where: { $0.id == threadId}) {
                archivesVM.recalculateAndAnimate(conversation)
            }
            NotificationCenter.draft.post(name: .draft, object: threadId)
        }
    }

    public func set(draftValue: String, contactId: Int) {
        if draftValue.isEmpty {
            clear(contactId: contactId)
        } else {
            UserDefaults.standard.setValue(draftValue, forKey: getContactKey(contactId: contactId))
        }
        
        Task { @MainActor in
            NotificationCenter.draft.post(name: .draft, object: contactId)
        }
    }

    public func setEditMessageDraft(_ editMessage: Message?, threadId: Int) {
        if editMessage == nil {
            clearEditMessage(threadId: threadId)
        } else if let editMessage = editMessage {
            UserDefaults.standard.setValue(codable: editMessage, forKey: getEditMessageKey(threadId: threadId))
        }
    }

    public func editMessageText(threadId: Int) -> Message? {
        let message: Message? = UserDefaults.standard.codableValue(forKey: getEditMessageKey(threadId: threadId))
        return message
    }
    
    public func replyMessageText(threadId: Int) -> Message? {
        let message: Message? = UserDefaults.standard.codableValue(forKey: getReplyMessageKey(threadId: threadId))
        return message
    }
    
    public func setReplyMessageDraft(_ replyMessage: Message?, threadId: Int) {
        if replyMessage == nil {
            clearReplyMessage(threadId: threadId)
        } else if let replyMessage = replyMessage {
            UserDefaults.standard.setValue(codable: replyMessage, forKey: getReplyMessageKey(threadId: threadId))
        }
    }

    public func clear(threadId: Int) {
        UserDefaults.standard.removeObject(forKey: getConversationKey(threadId: threadId))
    }

    public func clear(contactId: Int) {
        UserDefaults.standard.removeObject(forKey: getContactKey(contactId: contactId))
    }

    private func clearEditMessage(threadId: Int) {
        UserDefaults.standard.removeObject(forKey: getEditMessageKey(threadId: threadId))
    }
    
    private func clearReplyMessage(threadId: Int) {
        UserDefaults.standard.removeObject(forKey: getReplyMessageKey(threadId: threadId))
    }

    private func getConversationKey(threadId: Int) -> String {
        "\(conversationKey)\(threadId)"
    }

    private func getEditMessageKey(threadId: Int) -> String {
        "\(eidtMessageKey)\(threadId)"
    }
    
    private func getReplyMessageKey(threadId: Int) -> String {
        "\(replyMessageKey)\(threadId)"
    }

    private func getContactKey(contactId: Int) -> String {
        "\(contactKey)\(contactId)"
    }
}

public extension DraftManager {
    static let shared = DraftManager()
}
