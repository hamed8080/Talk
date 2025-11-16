//
//  Font+.swift
//  TalkUI
//
//  Created by hamed on 3/15/23.
//

import SwiftUI

public enum FontName: String, CaseIterable {
    case bold = "bold"
    case extraBold = "extrabold"
    case regular = "regular"
    case heavy = "heavy"
    case black = "black"
    case extraBlack = "extrablack"
    case thin = "thin"
    case light = "light"
    case ultraLight = "ultralight"
    case medium = "medium"
    case demiBold = "demibold"
}

public enum FontFamily: String, CaseIterable {
    case bold = "SVJBTlNhbnNYRmFOdW0tQm9sZA=="
    case extraBold = "SVJBTlNhbnNYRmFOdW0tRXh0cmFCb2xk"
    case regular = "SVJBTlNhbnNYRmFOdW0tUmVndWxhcg=="
    case heavy = "SVJBTlNhbnNYRmFOdW0tSGVhdnk="
    case black = "SVJBTlNhbnNYRmFOdW0tQmxhY2s="
    case extraBlack = "SVJBTlNhbnNYRmFOdW0tRXh0cmFCbGFjaw=="
    case thin = "SVJBTlNhbnNYRmFOdW0tVGhpbg=="
    case light = "SVJBTlNhbnNYRmFOdW0tTGlnaHQ="
    case ultraLight = "SVJBTlNhbnNYRmFOdW0tVWx0cmFMaWdodA=="
    case medium = "SVJBTlNhbnNYRmFOdW0tTWVkaXVt"
    case demiBold = "SVJBTlNhbnNYRmFOdW0tRGVtaUJvbGQ="
    
    var name: String {
        fromBase64() ?? ""
    }
    
    private func fromBase64() -> String? {
        guard let data = Data(base64Encoded: rawValue) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

public enum FontSize: CGFloat, CaseIterable {
    case largeTitle = 24
    case title = 20
    case subtitle = 18
    case subheadline = 16
    case body = 14
    case caption = 13
    case caption2 = 12
    case caption3 = 11
    case footnote = 10
}

/// SwiftUI
public extension Font {
    static func font(familyName: FontFamily, size: FontSize) -> Font {
        return Font.custom(familyName.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func normal(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.regular.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func bold(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.bold.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func extraBold(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.extraBold.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func heavy(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.heavy.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func thin(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.thin.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func light(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.light.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func medium(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.medium.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func ultraLight(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.ultraLight.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func extraBlack(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.extraBlack.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func black(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.black.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
    
    static func demiBold(_ size: FontSize) -> Font {
        return Font.custom(FontFamily.demiBold.name, size: size.rawValue) ?? Font.system(size: size.rawValue)
    }
}

/// UIKit
public extension UIFont {
    static func font(familyName: FontFamily, size: FontSize) -> UIFont {
        return UIFont(name: familyName.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func normal(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.regular.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func bold(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.bold.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func extraBold(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.extraBold.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func heavy(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.heavy.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func thin(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.thin.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func light(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.light.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func medium(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.medium.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func ultraLight(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.ultraLight.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func extraBlack(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.extraBlack.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func black(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.black.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
    static func demiBold(_ size: FontSize) -> UIFont {
        return UIFont(name: FontFamily.demiBold.name, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
}

public extension UIFont {
    static func register(bundle: Bundle) {
        for name in FontName.allCases {
            registerFont(name: name.rawValue, bundle: bundle)
        }
    }
    
    private static func registerFont(name: String, bundle: Bundle) {
        guard let fontURL = bundle.url(forResource: name, withExtension: "ttf") else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }
}
