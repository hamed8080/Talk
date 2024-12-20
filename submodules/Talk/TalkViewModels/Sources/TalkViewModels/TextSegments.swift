//
//  File.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 12/20/24.
//

import Foundation
import TalkModels

public class TextSegments {
    let message: any HistoryMessageProtocol
    
    public init(message: any HistoryMessageProtocol) {
        self.message = message
    }
    
    func splitCodeTexts() -> [TextOrCode] {
        let text = message.message?.replacingOccurrences(of: "```", with: "\n```\n") ?? ""
        let matches = tripleTicksMatches(text: text)
        guard !matches.isEmpty else { return [] }
        
        var startIndex = text.startIndex
        var parts: [TextOrCode] = []
        
        for match in matches {
            let range = match.range
            
            // Convert the match's NSRange to a Swift Range
            guard let matchRange = Range(range, in: text) else { continue }
            
            // Handle non-code text before the match
            if startIndex < matchRange.lowerBound {
                let noneCodeText = String(text[startIndex..<matchRange.lowerBound])
                let sanitizedText = noneCodeText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sanitizedText.isEmpty {
                    parts.append(.init(isCode: false, text: sanitizedText))
                }
            }
            
            // Handle code text between the triple ticks
            let codeText = String(text[matchRange])
            let cleanCodeText = codeText.replacingOccurrences(of: "```\n", with: "").replacingOccurrences(of: "\n```", with: "")
            parts.append(.init(isCode: true, text: cleanCodeText))
            
            // Update startIndex to the end of the current match
            startIndex = matchRange.upperBound
        }
        
        // Handle the remaining non-code text after the last match
        if startIndex < text.endIndex {
            let remainingText = String(text[startIndex..<text.endIndex])
            let sanitizedText = remainingText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !sanitizedText.isEmpty {
                parts.append(.init(isCode: false, text: sanitizedText))
            }
        }
        
        return parts
    }
    
    func tripleTicksMatches(text: String) -> [NSTextCheckingResult] {
        let pattern = "```\n(.*?)\n```"
        let allRange = NSRange(location: 0, length: text.utf16.count)
        guard
            let regex = try? NSRegularExpression(pattern: pattern)
        else { return [] }
        return regex.matches(in: text, range: allRange)
    }
}

public struct TextOrCode: Sendable {
    public let isCode: Bool
    public let text: String
}
