//
//  ThreadCalculators.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/5/25.
//

import Foundation
import TalkModels
import Chat
import TalkExtensions
import UIKit

public class ThreadCalculators {
    private static let textDirectionMark = Language.isRTL ? "\u{200f}" : "\u{200e}"
    
    @AppBackgroundActor
    public class func calculate(_ conversations: [Conversation],
                                _ myId: Int,
                                _ navSelectedId: Int? = nil,
                                _ nonArchives: Bool = true
    ) async -> [CalculatedConversation] {
        return await calculateWithGroup(conversations, myId, navSelectedId, nonArchives)
    }
    
    private class func calculateWithGroup(_ conversations: [Conversation],
                                          _ myId: Int,
                                          _ navSelectedId: Int? = nil,
                                          _ nonArchives: Bool = true
    )
    async -> [CalculatedConversation] {
        let sanitizedConversatiosn = sanitizeConversations(conversations, nonArchives)
        let convsCal = await withTaskGroup(of: CalculatedConversation.self) { group in
            for conversation in sanitizedConversatiosn {
                group.addTask {
                    return calculate(conversation, myId, navSelectedId)
                }
            }
            var calculatedRows: [CalculatedConversation] = []
            for await vm in group {
                calculatedRows.append(vm)
            }
            return calculatedRows
        }
        return convsCal
    }
    
    private class func sanitizeConversations(_ conversations: [Conversation], _ nonArchives: Bool = true) -> [Conversation] {
        let fixedTitles = fixTitleAndReactionStatus(conversations)
        if nonArchives {
            let fixedArchives = fileterNonArchives(fixedTitles)
            return fixedArchives
        }
        return fixedTitles
    }
    
    private class func fileterNonArchives(_ conversations: [Conversation]) -> [Conversation] {
        return conversations.filter({$0.isArchive == false || $0.isArchive == nil}) ?? []
    }
    
    class func calculate(
        _ conversation: Conversation,
        _ myId: Int,
        _ navSelectedId: Int? = nil
    ) -> CalculatedConversation {
        var classConversation = conversation.toClass()
        classConversation.computedTitle = calculateComputedTitle(conversation)
        classConversation.titleRTLString = calculateTitleRTLString(classConversation.computedTitle)
        classConversation.metaData = calculateMetadata(conversation.metadata)
        let avatarTuple = avatarColorName(conversation.title, classConversation.computedTitle)
        classConversation.materialBackground = avatarTuple.color
        classConversation.splitedTitle = avatarTuple.splited
        classConversation.computedImageURL = calculateImageURL(conversation.image, classConversation.metaData)
        classConversation.addRemoveParticipant = calculateAddOrRemoveParticipant(classConversation, myId)
        let isFileType = classConversation.lastMessageVO?.toMessage.isFileType == true
        classConversation.fiftyFirstCharacter = calculateFifityFirst(classConversation.lastMessageVO?.message ?? "", isFileType)
        classConversation.participantName = calculateParticipantName(classConversation, myId)
        classConversation.hasSpaceToShowPin = calculateHasSpaceToShowPin(classConversation)
        classConversation.sentFileString = sentFileString(classConversation, isFileType, myId)
        classConversation.createConversationString = createConversationString(classConversation)
        classConversation.callMessage = callMessage(classConversation)
        classConversation.isSelected = calculateIsSelected(classConversation, navSelectedId)
        
        classConversation.isCircleUnreadCount = conversation.isCircleUnreadCount
        let lastMessageIconStatus = iconStatus(conversation, myId)
        classConversation.iconStatus = lastMessageIconStatus?.icon
        classConversation.iconStatusColor = lastMessageIconStatus?.color
        classConversation.unreadCountString = calculateUnreadCountString(conversation.unreadCount) ?? ""
        classConversation.timeString = calculateThreadTime(conversation.time)
        classConversation.eventVM = ThreadEventViewModel(threadId: conversation.id ?? -1)
        
        return classConversation
    }
    
