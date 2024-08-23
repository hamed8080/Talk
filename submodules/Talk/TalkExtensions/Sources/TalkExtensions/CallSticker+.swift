//
//  CallSticker+.swift
//  TalkExtensions
//
//  Created by hamed on 12/10/22.
//

import Foundation
import SwiftUI
import Chat

public extension CallSticker {
    var systemImage: SwiftUI.Image {
        switch self {
        case .raiseHand:
            return SwiftUI.Image(systemName: "hand.raised.fill")
        case .like:
            return SwiftUI.Image(systemName: "hand.thumbsup.fill")
        case .dislike:
            return SwiftUI.Image(systemName: "hand.thumbsdown.fill")
        case .clap:
            return SwiftUI.Image(systemName: "hands.clap.fill")
        case .heart:
            return SwiftUI.Image(systemName: "heart.fill")
        case .happy:
            return SwiftUI.Image(systemName: "face.smiling.inverse")
        case .angry:
            return SwiftUI.Image("angry")
        case .cry:
            return SwiftUI.Image("crying")
        case .power:
            return SwiftUI.Image(systemName: "bolt.fill")
        case .bored:
            return SwiftUI.Image("bored")
        }
    }
}
