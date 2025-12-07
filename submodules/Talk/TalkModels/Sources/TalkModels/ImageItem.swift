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
    public var fileExt: String?
    public var fileName: String? { originalFilename }
    public var width: Int
    public var height: Int
    public var isVideo: Bool
    public var progress: Progress?
    public var failed: Bool = false

    public init(id: UUID = UUID(),
                isVideo: Bool = false,
                data: Data,
                width: Int,
                height: Int,
                originalFilename: String? = nil,
                fileExt: String? = nil,
                progress: Progress? = nil,
                failed: Bool = false
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.data = data
        self.isVideo = isVideo
        self.originalFilename = originalFilename
        self.fileExt = fileExt
        self.progress = progress
    }
}
