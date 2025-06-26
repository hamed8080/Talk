//
//  Logger+.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/7/25.
//

import Foundation
import Logger
import Spec

extension Logger {
    fileprivate static let config: LoggerConfig = {
        let config = LoggerConfig(
            spec: Spec.empty,
            prefix: "TALK",
            isDebuggingLogEnabled: true)
        return config
    }()
    
    static let logger = Logger(config: config)
}
