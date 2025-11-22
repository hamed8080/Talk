//
//  NSMutableAttributedString+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import UIKit
import TalkFont

public extension NSMutableAttributedString {
    private static let userMentionFont = UIFont.bold(.body)
    private static let boldFont = UIFont.bold(.body)
    private static let bodyFont = UIFont.normal(.body)

    func addDefaultTextColor(_ color: UIColor) {
        let allRange = NSRange(string.startIndex..., in: string)
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        style.lineSpacing = 12
        style.paragraphSpacing = 1
        style.lineBreakMode = .byWordWrapping
        let attributes = defalutTextAttributes(style: style, color: color)
        addAttributes(attributes, range: allRange)
    }

    func addLinkColor(_ color: UIColor = .blue) {
        if let linkRegex = NSRegularExpression.urlRegEx {
            let allRange = NSRange(string.startIndex..., in: string)
            linkRegex.enumerateMatches(in: string, range: allRange) { (result, flag, _) in
                if let range = result?.range, let urlRange = Range(range, in: string) {
                    let urlString = string[urlRange]
                    let sanitizedURL = String(urlString).trimmingCharacters(in: .whitespacesAndNewlines)
                    let encodedValue = sanitizedURL.data(using: .utf8)?.base64EncodedString()
                    if let link = NSURL(string: "openURL:url?encodedValue=\(encodedValue ?? "")") {
                        let attributedList = linkColorAttributes(color: color, link: link)
                        addAttributes(attributedList, range: range)
                    }
                }
            }
        }
    }

    func addUserColor(_ color: UIColor = .blue) {
        if let userRegex = NSRegularExpression.userRegEx {
            let allRange = NSRange(string.startIndex..., in: string)
            userRegex.enumerateMatches(in: string, range: allRange) { (result, flag, _) in
                if let range = result?.range, let userNameRange = Range(range, in: string) {
                    let userName = string[userNameRange]
                    let sanitizedUserName = String(userName).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
                    if let link = NSURL(string: "showUser:User?userName=\(sanitizedUserName)") {
                        addAttributes(userColorAttributes(link: link, color: color), range: range)
                    }
                }
            }
        }
    }

    private func defalutTextAttributes(style: NSMutableParagraphStyle, color: UIColor) -> [NSAttributedString.Key: Any] {
        [NSAttributedString.Key.paragraphStyle: style,
        NSAttributedString.Key.foregroundColor : color,
        NSAttributedString.Key.font: NSMutableAttributedString.bodyFont ?? .systemFont(ofSize: 14)]
    }

    private func userColorAttributes(link: NSURL, color: UIColor) -> [NSAttributedString.Key: Any] {
        [NSAttributedString.Key.link: link,
         NSAttributedString.Key.foregroundColor: color,
         NSAttributedString.Key.font: NSMutableAttributedString.boldFont ?? .systemFont(ofSize: 14, weight: .bold)]
    }

    private func linkColorAttributes(color: UIColor, link: NSURL) -> [NSAttributedString.Key: Any] {
        [NSAttributedString.Key.foregroundColor: color,
         NSAttributedString.Key.underlineColor: color,
         NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
         NSAttributedString.Key.link: link]
    }
    
    public func addBold() {
        let pattern = "\\*\\*(.*?)\\*\\*"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        for match in matches.reversed() {
            let range = match.range
            addAttributes([.font: NSMutableAttributedString.boldFont], range: range)
            
            // Remove the surrounding `**` by replacing them with an empty string
            let fullRange = match.range
            replaceCharacters(in: NSRange(location: fullRange.location + fullRange.length - 2, length: 2), with: "")
            replaceCharacters(in: NSRange(location: fullRange.location, length: 2), with: "")
        }
    }
    
    public func addItalic() {
        let pattern = "\\_\\_(.*?)\\_\\_"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        for match in matches.reversed() {
            let range = match.range
            addAttributes([.font: UIFont.italicSystemFont(ofSize: 16)], range: range)
            
            // Remove the surrounding `**` by replacing them with an empty string
            let fullRange = match.range
            replaceCharacters(in: NSRange(location: fullRange.location + fullRange.length - 2, length: 2), with: "")
            replaceCharacters(in: NSRange(location: fullRange.location, length: 2), with: "")
        }
    }
    
    public func addStrikethrough() {
        let pattern = "\\~\\~(.*?)\\~\\~"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        for match in matches.reversed() {
            let range = match.range
            addAttributes([.strikethroughStyle: NSUnderlineStyle.single.rawValue], range: range)
            
            // Remove the surrounding `**` by replacing them with an empty string
            let fullRange = match.range
            replaceCharacters(in: NSRange(location: fullRange.location + fullRange.length - 2, length: 2), with: "")
            replaceCharacters(in: NSRange(location: fullRange.location, length: 2), with: "")
        }
    }
}
