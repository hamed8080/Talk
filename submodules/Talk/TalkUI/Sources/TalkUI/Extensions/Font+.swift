//
//  Font+.swift
//  TalkUI
//
//  Created by hamed on 3/15/23.
//

import SwiftUI
import TalkExtensions

fileprivate let fName = "SVJBTlNhbnNY".fromBase64() ?? ""
fileprivate let fBoldName = "SVJBTlNhbnNYLUJvbGQ=".fromBase64() ?? ""
fileprivate let fRegualrBoldName = "SVJBTlNhbnNYLVJlZ3VsYXI=".fromBase64() ?? ""

public extension UIFont {
    static func register() {
        registerFont(name: fBoldName)
        registerFont(name: fRegualrBoldName)
    }

    private static func registerFont(name: String) {
        guard let fontURL = Bundle.module.url(forResource: name, withExtension: "ttf") else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }
}

public extension Font {
    static let fLargeTitle = Font.custom(fName, size: 24)
    static let fTitle = Font.custom(fName, size: 20)
    static let fSubtitle = Font.custom(fName, size: 18)
    static let fSubheadline = Font.custom(fName, size: 16)
    static let fBody = Font.custom(fName, size: 14)
    static let fCaption = Font.custom(fName, size: 13)
    static let fCaption2 = Font.custom(fName, size: 12)
    static let fCaption3 = Font.custom(fName, size: 11)
    static let fFootnote = Font.custom(fName, size: 10)

    static let fBoldLargeTitle = Font.custom(fBoldName, size: 24)
    static let fBoldTitle = Font.custom(fBoldName, size: 20)
    static let fBoldSubtitle = Font.custom(fBoldName, size: 18)
    static let fBoldSubheadline = Font.custom(fBoldName, size: 16)
    static let fBoldBody = Font.custom(fBoldName, size: 14)
    static let fBoldCaption = Font.custom(fBoldName, size: 13)
    static let fBoldCaption2 = Font.custom(fBoldName, size: 12)
    static let fBoldCaption3 = Font.custom(fBoldName, size: 11)
    static let fBoldFootnote = Font.custom(fBoldName, size: 10)
}

public extension UIFont {
    static let fLargeTitle = UIFont(name: fName, size: 24)
    static let fTitle = UIFont(name: fName, size: 20)
    static let fSubtitle = UIFont(name: fName, size: 18)
    static let fSubheadline = UIFont(name: fName, size: 16)
    static let fBody = UIFont(name: fName, size: 14)
    static let fCaption = UIFont(name: fName, size: 13)
    static let fCaption2 = UIFont(name: fName, size: 12)
    static let fCaption3 = UIFont(name: fName, size: 11)
    static let fFootnote = UIFont(name: fName, size: 10)

    static let fBoldLargeTitle = UIFont(name: fBoldName, size: 24)
    static let fBoldTitle = UIFont(name: fBoldName, size: 20)
    static let fBoldSubtitle = UIFont(name: fBoldName, size: 18)
    static let fBoldSubheadline = UIFont(name: fBoldName, size: 16)
    static let fBoldBody = UIFont(name: fBoldName, size: 14)
    static let fBoldCaption = UIFont(name: fBoldName, size: 13)
    static let fBoldCaption2 = UIFont(name: fBoldName, size: 12)
    static let fBoldCaption3 = UIFont(name: fBoldName, size: 11)
    static let fBoldFootnote = UIFont(name: fBoldName, size: 10)
}
