//
//  MessageAttributedStringCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import TalkModels
import UIKit

public final class MessageAttributedStringCalculator {
    private let message: HistoryMessageType
    
    public init (message: HistoryMessageType) {
        self.message = message
    }
    
    public func attributedString() -> NSAttributedString? {
        let mapUploadText = (message as? UploadFileMessage)?.locationRequest?.textMessage
        let stringMessage = message.message ?? mapUploadText ?? ""
        
        // Step 1: Convert all encoded text from the web version to normal signs.
        let decodedText = stringMessage.convertedHTMLEncoding
        
        // Step 2: Add code blocks signs if there is any.
        let text = formatCodeBlocks(string: decodedText)
        
        guard let mutableAttr = try? NSMutableAttributedString(string: text) else { return NSAttributedString() }
        let range = (text.startIndex..<text.endIndex)
        
        mutableAttr.addDefaultTextColor(UIColor(named: "text_primary") ?? .white)
        mutableAttr.addUserColor(UIColor(named: "accent") ?? .orange)
        mutableAttr.addLinkColor(UIColor(named: "text_secondary") ?? .gray)
        mutableAttr.addBold()
        mutableAttr.addItalic()
        mutableAttr.addStrikethrough()
        
        let tripleCal = MessageTripleGraveAccentCalculator(message: message, pattern: "(?s)```\n(.*?)\n```")
        /// Add Space around all code text start with triple ``` and end with ```
        tripleCal.calculateRange(string: mutableAttr.string).forEach { result in
            // Define paragraph style with leading padding
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 8 // Adds padding to all lines of the paragraph
            paragraphStyle.firstLineHeadIndent = 8 // Adds padding to the first line
            
            mutableAttr.addAttribute(.paragraphStyle, value: paragraphStyle, range: result.range)
        }
        
        /// Hide triple ``` by making them clear
        /// We have to use ``mutableAttr.string`` instead of the ``text argument``,
        /// because there is a chance the text contains both bold and triple grave accent in this case it will crash because bold will remove four **** sign therefore the index with ``text`` is bigger than mutableAttr.string.
        let hideTripleCal = MessageTripleGraveAccentCalculator(message: message, pattern: "```")
        hideTripleCal.calculateRange(string: mutableAttr.string).forEach { result in
            mutableAttr.addAttribute(.foregroundColor, value: UIColor.clear, range: result.range)
            mutableAttr.addAttribute(.font, value: UIFont.name(name: "Menlo", .body), range: result.range)
        }
        
        return NSAttributedString(attributedString: mutableAttr)
    }
    
    private func formatCodeBlocks(string: String) -> String {
        let pattern = "```\\n?(.*?)\\n?```" // Match ``` and capture content between them
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) // Allows multiline match
        
        let formattedText = regex.stringByReplacingMatches(
            in: string,
            options: [],
            range: NSRange(string.startIndex..., in: string),
            withTemplate: "\n```\n$1\n```\n" // Ensure newline before and add two spaces inside
        )
        return formattedText
    }
}
