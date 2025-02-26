import Foundation
public struct DropItem: Identifiable, Sendable {
    public let id: UUID = .init()
    public let data: Data?
    public let name: String?
    public let iconName: String?
    public let ext: String?
    public var fileSize: String { data?.count.toSizeString(locale: Language.preferredLocale) ?? "" }

    public init(data: Data? = nil, name: String? = nil, iconName: String? = nil, ext: String? = nil) {
        self.data = data
        self.name = name
        self.iconName = iconName
        self.ext = ext
    }

}
