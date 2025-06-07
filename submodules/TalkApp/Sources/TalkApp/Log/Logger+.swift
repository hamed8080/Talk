//
//  Logger+.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 6/7/25.
//

import Logger
import Spec

extension Logger {
    fileprivate static let config: LoggerConfig = {
        let config = LoggerConfig(
            spec: Spec.empty,
            prefix: "TALK_APP",
            isDebuggingLogEnabled: true)
        return config
    }()
    
    fileprivate static let logger = Logger(config: config)
    
    static func log(title: String = "", message: String = "", persist: Bool = true, userInfo: [String: String]? = nil) {
#if DEBUG
        Logger.logger.log(title: title, message: message, persist: persist, type: .internalLog, userInfo: userInfo)
#endif
    }
}
