//
//  Logger+.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 6/7/25.
//

import Logger
import Spec
import Foundation

extension Logger {
    fileprivate static let config: LoggerConfig = {
        let config = LoggerConfig(
            spec: Spec.empty,
            prefix: "TALK_APP",
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
    
    private static let logOnDisk: Bool = {
        return (Bundle.main.object(forInfoDictionaryKey: "LOG_ON_DISK") as? NSNumber)?.boolValue == true
    }()
    
    fileprivate static let isDebuggingEnabled: Bool = {
        isDebugBuild || (Bundle.main.bundleIdentifier?.contains("talk-test") ?? false)
    }()
    
    static func log(title: String = "", message: String = "", persist: Bool = true, userInfo: [String: String]? = nil) {
        guard isDebuggingEnabled else { return }
        var persist = persist
        if !logOnDisk {
            persist = false
        }
        Logger.shared.log(title: title, message: message, persist: persist, type: .internalLog, userInfo: userInfo)
    }
}
