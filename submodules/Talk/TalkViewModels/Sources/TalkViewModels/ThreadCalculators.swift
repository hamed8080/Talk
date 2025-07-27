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
        classConversation.addRemoveParticipant = calculateAddOrRemoveParticipant(classConversation.lastMessageVO, myId)
        let isFileType = classConversation.lastMessageVO?.toMessage.isFileType == true
        classConversation.fiftyFirstCharacter = calculateFifityFirst(classConversation.lastMessageVO?.message ?? "", isFileType)
        classConversation.participantName = calculateParticipantName(conversation, myId)
        classConversation.hasSpaceToShowPin = calculateHasSpaceToShowPin(conversation)
        classConversation.sentFileString = sentFileString(conversation, isFileType, myId)
        classConversation.createConversationString = createConversationString(conversation)
        classConversation.callMessage = callMessage(conversation)
        classConversation.isSelected = calculateIsSelected(conversation, isSelected: false, isInForwardMode: false, navSelectedId)
        
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
        let wasSelected = await wasSelectedOnMain(classConversation)
        let conversation = await convertToStruct(classConversation)
        let computedTitle = calculateComputedTitle(conversation)
        let titleRTLString = calculateTitleRTLString(conversation.computedTitle)
        let metaData = calculateMetadata(conversation.metadata)
        let avatarTuple = avatarColorName(conversation.title, conversation.computedTitle)
        let materialBackground = avatarTuple.color
        let splitedTitle = avatarTuple.splited
        let computedImageURL = calculateImageURL(conversation.image, conversation.metaData)
        let addRemoveParticipant = calculateAddOrRemoveParticipant(conversation.lastMessageVO, myId)
        let isFileType = conversation.lastMessageVO?.toMessage.isFileType == true
        let fiftyFirstCharacter = calculateFifityFirst(conversation.lastMessageVO?.message ?? "", isFileType)
        let participantName = calculateParticipantName(conversation, myId)
        let hasSpaceToShowPin = calculateHasSpaceToShowPin(conversation)
        let sentFileString = sentFileString(conversation, isFileType, myId)
        let createConversationString = createConversationString(conversation)
        let callMessage = callMessage(conversation)
        let isSelected = calculateIsSelected(conversation, isSelected: wasSelected, isInForwardMode: classConversation.isInForwardMode, navSelectedId)
        
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
    
    @MainActor
    private class func wasSelectedOnMain(_ classConversation: CalculatedConversation) -> Bool {
        classConversation.isSelected
    }
    
    private class func convertToStruct(_ classConversation: CalculatedConversation) -> Conversation {
        classConversation.toStruct()
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
    
    private class func unreadCountOnMain(_ classConversation: CalculatedConversation) -> Int? {
        classConversation.unreadCount
    }
    
    private class func calculateComputedTitle(_ conversation: Conversation) -> String {
        if conversation.type == .selfThread {
            return "Thread.selfThread".bundleLocalized()
        }
        return conversation.title ?? ""
    }
    
    public class func calculateTitleRTLString(_ computedTitle: String) -> String {
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
    
    public class func calculateImageURL(_ image: String?, _ metaData: FileMetaData?) -> String? {
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
    
    private class func calculateAddOrRemoveParticipant(_ lastMessageVO: LastMessageVO?, _ myId: Int) -> String? {
        guard lastMessageVO?.messageType == .participantJoin || lastMessageVO?.messageType == .participantLeft,
              let metadata = lastMessageVO?.metadata?.data(using: .utf8) else { return nil }
        let addRemoveParticipant = try? JSONDecoder.instance.decode(AddRemoveParticipant.self, from: metadata)
        
        guard let requestType = addRemoveParticipant?.requestTypeEnum else { return nil }
        let isMe = lastMessageVO?.participant?.id == myId
        let effectedName = addRemoveParticipant?.participnats?.first?.name ?? ""
        let participantName = lastMessageVO?.participant?.name ?? ""
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
    
    private class func calculateHasSpaceToShowPin(_ conversation: Conversation) -> Bool {
        let allActive = conversation.pin == true && conversation.mute == true && conversation.unreadCount ?? 0 > 0
        return !allActive
    }

    private class func calculateFifityFirst(_ message: String, _ isFileType: Bool) -> String? {
        let message = removeMessageTextStyle(message: message)
        if !isFileType {
            return String(message.replacingOccurrences(of: "\n", with: " ").prefix(50))
        }
        return nil
    }

    public class func removeMessageTextStyle(message: String) -> String {
        message.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "~~", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "__", with: "")
    }

    private class func calculateParticipantName(_ conversation: Conversation, _ myId: Int) -> String? {
        if let participantName = conversation.lastMessageVO?.participant?.contactName ?? conversation.lastMessageVO?.participant?.name, conversation.group == true {
            let meVerb = "General.you".bundleLocalized()
            let localized = "Thread.Row.lastMessageSender".bundleLocalized()
            let participantName = String(format: localized, participantName)
            let isMe = conversation.lastMessageVO?.ownerId ?? 0 == myId
            let name = isMe ? "\(meVerb):" : participantName
            return MessageHistoryStatics.textDirectionMark + name
        } else {
            return nil
        }
    }

    private class func createConversationString(_ conversation: Conversation) -> String? {
        if conversation.lastMessageVO == nil, let creator = conversation.inviter?.name {
            let type = conversation.type
            let key = type?.isChannelType == true ? "Thread.createdAChannel" : "Thread.createdAGroup"
            let localizedLabel = key.bundleLocalized()
            let text = String(format: localizedLabel, creator)
            return text
        } else {
            return nil
        }
    }

    private class func sentFileString(_ conversation: Conversation, _ isFileType: Bool, _ myId: Int) -> String? {
        if isFileType {
            var fileStringName = conversation.lastMessageVO?.messageType?.fileStringName ?? "MessageType.file"
            var isLocation = false
            if let data = conversation.lastMessageVO?.metadata?.data(using: .utf8),
               let _ = try? JSONDecoder().decode(FileMetaData.self, from: data).mapLink {
                fileStringName =  "MessageType.location"
            }
            let isMe = conversation.lastMessageVO?.ownerId ?? 0 == myId
            let sentVerb = (isMe ? "Genral.mineSendVerb" : "General.thirdSentVerb").bundleLocalized()
            let formatted = String(format: sentVerb, fileStringName.bundleLocalized())
            return MessageHistoryStatics.textDirectionMark + "\(formatted)"
        } else {
            return nil
        }
    }

    private class func callMessage(_ conversation: Conversation) -> Message? {
        if let message = conversation.lastMessageVO, message.messageType == .endCall || message.messageType == .startCall {
            return message.toMessage
        } else {
            return nil
        }
    }
    
    private class func calculateIsSelected(_ conversation: Conversation, isSelected: Bool, isInForwardMode: Bool, _ navSelectedId: Int?) -> Bool {
        if navSelectedId == conversation.id {
            return isInForwardMode == true ? false : (navSelectedId == conversation.id)
        } else if isSelected == true {
            return false
        }
        return false
    }
}
