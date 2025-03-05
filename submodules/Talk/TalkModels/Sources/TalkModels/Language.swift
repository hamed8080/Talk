import Foundation

public struct Language: Identifiable, Sendable {
    public var id: String { identifier }
    public let identifier: String
    public let language: String
    public let bundleFolderName: String
    public let text: String

    public init(identifier: String, bundleFolderName: String, language: String, text: String) {
        self.identifier = identifier
        self.bundleFolderName = bundleFolderName
        self.language = language
        self.text = text
    }

    nonisolated(unsafe) public static let languages: [Language] = [
        .init(identifier: "en_US", bundleFolderName: "en", language: "en-US", text: "English"),
        .init(identifier: "ZmFfSVI=".fromBase64() ?? "", bundleFolderName: "fa-IR", language: "fa-IR", text: "UGVyc2lhbiAo2YHYp9ix2LPbjCk=".fromBase64() ?? ""),
        .init(identifier: "sv_SE", bundleFolderName: "sv", language: "sv-SE", text: "Swedish"),
        .init(identifier: "de_DE", bundleFolderName: "de", language: "de-DE", text: "Germany"),
        .init(identifier: "es_ES", bundleFolderName: "es", language: "es-ES", text: "Spanish"),
        .init(identifier: "ar_SA", bundleFolderName: "ar", language: "ar-SA", text: "Arabic")
    ]

    public static var preferredLocale: Locale {
        if let cachedPreferedLocale = cachedPreferedLocale {
            return cachedPreferedLocale
        } else {
            let localIdentifier = Language.languages.first(where: {$0.language == Locale.preferredLanguages[0] })?.identifier
            let preferedLocale = Locale(identifier: localIdentifier ?? "en_US")
            cachedPreferedLocale = preferedLocale
            return preferedLocale
        }
    }

    public static var preferredLocaleLanguageCode: String {
        return Language.languages.first(where: {$0.language == Locale.preferredLanguages[0] })?.language ?? "en"
    }

    public static var rtlLanguages: [Language] {
        languages.filter{ $0.identifier == "ar_SA" || $0.identifier == "ZmFfSVI=".fromBase64() }
    }

    public static var isRTL: Bool {
        if let cachedIsRTL = cachedIsRTL {
            return cachedIsRTL
        } else {
            let isRTL = rtlLanguages.contains(where: {$0.language == Locale.preferredLanguages[0] })
            cachedIsRTL = isRTL
            return isRTL
        }
    }

    public static var preferedBundle: Bundle {
        if let cachedbundel = cachedbundel {
            return cachedbundel
        }
        guard
            let path = Bundle.main.path(forResource: preferredLocaleLanguageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .main }
        cachedbundel = bundle
        return bundle
    }
    
    public static func setLanguageTo(bundle: Bundle, language: Language) {
        
        if language.language != Locale.preferredLanguages[0] {
            UserDefaults.standard.set([language.identifier], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
        
        rootBundle = bundle
        
        let isRTL = rtlLanguages.contains(where: { $0.language == language.language })
        cachedIsRTL = isRTL
        
        if let path = bundle.path(forResource: language.bundleFolderName, ofType: "lproj") {
            cachedbundel = Bundle(path: path)
        }
        
        let preferedLocale = Locale(identifier: language.identifier ?? "en_US")
        cachedPreferedLocale = preferedLocale
    }
    
    /// root bundle is the main folder of MyBundle.bundle,
    /// which is contains ringtones and fonts.
    nonisolated(unsafe) public static var rootBundle: Bundle?
    
    /// cachedBundle is language specific bundle such as MyBundle.bundle/fa-IR.lproj ,
    /// which is not contains ringtones and fonts.
    nonisolated(unsafe) private static var cachedbundel: Bundle?
    nonisolated(unsafe) private static var cachedIsRTL: Bool?
    nonisolated(unsafe) private static var cachedPreferedLocale: Locale?
}
