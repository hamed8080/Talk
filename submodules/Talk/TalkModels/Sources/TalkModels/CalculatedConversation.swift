//
//  CalculatedConversation.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatModels
#if canImport(UIKit)
import UIKit
#endif
import Combine

public class CalculatedConversation: @unchecked Sendable, Hashable, Identifiable, ObservableObject {
    
    public static func == (lhs: CalculatedConversation, rhs: CalculatedConversation) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(admin)
        hasher.combine(title)
        hasher.combine(lastMessageVO?.message)
        hasher.combine(lastMessageVO?.id)
        hasher.combine(lastMessageVO?.seen)
        hasher.combine(lastMessageVO?.delivered)
        hasher.combine(lastMessageVO?.metadata)
        hasher.combine(mentioned)
        hasher.combine(mute)
        hasher.combine(participantCount)
        hasher.combine(participantCount)
        hasher.combine(time)
        hasher.combine(unreadCount)
        hasher.combine(isArchive)
        hasher.combine(pinMessage?.id)
        hasher.combine(pinMessage?.text)
        hasher.combine(pinMessage?.text)
        hasher.combine(iconStatus)
        hasher.combine(iconStatusColor)
    }
    
    public var admin: Bool?
    public var canEditInfo: Bool?
    public var canSpam: Bool = false
    public var closed: Bool = false
    public var description: String?
    public var group: Bool?
    public var id: Int?
    public var image: String?
    public var joinDate: Int?
    public var lastMessage: String?
    public var lastParticipantImage: String?
    public var lastParticipantName: String?
    public var lastSeenMessageId: Int?
    public var lastSeenMessageNanos: UInt?
    public var lastSeenMessageTime: UInt?
    public var mentioned: Bool?
    public var metadata: String?
    public var mute: Bool?
    public var participantCount: Int?
    public var partner: Int?
    public var partnerLastDeliveredMessageId: Int?
    public var partnerLastDeliveredMessageNanos: UInt?
    public var partnerLastDeliveredMessageTime: UInt?
    public var partnerLastSeenMessageId: Int?
    public var partnerLastSeenMessageNanos: UInt?
    public var partnerLastSeenMessageTime: UInt?
    public var pin: Bool?
    public var time: UInt?
    public var title: String?
    public var type: ThreadTypes?
    public var unreadCount: Int?
    public var uniqueName: String?
    public var userGroupHash: String?
    public var inviter: Participant?
    public var lastMessageVO: LastMessageVO?
    public var participants: [Participant]?
    public var isArchive: Bool?
    public var pinMessage: PinMessage?
    public var reactionStatus: ReactionStatus?
        
    public var isSelected: Bool = false
    public var computedTitle: String = ""
    public var unreadCountString: String = ""
    public var isCircleUnreadCount: Bool = true
    public var isTalk: Bool = false
    public var titleRTLString: NSAttributedString?
#if canImport(UIKit)
    public var materialBackground: UIColor = .clear
    public var iconStatus: UIImage?
    public var iconStatusColor: UIColor?
#endif
    public var splitedTitle: String = ""
    public var computedImageURL: String?
    public var metaData: FileMetaData?
    public var timeString: String = ""
    public var eventVM: AnyObject?
    public var addRemoveParticipant: String?
    public var fiftyFirstCharacter: NSAttributedString?
    public var participantName: String?
    public var hasSpaceToShowPin: Bool = false
    public var sentFileString: String?
    public var createConversationString: String?
    public var callMessage: Message?
    public var isInForwardMode: Bool = false
    
    public init(
        admin: Bool? = nil,
        canEditInfo: Bool? = nil,
        canSpam: Bool? = nil,
        closed: Bool? = nil,
        description: String? = nil,
        group: Bool? = nil,
        id: Int? = nil,
        image: String? = nil,
        joinDate: Int? = nil,
        lastMessage: String? = nil,
        lastParticipantImage: String? = nil,
        lastParticipantName: String? = nil,
        lastSeenMessageId: Int? = nil,
        lastSeenMessageNanos: UInt? = nil,
        lastSeenMessageTime: UInt? = nil,
        mentioned: Bool? = nil,
        metadata: String? = nil,
        mute: Bool? = nil,
        participantCount: Int? = nil,
        partner: Int? = nil,
        partnerLastDeliveredMessageId: Int? = nil,
        partnerLastDeliveredMessageNanos: UInt? = nil,
        partnerLastDeliveredMessageTime: UInt? = nil,
        partnerLastSeenMessageId: Int? = nil,
        partnerLastSeenMessageNanos: UInt? = nil,
        partnerLastSeenMessageTime: UInt? = nil,
        pin: Bool? = nil,
        time: UInt? = nil,
        title: String? = nil,
        type: ThreadTypes? = nil,
        unreadCount: Int? = nil,
        uniqueName: String? = nil,
        userGroupHash: String? = nil,
        inviter: Participant? = nil,
        lastMessageVO: LastMessageVO? = nil,
        participants: [Participant]? = nil,
        pinMessage: PinMessage? = nil,
        reactionStatus: ReactionStatus? = nil,
        isArchive: Bool? = nil
    ) {
        self.admin = admin
        self.canEditInfo = canEditInfo
        self.canSpam = canSpam ?? false
        self.closed = closed ?? false
        self.description = description
        self.group = group
        self.id = id
        self.image = image
        self.joinDate = joinDate
        self.lastMessage = lastMessage
        self.lastParticipantImage = lastParticipantImage
        self.lastParticipantName = lastParticipantName
        self.lastSeenMessageId = lastSeenMessageId
        self.lastSeenMessageNanos = lastSeenMessageNanos
        self.lastSeenMessageTime = lastSeenMessageTime
        self.mentioned = mentioned
        self.metadata = metadata
        self.mute = mute
        self.participantCount = participantCount
        self.partner = partner
        self.partnerLastDeliveredMessageId = partnerLastDeliveredMessageId
        self.partnerLastDeliveredMessageNanos = partnerLastDeliveredMessageNanos
        self.partnerLastDeliveredMessageTime = partnerLastDeliveredMessageTime
        self.partnerLastSeenMessageId = partnerLastSeenMessageId
        self.partnerLastSeenMessageNanos = partnerLastSeenMessageNanos
        self.partnerLastSeenMessageTime = partnerLastSeenMessageTime
        self.pin = pin
        self.time = time
        self.title = title
        self.type = type
        self.unreadCount = unreadCount
        self.uniqueName = uniqueName
        self.userGroupHash = userGroupHash
        self.inviter = inviter
        self.lastMessageVO = lastMessageVO
        self.participants = participants
        self.pinMessage = pinMessage
        self.reactionStatus = reactionStatus
        self.isArchive = isArchive
    }
}
