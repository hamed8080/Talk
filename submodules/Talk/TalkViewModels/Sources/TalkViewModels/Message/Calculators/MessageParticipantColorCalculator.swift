//
//  MessageParticipantColorCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageParticipantColorCalculator {
    private let message: HistoryMessageType
    private let participantsColorVM: ParticipantsColorViewModel?
    
    public init(message: HistoryMessageType, participantsColorVM: ParticipantsColorViewModel?) {
        self.message = message
        self.participantsColorVM = participantsColorVM
    }
    
    func color() async -> UIColor {
        let color = await participantsColorVM?.color(for: message.participant?.id ?? -1)
        return color ?? .clear
    }
}
