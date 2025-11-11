//
//  Array+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 11/11/25.
//

import Foundation

public extension Array where Element: Identifiable {
    
    mutating func removeDuplicates() {
        var seen: [Int: Int] = [:]
        var duplicateIndex: [Int] = []
        for (index, element) in enumerated() {
            if let id = element.id as? Int, seen[id] == nil {
                seen[id] = id
            } else {
                duplicateIndex.append(index)
            }
        }
        
        for index in duplicateIndex {
            remove(at: index)
        }
        return
    }
}
