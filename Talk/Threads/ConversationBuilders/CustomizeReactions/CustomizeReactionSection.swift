//
//  CustomizeReactionSection.swift
//  Talk
//
//  Created by hamed on 7/31/24.
//

import Foundation

public struct CustomizeReactionSection: Hashable {
    let type: CustomizeSectionType
    var rows: [Item] = []

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.type.rawValue == rhs.type.rawValue
    }
}
