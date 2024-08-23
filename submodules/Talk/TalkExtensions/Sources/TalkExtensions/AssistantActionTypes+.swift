//
//  AssistantActionTypes+.swift
//  TalkExtensions
//
//  Created by hamed on 11/26/22.
//

import Foundation
import SwiftUI
import Chat

public extension AssistantActionTypes {
    var imageIconName: String? {
        switch self {
        case .register:
            return "rectangle.and.pencil.and.ellipsis"
        case .activate:
            return "play"
        case .deactivate:
            return "trash"
        case .block:
            return "hand.raised.slash"
        case .unblock:
            return "lock.open"
        case .unknown:
            return nil
        }
    }

    var actionColor: Color? {
        switch self {
        case .register:
            return .green
        case .activate:
            return .blue
        case .deactivate:
            return .yellow
        case .block:
            return .red
        case .unblock:
            return .mint
        case .unknown:
            return nil
        }
    }

    var stringValue: String? {
        switch self {
        case .register:
            return "Assistant.registered"
        case .activate:
            return "Assistant.activated"
        case .deactivate:
            return "Assistant.deactivated"
        case .block:
            return "Assistant.blocked"
        case .unblock:
            return "Assistant.unblocked"
        case .unknown:
            return nil
        }
    }
}
