//
//  ChatResponse+.swift
//  TalkExtensions
//
//  Created by hamed on 12/4/22.
//

import ChatCore
import Additive
import Foundation
import TalkModels

extension ChatError {
    public static var presentableErrors: [ServerErrorType] = ServerErrorType.allCases.filter{ !customPresentable.contains($0) }
    public static var customPresentable: [ServerErrorType] = [.noOtherOwnership]
    public var localizedError: String? {
        guard let code = code, let chatCode = ServerErrorType(rawValue: code) else { return nil }
        switch chatCode {
        case .temporaryBan:
            guard
                let data = message?.data(using: .utf8),
                let banError = try? JSONDecoder.instance.decode(BanError.self, from: data)
            else { return nil }
            let localized = "General.ban".localized(bundle: Language.preferedBundle)
            let banTime = banError.duration ?? 0
            return String(format: localized, "\(banTime / 1000)")
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