    @AppBackgroundActor
    public class func reCalculate(
        _ classConversation: CalculatedConversation,
        _ myId: Int,
        _ navSelectedId: Int? = nil)
    async -> CalculatedConversation {
        let conversation = classConversation.toStruct()
        let computedTitle = calculateComputedTitle(conversation)
        let titleRTLString = calculateTitleRTLString(classConversation.computedTitle)
        let metaData = calculateMetadata(conversation.metadata)
        let avatarTuple = avatarColorName(conversation.title, classConversation.computedTitle)
        let materialBackground = avatarTuple.color
        let splitedTitle = avatarTuple.splited
        let computedImageURL = calculateImageURL(conversation.image, classConversation.metaData)
        let addRemoveParticipant = calculateAddOrRemoveParticipant(classConversation, myId)
        let isFileType = classConversation.lastMessageVO?.toMessage.isFileType == true
        let fiftyFirstCharacter = calculateFifityFirst(classConversation.lastMessageVO?.message ?? "", isFileType)
        let participantName = calculateParticipantName(classConversation, myId)
        let hasSpaceToShowPin = calculateHasSpaceToShowPin(classConversation)
        let sentFileString = sentFileString(classConversation, isFileType, myId)
        let createConversationString = createConversationString(classConversation)
        let callMessage = callMessage(classConversation)
        let isSelected = calculateIsSelected(classConversation, navSelectedId)
        
        let isCircleUnreadCount = conversation.isCircleUnreadCount
        let lastMessageIconStatus = iconStatus(conversation, myId)
        let iconStatus = lastMessageIconStatus?.icon
        let iconStatusColor = lastMessageIconStatus?.color
        let unreadCountString = calculateUnreadCountString(conversation.unreadCount) ?? ""
        let timeString = calculateThreadTime(conversation.time)
        let eventVM = ThreadEventViewModel(threadId: conversation.id ?? -1)
        await MainActor.run {
            classConversation.computedTitle = computedTitle
            classConversation.titleRTLString = titleRTLString
            classConversation.metaData = metaData
            classConversation.materialBackground = materialBackground
            classConversation.splitedTitle = splitedTitle
            classConversation.computedImageURL = computedImageURL
            classConversation.addRemoveParticipant = addRemoveParticipant
            classConversation.fiftyFirstCharacter = fiftyFirstCharacter
            classConversation.participantName = participantName
            classConversation.hasSpaceToShowPin = hasSpaceToShowPin
            classConversation.sentFileString = sentFileString
            classConversation.createConversationString = createConversationString
            classConversation.callMessage = callMessage
            classConversation.isSelected = isSelected
            classConversation.isCircleUnreadCount = isCircleUnreadCount
            classConversation.iconStatus = iconStatus
            classConversation.iconStatusColor = iconStatusColor
            classConversation.unreadCountString = unreadCountString
            classConversation.timeString = timeString
            classConversation.eventVM = eventVM
        }
        return classConversation
    }
    
    @discardableResult
    @AppBackgroundActor
    public class func reCalculateUnreadCount(_ classConversation: CalculatedConversation) async -> CalculatedConversation {
        let unreadCount = await unreadCountOnMain(classConversation)
        let unreadCountString = calculateUnreadCountString(unreadCount) ?? ""
        let isCircleUnreadCount = unreadCount ?? 0 < 100
        await MainActor.run {
            classConversation.unreadCountString = unreadCountString
            classConversation.isCircleUnreadCount = isCircleUnreadCount
        }
        return classConversation
    }
    
    @MainActor
    private class func unreadCountOnMain(_ classConversation: CalculatedConversation) -> Int? {
        classConversation.unreadCount
    }
    
    private class func calculateComputedTitle(_ conversation: Conversation) -> String {
        if conversation.type == .selfThread {
            return String(localized: .init("Thread.selfThread"), bundle: Language.preferedBundle)
        }
        return conversation.title ?? ""
    }
    
