//
//  MessageAddOrRemoveParticipantCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageAddOrRemoveParticipantCalculator {
    private let message: HistoryMessageType
    private let isMine: Bool
    private let myId: Int?
    
    public init(message: HistoryMessageType, isMine: Bool, myId: Int?) {
        self.message = message
        self.isMine = isMine
        self.myId = myId
    }

    public func attribute() -> NSAttributedString? {
        if ![.participantJoin, .participantLeft].contains(message.type) { return nil }
        let date = Date(milliseconds: Int64(message.time ?? 0)).onlyLocaleTime
        let string = "\(message.addOrRemoveParticipantString(meId: myId) ?? "") \(date)"
        let attr = NSMutableAttributedString(string: string)
        let isMeDoer = "General.you".bundleLocalized()
        let doer = isMine ? isMeDoer : (message.participant?.name ?? "")
        let doerRange = NSString(string: string).range(of: doer)
        let allRange = NSRange(string.startIndex..., in: string)
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: allRange)
        attr.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor(named: "accent") ?? .orange,
            NSAttributedString.Key.font: UIFont.normal(.body)
        ], range: doerRange)
        return attr
    }
}
