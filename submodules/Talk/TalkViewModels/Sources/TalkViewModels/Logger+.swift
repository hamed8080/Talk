//
//  Logger+.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import OSLog

extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier!
    static let viewModels = Logger(subsystem: subsystem, category: "viewModels")
}
