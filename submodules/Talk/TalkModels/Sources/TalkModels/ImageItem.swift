import Foundation

public class ImageItem: Hashable, Identifiable, ObservableObject {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    public let id: UUID
    public var data: Data
    public var originalFilename: String?
    public var fileName: String? { originalFilename }
    public var width: Int
    public var height: Int
    public let isVideo: Bool
    public var progress: Progress?
    public var failed: Bool = false

    public init(id: UUID = UUID(),
                isVideo: Bool = false,
                data: Data,
                width: Int,
                height: Int,
                originalFilename: String? = nil,
                progress: Progress? = nil,
                failed: Bool = false
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.data = data
        self.isVideo = isVideo
        self.originalFilename = originalFilename
        self.progress = progress
    }
}
