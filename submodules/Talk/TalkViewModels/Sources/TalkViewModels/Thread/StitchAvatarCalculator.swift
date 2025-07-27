//
//  StitchAvatarCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/18/25.
//

import Foundation
import ChatModels

@MainActor
public class StitchAvatarCalculator {
    public static func forTop(_ sections: ContiguousArray<MessageSection>, _ sortedVMS: [MessageRowViewModel]) -> MessageRowViewModel? {
        let sorted = sortedVMS.sorted(by: {$0.message.id ?? 0 < $1.message.id ?? 0 })
        guard
            let sectionFirstMessage = sections.first?.vms.first,
            let lastSortedMessage = sorted.last
        else { return nil }
        
        var shouldUpdateTopInSection = false
        if sectionFirstMessage.message.ownerId == lastSortedMessage.message.ownerId, sectionFirstMessage.message.reactionableType {
            sectionFirstMessage.calMessage.isFirstMessageOfTheUser = false
            lastSortedMessage.calMessage.isLastMessageOfTheUser = false
            shouldUpdateTopInSection = true
        }
        
        return shouldUpdateTopInSection ? sectionFirstMessage : nil
    }
    
    public static func forBottom(_ sections: ContiguousArray<MessageSection>, _ sortedVMS: [MessageRowViewModel]) -> MessageRowViewModel? {
        let sorted = sortedVMS.sorted(by: {$0.message.id ?? 0 < $1.message.id ?? 0 })
        guard
            let sectionLastMessage = sections.last?.vms.last,
            let firstSortedMessage = sorted.first
        else { return nil }
        
        var shouldUpdateBottomInSection = false
        if sectionLastMessage.message.ownerId == firstSortedMessage.message.ownerId, sectionLastMessage.message.reactionableType {
            sectionLastMessage.calMessage.isLastMessageOfTheUser = false
            firstSortedMessage.calMessage.isFirstMessageOfTheUser = false
            shouldUpdateBottomInSection = true
        }
        
        return shouldUpdateBottomInSection ? sectionLastMessage : nil
    }
    
    public static func forNew(_ sections: ContiguousArray<MessageSection>, _ newMessage: Message, _ bottomVMBeforeJoin: MessageRowViewModel?) -> IndexPath? {
        guard
            newMessage.reactionableType,
            let bottomVMBeforeJoin = bottomVMBeforeJoin,
            bottomVMBeforeJoin.message.ownerId == newMessage.ownerId,
            let indexPath = sections.indexPath(for: bottomVMBeforeJoin)
        else { return nil }
        return indexPath
    }
}