    private class func calculateTitleRTLString(_ computedTitle: String) -> String {
        return textDirectionMark + computedTitle
    }
    
    private class func fixTitleAndReactionStatus(_ conversations: [Conversation]) -> [Conversation] {
        var conversations = conversations
        conversations.enumerated().forEach { index, thread in
            conversations[index].title = thread.title?.stringToScalarEmoji()
            conversations[index].reactionStatus = thread.reactionStatus ?? .enable
        }
        return conversations
    }
    
    private class func calculateImageURL(_ image: String?, _ metaData: FileMetaData?) -> String? {
        let computedImageURL = (image ?? metaData?.file?.link)?.replacingOccurrences(of: "http://", with: "https://")
        return computedImageURL
    }
    
    private class func avatarColorName(_ title: String?, _ computedTitle: String) -> (splited: String, color: UIColor) {
        let materialBackground = String.getMaterialColorByCharCode(str: title ?? "")
        let splitedTitle = String.splitedCharacter(computedTitle)
        return (splitedTitle, materialBackground)
    }
    
    private class func calculateMetadata(_ metadata: String?) -> FileMetaData? {
        guard let metadata = metadata?.data(using: .utf8),
              let metaData = try? JSONDecoder().decode(FileMetaData.self, from: metadata) else { return nil }
        return metaData
    }
    
    private class func iconStatus(_ conversation: Conversation, _ myId: Int) -> (icon: UIImage, color: UIColor)? {
        if conversation.group == true || conversation.type == .selfThread { return nil }
        if !isLastMessageMine(lastMessageVO: conversation.lastMessageVO, myId: myId) { return nil }
        let lastID = conversation.lastMessageVO?.id ?? 0
        if let partnerLastSeenMessageId = conversation.partnerLastSeenMessageId, partnerLastSeenMessageId == lastID {
            return (MessageHistoryStatics.seenImage!, UIColor(named: "accent") ?? .clear)
        } else if let partnerLastDeliveredMessageId = conversation.partnerLastDeliveredMessageId, partnerLastDeliveredMessageId == lastID {
            return (MessageHistoryStatics.sentImage!, UIColor(named: "text_secondary") ?? .clear)
        } else if lastID > conversation.partnerLastSeenMessageId ?? 0 {
            return (MessageHistoryStatics.sentImage!, UIColor(named: "text_secondary") ?? .clear)
        } else { return nil }
    }
    
    private class func isLastMessageMine(lastMessageVO: LastMessageVO?, myId: Int?) -> Bool {
        (lastMessageVO?.ownerId ?? lastMessageVO?.participant?.id) ?? 0 == myId
    }
    
    private class func calculateThreadTime(_ time: UInt?) -> String {
        time?.date.localTimeOrDate ?? ""
    }
    
    private class func calculateUnreadCountString(_ unreadCount: Int?) -> String? {
        if let unreadCount = unreadCount, unreadCount > 0 {
            let unreadCountString = unreadCount.localNumber(locale: Language.preferredLocale)
            let computedString = unreadCount < 1000 ? unreadCountString : "+\(999.localNumber(locale: Language.preferredLocale) ?? "")"
            return computedString
        } else {
            return nil
        }
    }
    
    private class func calculateAddOrRemoveParticipant(_ conversation: CalculatedConversation, _ myId: Int) -> String? {
        guard conversation.lastMessageVO?.messageType == .participantJoin || conversation.lastMessageVO?.messageType == .participantLeft,
              let metadata = conversation.lastMessageVO?.metadata?.data(using: .utf8) else { return nil }
        let addRemoveParticipant = try? JSONDecoder.instance.decode(AddRemoveParticipant.self, from: metadata)
        
