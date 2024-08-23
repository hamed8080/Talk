//
//  LogEmitter+.swift
//  TalkExtensions
//
//  Created by hamed on 3/29/23.
//

import Logger

public extension LogEmitter {
    var title: String {
        switch self {
        case .internalLog:
            return "Log.internalLog"
        case .sent:
            return "Log.sent"
        case .received:
            return "Log.received"
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
}
