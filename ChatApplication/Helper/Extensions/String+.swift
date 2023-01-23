//
//  String+.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/10/21.
//

import FanapPodChatSDK
import Foundation
import NaturalLanguage
import UIKit

extension String {
    func isTypingAnimationWithText(onStart: @escaping (String) -> Void, onChangeText: @escaping (String, Timer) -> Void, onEnd: @escaping () -> Void) {
        onStart(self)
        var count = 0
        var indicatorCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if count >= 100 {
                onEnd()
                timer.invalidate()
            } else {
                if indicatorCount == 3 {
                    indicatorCount = 0
                } else {
                    indicatorCount += 1
                }
                onChangeText("typing" + String(repeating: "•", count: indicatorCount), timer)
                count += 1
            }
        }
    }

    func signalMessage(signal: SMT, onStart: @escaping (String) -> Void, onChangeText: @escaping (String, Timer) -> Void, onEnd: @escaping () -> Void) {
        onStart(self)
        var count = 0
        var indicatorCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if count >= 15 {
                onEnd()
                timer.invalidate()
            } else {
                if indicatorCount == 3 {
                    indicatorCount = 0
                } else {
                    indicatorCount += 1
                }
                if let typeString = getSystemTypeString(type: signal) {
                    onChangeText(typeString + String(repeating: "•", count: indicatorCount), timer)
                }
                count += 1
            }
        }
    }

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

    var isEnglishString: Bool {
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(self)
        guard let code = languageRecognizer.dominantLanguage?.rawValue else { return true }
        return Locale.current.localizedString(forIdentifier: code) == "English"
    }

    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return NSString(string: self).size(withAttributes: fontAttributes).width
    }

    func remove(in range: NSRange) -> String? {
        guard let range = Range(range, in: self) else { return nil }
        return replacingCharacters(in: range, with: "")
    }

    func matches(char: Character) -> [NSTextCheckingResult]? {
        let range = NSRange(startIndex..., in: self)
        return try? NSRegularExpression(pattern: "\(char)[0-9a-zA-Z\\-](\\.?[0-9a-zA-Z\\-])*").matches(in: self, range: range)
    }

    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }
}
