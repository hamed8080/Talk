//
//  Font+.swift
//  TalkUI
//
//  Created by hamed on 3/15/23.
//

import SwiftUI

public extension UIFont {
    static func register() {
        registerFont(name: "IRANSansX-Bold")
        registerFont(name: "IRANSansX-Regular")
    }

    private static func registerFont(name: String) {
        guard let fontURL = Bundle.module.url(forResource: name, withExtension: "ttf") else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }
}

public extension Font {
    static let flargeTitle = Font.custom("IRANSansX", size: 24)
    static let ftitle = Font.custom("IRANSansX", size: 20)
    static let fSubtitle = Font.custom("IRANSansX", size: 18)
    static let fSubheadline = Font.custom("IRANSansX", size: 16)
    static let fBody = Font.custom("IRANSansX", size: 14)
    static let fCaption = Font.custom("IRANSansX", size: 13)
    static let fCaption2 = Font.custom("IRANSansX", size: 12)
    static let fCaption3 = Font.custom("IRANSansX", size: 11)
    static let fFootnote = Font.custom("IRANSansX", size: 10)

    static let fBoldLargeTitle = Font.custom("IRANSansX-Bold", size: 24)
    static let fBoldTitle = Font.custom("IRANSansX-Bold", size: 20)
    static let fBoldSubtitle = Font.custom("IRANSansX-Bold", size: 18)
    static let fBoldSubheadline = Font.custom("IRANSansX-Bold", size: 16)
    static let fBoldBody = Font.custom("IRANSansX-Bold", size: 14)
    static let fBoldCaption = Font.custom("IRANSansX-Bold", size: 13)
    static let fBoldCaption2 = Font.custom("IRANSansX-Bold", size: 12)
    static let fBoldCaption3 = Font.custom("IRANSansX-Bold", size: 11)
    static let fBoldFootnote = Font.custom("IRANSansX-Bold", size: 10)
}

public extension UIFont {
    static let fLargeTitle = UIFont(name: "IRANSansX", size: 24)
    static let fTitle = UIFont(name: "IRANSansX", size: 20)
    static let fSubtitle = UIFont(name: "IRANSansX", size: 18)
    static let fSubheadline = UIFont(name: "IRANSansX", size: 16)
    static let fBody = UIFont(name: "IRANSansX", size: 14)
    static let fCaption = UIFont(name: "IRANSansX", size: 13)
    static let fCaption2 = UIFont(name: "IRANSansX", size: 12)
    static let fCaption3 = UIFont(name: "IRANSansX", size: 11)
    static let fFootnote = UIFont(name: "IRANSansX", size: 10)

    static let fBoldLargeTitle = UIFont(name: "IRANSansX-Bold", size: 24)
    static let fBoldTitle = UIFont(name: "IRANSansX-Bold", size: 20)
    static let fBoldSubtitle = UIFont(name: "IRANSansX-Bold", size: 18)
    static let fBoldSubheadline = UIFont(name: "IRANSansX-Bold", size: 16)
    static let fBoldBody = UIFont(name: "IRANSansX-Bold", size: 14)
    static let fBoldCaption = UIFont(name: "IRANSansX-Bold", size: 13)
    static let fBoldCaption2 = UIFont(name: "IRANSansX-Bold", size: 12)
    static let fBoldCaption3 = UIFont(name: "IRANSansX-Bold", size: 11)
    static let fBoldFootnote = UIFont(name: "IRANSansX-Bold", size: 10)
}
