//
//  MessageGroupParticipantNameCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit
import Chat
import TalkModels

public final class MessageGroupParticipantNameCalculator {
    private let message: HistoryMessageType
    private let isMine: Bool
    private let isFirstMessageOfTheUser: Bool
    private let conversation: Conversation?
    
    public init(message: HistoryMessageType, isMine: Bool, isFirstMessageOfTheUser: Bool, conversation: Conversation?) {
        self.message = message
        self.isMine = isMine
        self.isFirstMessageOfTheUser = isFirstMessageOfTheUser
        self.conversation = conversation
    }
    
    func participantName() -> String? {
        let canShowGroupName = !isMine && conversation?.group == true && conversation?.type?.isChannelType == false
        && isFirstMessageOfTheUser
        if canShowGroupName {
            return message.participant?.contactName ?? message.participant?.name
        }
        return nil
    }
}
