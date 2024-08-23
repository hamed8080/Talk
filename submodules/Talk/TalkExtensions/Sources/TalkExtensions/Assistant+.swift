//
//  Assistant+.swift
//  TalkExtensions
//
//  Created by hamed on 11/26/22.
//

import Foundation
import Chat

public extension Assistant {
    mutating func update(_ newAssistant: Assistant) {
        id = newAssistant.id
        contactType = newAssistant.contactType
        assistant = newAssistant.assistant
        participant = newAssistant.participant
        roles = newAssistant.roles
        block = newAssistant.block
    }
}
