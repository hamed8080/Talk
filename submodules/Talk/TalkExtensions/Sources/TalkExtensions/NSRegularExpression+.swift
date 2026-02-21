//
//  NSRegularExpression+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation

public extension NSRegularExpression {
    static let urlRegEx = try? NSRegularExpression(pattern: "((https?:\\/\\/[^\\s]+)|([a-zA-Z0-9._-]+@[a-zA-Z0-9-]+\\.[a-zA-Z]{2,})|(https?:\\/\\/)?(www\\.)?([a-zA-Z0-9_-]+\\.)*[a-zA-Z0-9-_]{1,}\\.(ir|com|org|net|IR|COM|NET|ORG)(\\/?[a-zA-Z0-9-_\\/&=?;:+,#$^*&_!@.%]+)?)")
    static let userRegEx = try? NSRegularExpression(pattern: "@[0-9a-zA-Z\\-\\p{Arabic}](\\.?[0-9a-zA-Z\\--\\p{Arabic}])*")
    static let phoneRegEx = try? NSRegularExpression(pattern: #"(?<!\d)(?:\+98|\+۹۸|0|۰)[9۹][0-9۰-۹]{9}(?!\d)"#)
    static let emojiRegEx = "&#x([0-9a-fA-F]+);"

}
