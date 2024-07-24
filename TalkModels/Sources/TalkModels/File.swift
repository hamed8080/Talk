//
//  File.swift
//  
//
//  Created by hamed on 7/24/24.
//

import Foundation

public extension Bundle {
    static func getBundle() -> Bundle {
        let bundleURL = Bundle.main.url(forResource: "MyBundle", withExtension: "bundle")
        if let bundleURL = bundleURL, let myBundle = Bundle(url: bundleURL) {
            return myBundle
        }
        return .main
    }
}
