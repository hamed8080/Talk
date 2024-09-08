//
//  String+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 11/10/21.
//

import UniformTypeIdentifiers
import UIKit
import SwiftUI
import NaturalLanguage
import TalkModels
import Chat

public extension String {

    func getSystemTypeString(type: SMT) -> String? {
        switch type {
        case .isTyping:
            return "typing"
        case .recordVoice:
            return "recording audio"
        case .uploadPicture:
            return "uploading image"
        case .uploadVideo:
            return "uploading video"
        case .uploadSound:
            return "uploading sound"
        case .uploadFile:
            return "uploading file"
        case .serverTime:
            return nil
        case .unknown:
            return "UNknown"
        }
    }

    func remove(in range: NSRange) -> String? {
        guard let range = Range(range, in: self) else { return nil }
        return replacingCharacters(in: range, with: "")
    }

    func matches(char: Character) -> [NSTextCheckingResult]? {
        let range = NSRange(startIndex..., in: self)
        return try? NSRegularExpression(pattern: "\(char)[0-9a-zA-Z\\-\\p{Arabic}](\\.?[0-9a-zA-Z\\--\\p{Arabic}])*").matches(in: self, range: range)
    }

    var systemImageNameForFileExtension: String {
        switch self {
        case ".mp4", ".avi", ".mkv":
            return "play.rectangle.fill"
        case ".mp3", ".m4a":
            return "play.circle.fill"
        case ".docx", ".pdf", ".xlsx", ".txt", ".ppt":
            return "doc.circle.fill"
        case ".zip", ".rar", ".7z":
            return "doc.zipper"
        default:
            return "doc.circle.fill"
        }
    }

    var nonCircleIconWithFileExtension: String {
        switch self {
        case "mp4", "avi", "mkv":
            return "film.fill"
        case "mp3", "m4a":
            return "music.note"
        case "docx", "pdf", "xlsx", "txt", "ppt":
            return "doc.text.fill"
        case "zip", "rar", "7z":
            return "doc.zipper"
        default:
            return "doc.fill"
        }
    }

    /// Convert mimeType to extension such as `audio/mpeg` to `mp3`.
    var ext: String? { UTType(mimeType: self)?.preferredFilenameExtension }

    var dominantLanguage: String? {
        return NLLanguageRecognizer.dominantLanguage(for: self)?.rawValue
    }

    var naturalTextAlignment: TextAlignment {
        guard let dominantLanguage = dominantLanguage else {
            return .leading
        }
        switch NSParagraphStyle.defaultWritingDirection(forLanguage: dominantLanguage) {
        case .leftToRight:
            return .leading
        case .rightToLeft:
            return .trailing
        case .natural:
            return .leading
        @unknown default:
            return .leading
        }
    }

    var isEmptyOrWhiteSpace: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    static func splitedCharacter(_ string: String) -> String {
        let splited = string.split(separator: " ")
        if let first = splited.first?.first {
            var second: String = ""
            if splited.indices.contains(1), let last = splited[1].first {
                second = String(last)
            }
            let first = String(first)
            return "\(first) \(second)"
        } else {
            return ""
        }
    }

    static func getMaterialColorByCharCode(str: String) -> UIColor {
        let splited = String.splitedCharacter(str).split(separator: " ")
        let defaultColor = UIColor(red: 50/255, green: 128/255, blue: 192/255, alpha: 1.0)
        guard let code = splited.first?.unicodeScalars.first?.value else { return defaultColor }
        var firstInt = Int(code)
        if let lastCode = splited.last?.unicodeScalars.first?.value {
            let lastInt = Int(lastCode)
            firstInt -= firstInt - lastInt
        }
        if (0..<20).contains(firstInt) { return UIColor(red: 50/255, green: 128/255, blue: 192/255, alpha: 1.0) }
        if (20..<39).contains(firstInt) { return UIColor(red: 60/255, green: 156/255, blue: 33/255, alpha: 1.0) }
        if (40..<59).contains(firstInt) { return UIColor(red: 195/255, green: 112/255, blue: 36/255, alpha: 1.0) }
        if (60..<79).contains(firstInt) { return UIColor(red: 185/255, green: 76/255, blue: 71/255, alpha: 1.0) }
        if (80..<99).contains(firstInt) { return UIColor(red: 137/255, green: 87/255, blue: 202/255, alpha: 1.0) }
        if (100..<119).contains(firstInt) { return UIColor(red: 54/255, green: 164/255, blue: 177/255, alpha: 1.0) }
        if (120..<199).contains(firstInt) { return UIColor(red: 183/255, green: 76/255, blue: 130/255, alpha: 1.0) }
        if (1500..<1549).contains(firstInt) { return UIColor(red: 50/255, green: 128/255, blue: 192/255, alpha: 1.0) }
        if (1550..<1599).contains(firstInt) { return UIColor(red: 60/255, green: 156/255, blue: 33/255, alpha: 1.0) }
        if (1600..<1619).contains(firstInt) { return UIColor(red: 195/255, green: 112/255, blue: 36/255, alpha: 1.0) }
        if (1620..<1679).contains(firstInt) { return UIColor(red: 185/255, green: 76/255, blue: 71/255, alpha: 1.0) }
        if (1680..<1699).contains(firstInt) { return UIColor(red: 137/255, green: 87/255, blue: 202/255, alpha: 1.0) }
        if (1700...1749).contains(firstInt) { return UIColor(red: 54/255, green: 164/255, blue: 177/255, alpha: 1.0) }
        if (1750..<1799).contains(firstInt) { return UIColor(red: 183/255, green: 76/255, blue: 130/255, alpha: 1.0) }
        return defaultColor
    }
}

public extension Optional where Wrapped == String {
    var validateString: String? {
        if let self = self {
            if self.isEmptyOrWhiteSpace {
                return nil
            } else {
                return self
            }
        } else {
            return nil
        }
    }
}

public extension String {
    func bundleLocalized() -> String {
        return NSLocalizedString(self, bundle: Language.preferedBundle, comment: "")
    }
}


public extension String {
    func links() -> [String] {
        var links: [String] = []
        if let linkRegex = NSRegularExpression.urlRegEx {
            let allRange = NSRange(startIndex..., in: self)
            linkRegex.enumerateMatches(in: self, range: allRange) { (result, flag, _) in
                if let range = result?.range, let linkRange = Range(range, in: self) {
                    let link = self[linkRange]
                    links.append(String(link))
                }
            }
        }
        return links
    }
}
