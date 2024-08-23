//
//  CGFloat+.swift
//
//
//  Created by hamed on 1/2/24.
//

import Foundation

public extension CGFloat {
    var degree: CGFloat {
        self * (180 / .pi)
    }
}
