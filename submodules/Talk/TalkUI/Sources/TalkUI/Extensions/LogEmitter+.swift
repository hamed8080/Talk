import Logger
import SwiftUI

public extension LogEmitter {
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
