//
//  MessageIsInTwoWeeksCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageIsInTwoWeeksCalculator {
    private let message: HistoryMessageType
    
    public init(message: HistoryMessageType) {
        self.message = message
    }
    
    func isInTwoWeekPeriod() -> Bool {
        let twoWeeksInMilliSeconds: UInt = 1_209_600_000
        let now = UInt(Date().millisecondsSince1970)
        let twoWeeksAfter = UInt(message.time ?? 0) + twoWeeksInMilliSeconds
        if twoWeeksAfter > now {
            return true
        }
        return false
    }
}
