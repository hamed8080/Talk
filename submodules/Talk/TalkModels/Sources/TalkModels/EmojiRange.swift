//
//  EmojiRange.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 1/14/26.
//

import Foundation

public struct EmojiRange {
    var value: ClosedRange<Int>
    
    public init(value: ClosedRange<Int>) {
        self.value = value
    }
    
    public func emojies() -> [String] {
        var arr: [String] = []
        for intValue in value.lowerBound...value.upperBound {
            if let scalar = UnicodeScalar(intValue) {
                arr.append(String(scalar))
            }
        }
        return arr
    }
    
    public static var allCases: [EmojisSection] {
        var arr: [EmojisSection] = []
        arr.append(.init(title: "emotiIcons", items: EmojiRange(value: 0x1F600...0x1F64F).emojies()))  // Emoticons
        arr.append(.init(title: "misc", items: EmojiRange(value: 0x1F300...0x1F5FF).emojies())) // Misc Symbols and Pictographs
        arr.append(.init(title: "transport", items: EmojiRange(value: 0x1F680...0x1F6FF).emojies())) // Transport and Map
        arr.append(.init(title: "geometric", items: EmojiRange(value: 0x1F780...0x1F7FF).emojies())) // Geometric Shapes Extended
        arr.append(.init(title: "arrows", items: EmojiRange(value: 0x2190...0x21FF).emojies())) // Supplemental Arrows-C
        arr.append(.init(title: "pictograph", items: EmojiRange(value: 0x1F900...0x1F9FF).emojies())) // Supplemental Symbols and Pictographs
        arr.append(.init(title: "chess", items: EmojiRange(value: 0x1FA00...0x1FA6F).emojies())) // Chess Symbols
        arr.append(.init(title: "flags", items: EmojiRange(value: 0x1F1E6...0x1F1FF).emojies())) // Flags
        
        return arr
    }
}

public struct EmojisSection: Hashable, Sendable {
    public var title: String
    public var items: [String]
    
    public init(title: String, items: [String]) {
        self.title = title
        self.items = items
    }
}
