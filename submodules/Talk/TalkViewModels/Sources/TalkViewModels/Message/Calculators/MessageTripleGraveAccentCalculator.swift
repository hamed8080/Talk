//
//  MessageTripleGraveAccentCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels

public final class MessageTripleGraveAccentCalculator {
    private let message: HistoryMessageType
    private let pattern: String
    
    public init (message: HistoryMessageType, pattern: String ) {
        self.message = message
        self.pattern = pattern
    }
    
    public func calculateRange(text: String) -> [Range<String.Index>]? {
        return calculateRange(string: text).compactMap({ Range($0.range, in: text) })
    }
    
    public func calculateRange(string: String) -> [NSTextCheckingResult] {
        let allRange = NSRange(location: 0, length: string.utf16.count)
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: string, range: allRange)
        return matches
    }
}
