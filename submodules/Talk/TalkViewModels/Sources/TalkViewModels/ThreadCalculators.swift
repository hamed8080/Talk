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
    public class func calculate(conversations: [Conversation],
                                myId: Int,
                                navSelectedId: Int? = nil,
                                nonArchives: Bool = true,
                                keepOrder: Bool = false
    ) async -> [CalculatedConversation] {
        if keepOrder {
            return orderedCalculations(conversations: conversations, myId: myId, navSelectedId: navSelectedId)
        }
        return await calculateWithGroup(conversations, myId, navSelectedId, nonArchives)
    }
    
    private static func orderedCalculations(conversations: [Conversation], myId: Int, navSelectedId: Int? = nil) -> [CalculatedConversation] {
        var calThreads: [CalculatedConversation] = []
        for conversation in conversations {
            let cal = calculate(conversation, myId, navSelectedId)
            calThreads.append(cal)
        }
        return calThreads
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
        let fixedTitles = fixReactionStatus(conversations)
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
        classConversation.titleRTLString = calculateTitleRTLString(classConversation.computedTitle, conversation)
        classConversation.metaData = calculateMetadata(conversation.metadata)
        let avatarTuple = avatarColorName(conversation.title, classConversation.computedTitle)
        classConversation.materialBackground = avatarTuple.color
        classConversation.splitedTitle = avatarTuple.splited
        classConversation.computedImageURL = calculateImageURL(conversation.image, classConversation.metaData)
        let isFileType = classConversation.lastMessageVO?.toMessage.isFileType == true
       
        classConversation.hasSpaceToShowPin = calculateHasSpaceToShowPin(conversation)
        classConversation.isSelected = calculateIsSelected(conversation, isSelected: false, isInForwardMode: false, navSelectedId)
        
        classConversation.isCircleUnreadCount = conversation.isCircleUnreadCount
        let lastMessageIconStatus = iconStatus(conversation, myId)
        classConversation.iconStatus = lastMessageIconStatus?.icon
        classConversation.iconStatusColor = lastMessageIconStatus?.color
        classConversation.unreadCountString = calculateUnreadCountString(conversation.unreadCount) ?? ""
        classConversation.timeString = calculateThreadTime(conversation.time)
        classConversation.eventVM = ThreadEventViewModel(threadId: conversation.id ?? -1)
        classConversation.isTalk = conversation.isTalk
        classConversation.subtitleAttributedString = caculateSubtitle(conversation: conversation, myId: myId, isFileType: isFileType)
        
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
        let titleRTLString = calculateTitleRTLString(computedTitle, conversation)
        let metaData = calculateMetadata(conversation.metadata)
        let avatarTuple = avatarColorName(conversation.title, computedTitle)
        let materialBackground = avatarTuple.color
        let splitedTitle = avatarTuple.splited
        let computedImageURL = calculateImageURL(conversation.image, conversation.metaData)
        let isFileType = conversation.lastMessageVO?.toMessage.isFileType == true
        let fiftyFirstCharacter = calculateFifityFirst(conversation.lastMessageVO?.message ?? "", isFileType)
        let hasSpaceToShowPin = calculateHasSpaceToShowPin(conversation)
        let sentFileString = sentFileString(conversation, isFileType, myId)
        let createConversationString = createConversationString(conversation)
        let isSelected = calculateIsSelected(conversation, isSelected: wasSelected, isInForwardMode: classConversation.isInForwardMode, navSelectedId)
        
        let isCircleUnreadCount = conversation.isCircleUnreadCount
        let lastMessageIconStatus = iconStatus(conversation, myId)
        let iconStatus = lastMessageIconStatus?.icon
        let iconStatusColor = lastMessageIconStatus?.color
        let unreadCountString = calculateUnreadCountString(conversation.unreadCount) ?? ""
        let timeString = calculateThreadTime(conversation.time)
        let eventVM = classConversation.eventVM as? ThreadEventViewModel ?? ThreadEventViewModel(threadId: conversation.id ?? -1)
        let subtitleAttributdString = caculateSubtitle(conversation: conversation, myId: myId, isFileType: isFileType)
        await MainActor.run {
            classConversation.computedTitle = computedTitle
            classConversation.titleRTLString = titleRTLString
            classConversation.metaData = metaData
            classConversation.materialBackground = materialBackground
            classConversation.splitedTitle = splitedTitle
            classConversation.computedImageURL = computedImageURL
            classConversation.subtitleAttributedString = subtitleAttributdString
            classConversation.hasSpaceToShowPin = hasSpaceToShowPin
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
        return conversation.title?.stringToScalarEmoji() ?? ""
    }
    
    public class func calculateTitleRTLString(_ computedTitle: String, _ conversation: Conversation) -> NSAttributedString {
        let titleAttributedString = NSAttributedString(string: textDirectionMark + computedTitle)
        if conversation.isTalk, let image = UIImage(named: "ic_approved") {
            let mutable = NSMutableAttributedString(attributedString: titleAttributedString)
            let imgAttachment = NSTextAttachment(image: image)
            imgAttachment.bounds = CGRect(x: 0, y: -6, width: 18, height: 18)
            let attachmentAttribute = NSAttributedString(attachment: imgAttachment)
            mutable.append(NSAttributedString(string: " "))
            mutable.append(attachmentAttribute)
            return mutable
        } else if conversation.type?.isChannelType == true, let image = UIImage(named: "ic_channel")?.withTintColor(.gray) {
            let mutable = NSMutableAttributedString(attributedString: NSAttributedString(string: ""))
            let imgAttachment = NSTextAttachment(image: image)
            imgAttachment.bounds = CGRect(x: 0, y: -2, width: 18, height: 18)
            let attachmentAttribute = NSAttributedString(attachment: imgAttachment)
            mutable.append(attachmentAttribute)
            mutable.append(NSAttributedString(string: " "))
            mutable.append(titleAttributedString)
            return mutable
        } else if conversation.group == true, conversation.type?.isChannelType == false, let image = UIImage(systemName: "person.2.fill")?.withTintColor(.gray) {
            let mutable = NSMutableAttributedString(attributedString: NSAttributedString(string: ""))
            let imgAttachment = NSTextAttachment(image: image)
            imgAttachment.bounds = CGRect(x: 0, y: -4, width: 22, height: 16)
            let attachmentAttribute = NSAttributedString(attachment: imgAttachment)
            mutable.append(attachmentAttribute)
            mutable.append(NSAttributedString(string: " "))
            mutable.append(titleAttributedString)
            return mutable
        } else {
            return titleAttributedString
        }
    }
    
    private class func fixReactionStatus(_ conversations: [Conversation]) -> [Conversation] {
        var conversations = conversations
        conversations.enumerated().forEach { index, thread in
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

    private class func calculateFifityFirst(_ message: String, _ isFileType: Bool) -> NSAttributedString? {
        // Step 1: Remove Markdown style
        var message = removeMessageTextStyle(message: message)
        
        // Step 2: Decode HTML entities (e.g., &amp; → &)
        message = message.convertedHTMLEncoding
        
        if !isFileType {
            let subString = message.replacingOccurrences(of: "\n", with: " ").prefix(50)
            return NSAttributedString(string: String(subString))
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
        let lastMessage = conversation.lastMessageVO
        if lastMessage?.messageType != .endCall && lastMessage?.messageType != .startCall,
           let participantName = lastMessage?.participant?.contactName ?? lastMessage?.participant?.name, conversation.group == true {
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
    
    public static func caculateSubtitle(conversation: Conversation, myId: Int, isFileType: Bool) -> NSAttributedString? {
        var mutable = NSMutableAttributedString(string: "")
        if let addOrRemoveParticipant = calculateAddOrRemoveParticipant(conversation.lastMessageVO, myId) {
            mutable.append(NSAttributedString(string: addOrRemoveParticipant))
        } else if let participantName = calculateParticipantName(conversation, myId) {
            mutable.append(NSAttributedString(string: participantName, attributes: [
                .foregroundColor: UIColor(named: "accent")
            ]))
            mutable.append(NSAttributedString(string: " "))
        } else if let createdConversationString = createConversationString(conversation) {
            mutable.append(NSAttributedString(string: createdConversationString, attributes: [
                .foregroundColor: UIColor(named: "accent")
            ]))
            mutable.append(NSAttributedString(string: " "))
        } else if let callAttri = callMessageAttributedString(conversation, myId) {
            mutable.append(callAttri)
            mutable.append(NSAttributedString(string: " "))
        }
        
        if let fileString = sentFileString(conversation, isFileType, myId)  {
            mutable.append(NSAttributedString(string: fileString, attributes: [
                .foregroundColor: UIColor(named: "text_secondary")
            ]))
            mutable.append(NSAttributedString(string: " "))
        }
        
        let draft = DraftManager.shared.get(threadId: conversation.id ?? -1)
        if let draft = draft, !draft.isEmpty {
            /// Need to reset all above attributes
            mutable = NSMutableAttributedString(string: "")
            mutable.append(
                NSAttributedString(
                    string: "Thread.draft".bundleLocalized(),
                    attributes: [
                        .foregroundColor: UIColor(named: "red")
                    ]
                )
            )
            mutable.append(
                NSAttributedString(
                    string: " \(draft)"
                )
            )
        }

        
        if draft?.isEmpty == true || draft == nil,
           let message = conversation.lastMessageVO?.toMessage,
           let fiftyString = calculateFifityFirst(message.message ?? "", isFileType)
        {
            mutable.append(fiftyString)
        }
        return mutable
    }

    private static func callMessageAttributedString(_ conversation: Conversation, _ myId: Int) -> NSAttributedString? {
        guard let message = conversation.lastMessageVO?.toMessage,
              message.messageType == .endCall || message.messageType == .startCall,
              let status = message.callHistory?.status,
              let key = status.key?.bundleLocalized(),
              let time = message.time
        else { return nil }
        
        var mutable = NSMutableAttributedString(string: "")
        
        let isCallStarter = message.participant?.id == myId
        
        let isStarted = message.type == .startCall
        let isMissed = status == .declined || status == .miss
        let isCanceled = status == .canceled && isCallStarter
        let isDeclined = status == .canceled && !isCallStarter
        let isEnded = status == .ended
        
        let missed = status == .declined && message.callHistory?.startTime == nil
        let missString = missed ? "CallStatus.miss".bundleLocalized() : nil
        
        let imageName = isStarted ? "phone.fill" : isMissed ? "phone.arrow.down.left.fill" : "phone.down.fill"
        let uiImage = UIImage(systemName: imageName) ?? UIImage()
        let imgColor = UIColor(named: message.type == .startCall ? "color2" : "red")
        let imgAttachment = NSTextAttachment(image: uiImage.withTintColor(imgColor ?? .gray))
        imgAttachment.bounds = CGRect(x: 0, y: -2, width: 20, height: isEnded ? 8 : 16)
        let attachmentAttribute = NSAttributedString(attachment: imgAttachment)
        mutable.append(attachmentAttribute)
        mutable.append(NSAttributedString(string: " "))
        
        let color = UIColor(named: "text_primary")?.withAlphaComponent(0.7)
        mutable.append(NSAttributedString(string: missString ?? key, attributes: [
            .foregroundColor: color,
            .font: UIFont(name: "SVJBTlNhbnNY".fromBase64() ?? "", size: 12)
        ]))
        mutable.append(NSAttributedString(string: " "))
        
        let dateString = Date(milliseconds: Int64(time)).localFormattedTime ?? ""
        mutable.append(NSAttributedString(string: dateString, attributes: [
            .foregroundColor: color,
            .font: UIFont(name: "SVJBTlNhbnNYLUJvbGQ=".fromBase64() ?? "", size: 12)
        ]))
        mutable.append(NSAttributedString(string: " "))
        
        if isEnded {
            let duration = (message.callHistory?.endTime ?? 0) - (message.callHistory?.startTime ?? 0)
            let seconds = duration / 1000
            let durationString = seconds.timerStringTripleSection(locale: Language.preferredLocale) ?? ""
            
            let textDuration = "Thread.callEndedDuration".bundleLocalized()
            mutable.append(NSAttributedString(string: String(format: textDuration, durationString)))
        }

        return mutable
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