        guard let requestType = addRemoveParticipant?.requestTypeEnum else { return nil }
        let isMe = conversation.lastMessageVO?.participant?.id == myId
        let effectedName = addRemoveParticipant?.participnats?.first?.name ?? ""
        let participantName = conversation.lastMessageVO?.participant?.name ?? ""
        let effectedParticipantsName = addRemoveParticipant?.participnats?.compactMap{$0.name}.joined(separator: ", ") ?? ""
        switch requestType {
        case .leaveThread:
            return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.left", bundle: Language.preferedBundle, comment: ""), participantName)
        case .joinThread:
            return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.joined", bundle: Language.preferedBundle, comment: ""), participantName)
        case .removedFromThread:
            if isMe {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.removedByMe", bundle: Language.preferedBundle, comment: ""), effectedName)
            } else {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.removed", bundle: Language.preferedBundle, comment: ""), participantName, effectedName)
            }
        case .addParticipant:
            if isMe {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.addedByMe", bundle: Language.preferedBundle, comment: ""), effectedParticipantsName)
            } else {
                return MessageHistoryStatics.textDirectionMark + String(format: NSLocalizedString("Message.Participant.added", bundle: Language.preferedBundle, comment: ""), participantName, effectedParticipantsName)
            }
        default:
            return nil
        }
    }
    
    private class func calculateHasSpaceToShowPin(_ conversation: CalculatedConversation) -> Bool {
        let allActive = conversation.pin == true && conversation.mute == true && conversation.unreadCount ?? 0 > 0
        return !allActive
    }

    private class func calculateFifityFirst(_ message: String, _ isFileType: Bool) -> String? {
        if !isFileType {
            return String(message.replacingOccurrences(of: "\n", with: " ").prefix(50))
        }
        return nil
    }

    private class func calculateParticipantName(_ conversation: CalculatedConversation, _ myId: Int) -> String? {
        if let participantName = conversation.lastMessageVO?.participant?.contactName ?? conversation.lastMessageVO?.participant?.name, conversation.group == true {
            let meVerb = String(localized: .init("General.you"), bundle: Language.preferedBundle)
            let localized = String(localized: .init("Thread.Row.lastMessageSender"), bundle: Language.preferedBundle)
            let participantName = String(format: localized, participantName)
            let isMe = conversation.lastMessageVO?.ownerId ?? 0 == myId
            let name = isMe ? "\(meVerb):" : participantName
            return MessageHistoryStatics.textDirectionMark + name
        } else {
            return nil
        }
    }

    private class func createConversationString(_ conversation: CalculatedConversation) -> String? {
        if conversation.lastMessageVO == nil, let creator = conversation.inviter?.name {
            let type = conversation.type
            let key = type?.isChannelType == true ? "Thread.createdAChannel" : "Thread.createdAGroup"
            let localizedLabel = String(localized: .init(key), bundle: Language.preferedBundle)
            let text = String(format: localizedLabel, creator)
            return text
        } else {
            return nil
        }
    }

    private class func sentFileString(_ conversation: CalculatedConversation, _ isFileType: Bool, _ myId: Int) -> String? {
        if isFileType {
            let fileStringName = conversation.lastMessageVO?.messageType?.fileStringName ?? "MessageType.file"
            let isMe = conversation.lastMessageVO?.ownerId ?? 0 == myId
            let sentVerb = String(localized: .init(isMe ? "Genral.mineSendVerb" : "General.thirdSentVerb"), bundle: Language.preferedBundle)
            let formatted = String(format: sentVerb, fileStringName.bundleLocalized())
            return MessageHistoryStatics.textDirectionMark + "\(formatted)"
        } else {
            return nil
        }
    }

    private class func callMessage(_ conversation: CalculatedConversation) -> Message? {
        if let message = conversation.lastMessageVO, message.messageType == .endCall || message.messageType == .startCall {
            return message.toMessage
        } else {
            return nil
        }
    }
    
    private class func calculateIsSelected(_ conversation: CalculatedConversation, _ navSelectedId: Int?) -> Bool {
        if navSelectedId == conversation.id {
            return conversation.isInForwardMode == true ? false : (navSelectedId == conversation.id)
        } else if conversation.isSelected == true {
            return false
        }
        return false
    }
}
