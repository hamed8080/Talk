//
//  LogEmitter+.swift
//  ChatApplication
//
//  Created by hamed on 3/29/23.
//

import Logger
import SwiftUI

extension LogEmitter {
    var title: String {
        switch self {
        case .internalLog:
            return "Internal Logs"
        case .sent:
            return "Sent"
        case .received:
            return "Received"
        }
    }

    var icon: String {
        switch self {
        case .internalLog:
            return "shippingbox"
        case .sent:
            return "arrow.up.circle.fill"
        case .received:
            return "arrow.down.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .internalLog:
            return .yellow
        case .sent:
            return .green
        case .received:
            return .red
        }
    }
}
