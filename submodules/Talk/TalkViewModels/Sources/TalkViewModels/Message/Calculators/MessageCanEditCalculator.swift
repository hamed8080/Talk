//
//  MessageCanEditCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/12/26.
//

import Foundation
import Chat
import TalkModels

public class MessageCanEditCalculator {
    private let message: HistoryMessageType
    private let conversation: Conversation?
    private let isMine: Bool
    
    public init(message: HistoryMessageType, conversation: Conversation?, isMine: Bool) {
        self.message = message
        self.conversation = conversation
        self.isMine = isMine
    }
    
    func canEdit() -> Bool {
        var canEdit = false
        
        let isChannelType = conversation?.type?.isChannelType == true
        let isEditableOrNil = (message.editable == true || message.editable == nil)
        canEdit = ( isEditableOrNil && isMine) || (isEditableOrNil && conversation?.admin == true && isChannelType && isMine)
        
        if message.forwardInfo != nil {
            canEdit = false
        }
        
        return canEdit
    }
}
