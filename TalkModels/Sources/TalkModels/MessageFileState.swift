import Foundation
import UIKit

public struct MessageFileState {
    public var progress: CGFloat
    public var showDownload: Bool
    public var isUploading: Bool
    public var state: DownloadFileState
    public var iconState: String
    public var blurRadius: CGFloat
    // Preload Image: Either a placeholder image or a thumbnail image
    public var preloadImage: UIImage?

    public init(progress: CGFloat = 0.0,
                showImage: Bool = false,
                showDownload: Bool = false,
                isUploading: Bool = false,
                state: DownloadFileState = .undefined,
                iconState: String = "arrow.down",
                blurRadius: CGFloat = 0,
                preloadImage: UIImage? = nil) {
        self.progress = progress
        self.showDownload = showDownload
        self.isUploading = isUploading
        self.state = state
        self.iconState = iconState
        self.blurRadius = blurRadius
        self.preloadImage = preloadImage
    }

    mutating public func update(_ newState: MessageFileState) {
        let oldImage = preloadImage
        self = newState
        if newState.state == .downloading, let oldImage = oldImage {
            preloadImage = oldImage
        } else if newState.state == .completed {
            preloadImage = nil
        }
    }
}
