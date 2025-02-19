//
//  ChatResponse+.swift
//  TalkExtensions
//
//  Created by hamed on 12/4/22.
//

import Foundation
import TalkModels
import Chat

extension ChatError {
    nonisolated(unsafe) public static var presentableErrors: [ServerErrorType] = ServerErrorType.allCases.filter{ !customPresentable.contains($0) }
    nonisolated(unsafe) public static var customPresentable: [ServerErrorType] = [.noOtherOwnership, .temporaryBan]
    public var localizedError: String? {
        guard let code = code, let chatCode = ServerErrorType(rawValue: code) else { return nil }
        switch chatCode {
        case .haveAlreadyJoinedTheThread:
            return "Errors.hasAlreadyJoinedError"
        default:
            return nil
        }
    }

    public var isPresentable: Bool { ChatError.presentableErrors.contains(where: { $0.rawValue == code ?? 0}) }
}

public extension ChatResponse {
    var isPresentable: Bool { ChatError.presentableErrors.contains(where: { $0.rawValue == error?.code ?? 0}) }
}
