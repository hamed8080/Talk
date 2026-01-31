//
//  MainRequirements.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import Chat

public struct MainRequirements: Sendable {
    let appUserId: Int?
    let thread: Conversation?
    let participantsColorVM: ParticipantsColorViewModel?
    let isInSelectMode: Bool
    let joinLink: String
    
    public init(appUserId: Int?, thread: Conversation?, participantsColorVM: ParticipantsColorViewModel?, isInSelectMode: Bool, joinLink: String) {
        self.appUserId = appUserId
        self.thread = thread
        self.participantsColorVM = participantsColorVM
        self.isInSelectMode = isInSelectMode
        self.joinLink = joinLink
    }
}
