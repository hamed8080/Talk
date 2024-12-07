//
//  ParticipantsColorViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import UIKit
import SwiftUI

@HistoryActor
public final class ParticipantsColorViewModel: @unchecked Sendable {
    var participantsColor: [Int: UIColor] = [:]
    private var reservedColors: [Int] = []
    nonisolated public init() { }

    func random() -> UIColor {
        let number = Int.random(in: 1...7)
        let emptySlots = (1...7).filter { number in
            return !reservedColors.contains(where: { $0 == number })
        }
        let newNumber = emptySlots.randomElement()
        reservedColors.append(newNumber ?? number)
        return UIColor(named: "userColor\(newNumber ?? number)") ?? .random()
    }
    
    public func color(for participantId: Int) -> UIColor {
        if let color = participantsColor[participantId] {
            return color
        } else {
            let color = random()
            participantsColor[participantId] = color
            return color
        }
    }
}
