//
//  AppError.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

/// App Errors Start with negative 100 values.
public enum AppErrorTypes: Int {
    case microphone_access_denied = -100
    case location_access_denied = -101

    public var localized: String {
        switch self {
        case .microphone_access_denied:
            return String(localized: .init("Thread.accessMicrophonePermission"), bundle: Language.preferedBundle)
        case .location_access_denied:
            return String(localized: .init("Thread.accessLocaitonPermission"), bundle: Language.preferedBundle)
        }
    }
}

public enum AppErrors: Error, Equatable {
    case revokedToken
}
