//
//  MessagePaddingCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels

public final class MessageFirstOrLastCalculator {
    private let message: HistoryMessageType
    private let appended: [HistoryMessageType]
    private let isChannelType: Bool
    
    public init(message: HistoryMessageType, appended: [HistoryMessageType], isChannelType: Bool) {
        self.message = message
        self.appended = appended
        self.isChannelType = isChannelType
    }
    
    public func isLast() -> Bool {
        if isChannelType { return false }
        if !message.reactionableType { return false }
        let index = appended.firstIndex(where: {$0.id == message.id}) ?? -2
        let nextIndex = index + 1
        let isNextExist = appended.indices.contains(nextIndex)
        if appended.count > 0, isNextExist {
    
            /// If user send a message between two system messages,
            /// we have to mark this message as of the last message of the user.
            if !appended[nextIndex].reactionableType { return true }
    
            /// If they are the same participant, it means the next message is still having the same user.
            let isSameParticipant = appended[nextIndex].participant?.id == message.participant?.id
            return !isSameParticipant
        }
        return true
    }
    
    public func isFirst() -> Bool {
        if isChannelType == true { return false }
        if !message.reactionableType { return false }
        let index = appended.firstIndex(where: {$0.id == message.id}) ?? -2
        let prevIndex = index - 1
        let isPrevExist = appended.indices.contains(prevIndex)
        if appended.count > 0, isPrevExist {
            let isSameParticipant = appended[prevIndex].participant?.id == message.participant?.id
            return !isSameParticipant
        }
        return true
    }
}
