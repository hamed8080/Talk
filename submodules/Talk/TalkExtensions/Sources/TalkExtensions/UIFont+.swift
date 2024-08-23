//
//  UIFont+.swift
//
//
//  Created by hamed on 7/25/24.
//

import Foundation
import SwiftUI

public extension UIFont {
    static let bold = "SVJBTlNhbnNYLUJvbGQ=".fromBase64() ?? ""
    static let regular = "SVJBTlNhbnNYLVJlZ3VsYXI=".fromBase64() ?? ""

    static func register(bundle: Bundle) {
        registerFont(name: bold, bundle: bundle)
        registerFont(name: regular, bundle: bundle)
    }

    private static func registerFont(name: String, bundle: Bundle) {
        guard let fontURL = bundle.url(forResource: name, withExtension: "ttf") else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }
}

public extension Font {
    static let flargeTitle = Font.custom(UIFont.regular, size: 24)
    static let ftitle = Font.custom(UIFont.regular, size: 20)
    static let fSubtitle = Font.custom(UIFont.regular, size: 18)
    static let fSubheadline = Font.custom(UIFont.regular, size: 16)
    static let fBody = Font.custom(UIFont.regular, size: 14)
    static let fCaption = Font.custom(UIFont.regular, size: 13)
    static let fCaption2 = Font.custom(UIFont.regular, size: 12)
    static let fCaption3 = Font.custom(UIFont.regular, size: 11)
    static let fFootnote = Font.custom(UIFont.regular, size: 10)

    static let fBoldLargeTitle = Font.custom(UIFont.bold, size: 24)
    static let fBoldTitle = Font.custom(UIFont.bold, size: 20)
    static let fBoldSubtitle = Font.custom(UIFont.bold, size: 18)
    static let fBoldSubheadline = Font.custom(UIFont.bold, size: 16)
    static let fBoldBody = Font.custom(UIFont.bold, size: 14)
    static let fBoldCaption = Font.custom(UIFont.bold, size: 13)
    static let fBoldCaption2 = Font.custom(UIFont.bold, size: 12)
    static let fBoldCaption3 = Font.custom(UIFont.bold, size: 11)
    static let fBoldFootnote = Font.custom(UIFont.bold, size: 10)
}

public extension UIFont {
    static let fLargeTitle = UIFont(name: UIFont.regular, size: 24)
    static let fTitle = UIFont(name: UIFont.regular, size: 20)
    static let fSubtitle = UIFont(name: UIFont.regular, size: 18)
    static let fSubheadline = UIFont(name: UIFont.regular, size: 16)
    static let fBody = UIFont(name: UIFont.regular, size: 14)
    static let fCaption = UIFont(name: UIFont.regular, size: 13)
    static let fCaption2 = UIFont(name: UIFont.regular, size: 12)
    static let fCaption3 = UIFont(name: UIFont.regular, size: 11)
    static let fFootnote = UIFont(name: UIFont.regular, size: 10)

    static let fBoldLargeTitle = UIFont(name: UIFont.bold, size: 24)
    static let fBoldTitle = UIFont(name: UIFont.bold, size: 20)
    static let fBoldSubtitle = UIFont(name: UIFont.bold, size: 18)
    static let fBoldSubheadline = UIFont(name: UIFont.bold, size: 16)
    static let fBoldBody = UIFont(name: UIFont.bold, size: 14)
    static let fBoldCaption = UIFont(name: UIFont.bold, size: 13)
    static let fBoldCaption2 = UIFont(name: UIFont.bold, size: 12)
    static let fBoldCaption3 = UIFont(name: UIFont.bold, size: 11)
    static let fBoldFootnote = UIFont(name: UIFont.bold, size: 10)
}
