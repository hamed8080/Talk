//
//  Timer.swift
//  TalkExtensions
//
//  Created by hamed on 3/29/23.
//

import Foundation

public struct SendableTimer: @unchecked Sendable {
    public let timer: Timer
    
    public init(timer: Timer) {
        self.timer = timer
    }
}

public extension Timer {
    var sendable: SendableTimer { SendableTimer(timer: self) }
}
