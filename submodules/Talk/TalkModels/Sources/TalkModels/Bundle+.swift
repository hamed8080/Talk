//
//  Bundle+.swift
//
//
//  Created by hamed on 7/24/24.
//

import Foundation

public extension Bundle {
    static let manager = BundleManager()
    static let appBundle = manager.getBundle()
}
