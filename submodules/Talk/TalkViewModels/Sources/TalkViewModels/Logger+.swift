//
//  Logger.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 6/7/25.
//

import Logger
import Spec
import Foundation

public extension Logger {
    fileprivate static let config: LoggerConfig = {
        let config = LoggerConfig(
            spec: Spec.empty,
            prefix: "TALK_VIEW_MODELS",
            isDebuggingLogEnabled: true)
        return config
    }()
    
    fileprivate static let shared = Logger(config: config)
    
    fileprivate static let isDebugBuild: Bool = {
#if DEBUG
        return true
#else
        return false
#endif
    }()
    
    fileprivate static let isDebuggingEnabled: Bool = {
        isDebugBuild || (Bundle.main.bundleIdentifier?.contains("talk-test") ?? false)
    }()
    
    internal static func log(title: String = "", message: String = "", persist: Bool = true, userInfo: [String: String]? = nil) {
        guard isDebuggingEnabled else { return }
        Logger.shared.log(title: title, message: message, persist: persist, type: .internalLog, userInfo: userInfo)
    }
}
