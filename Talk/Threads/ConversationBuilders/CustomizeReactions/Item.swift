//
//  Item.swift
//  Talk
//
//  Created by hamed on 7/31/24.
//

import Foundation
import ChatModels

public struct Item: Hashable, Equatable {
    let sticker: Sticker
    var selected: Bool

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sticker.rawValue == rhs.sticker.rawValue && lhs.selected == rhs.selected
    }
}
