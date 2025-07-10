import Chat
import Combine
import Foundation
import UIKit

@MainActor
public class ThumbnailDownloadManagerViewModel {
    private var objectId = UUID().uuidString
    private let THUMBNAIL_KEY: String
    private var uniqueId: String = ""
    private var cancellable: AnyCancellable?
    public var onDownload: (@Sendable (Data?) -> Void)?

    public init() {
        THUMBNAIL_KEY = "THUMBNAIL-\(objectId)"
        setObservers()
    }

    private func setObservers() {
        cancellable = NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] value in
                self?.onDownloadEvent(value)
            }
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) {
        switch event {
        case .file(let chatResponse, let url):
            onResponse(chatResponse, url)
        case .image(let chatResponse, let url):
            onResponse(chatResponse, url)
        default:
            break
        }
    }

    /// We use a Task to decode fileMetaData and hashCode inside the fileHashCode.
    /// If the image we want to use as thumbnail for example in reply message image exist on cache
    /// we will return the cahce small version of it,
    /// instead of calling the Chat SDK to get large version of the cache with get which lead to memory spike
    public func downloadBlurImage(req: ImageRequest, url: URL, onDownload: (@Sendable (Data?) -> Void)? = nil) {
        self.onDownload = onDownload
        uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: THUMBNAIL_KEY, value: req, autoCancel: false)
        Task { @ChatGlobalActor [weak self] in
            if let data = self?.cacheData(url: url) {
                await self?.onCacheResponse(data: data)
            } else {
                ChatManager.activeInstance?.file.get(req)
            }
        }
    }
    
    public func downloadThumbnail(req: ImageRequest, url: URL) async -> Data? {
        typealias ResultType = CheckedContinuation<Data?, Never>
        return await withCheckedContinuation { [weak self] (continuation: ResultType) in
            self?.downloadBlurImage(req: req, url: url) { data in
                continuation.resume(with: .success(data))
            }
        }
    }

    private func onResponse(_ response: ChatResponse<Data>, _ url: URL?) {
        if response.uniqueId != uniqueId { return }
        if response.pop(prepend: THUMBNAIL_KEY) != nil, let data = response.result {
            onDownload?(data)
        }
    }
    
    @ChatGlobalActor
    private func cacheData(url: URL) -> Data? {
        guard let filePath = ChatManager.activeInstance?.file.filePath(url),
              let cgImage = filePath.imageScale(width: 100)?.image,
              let data = UIImage(cgImage: cgImage).pngData()
        else { return nil }
        return data
    }
    
    private func onCacheResponse(data: Data) {
        onDownload?(data)
        removeKey()
        onDownload = nil
    }

    public func removeKey() {
        _ = RequestsManager.shared.pop(prepend: THUMBNAIL_KEY, for: uniqueId)
    }
}

extension ThumbnailDownloadManagerViewModel {
    @AppBackgroundActor
    public class func get(message: Message) async -> UIImage? {
        guard let url = await message.url else { return nil }
        let req = ImageRequest(hashCode: message.fileHashCode, quality: 1.0, size: .MEDIUM, thumbnail: true)
        guard
            let data = await ThumbnailDownloadManagerViewModel().downloadThumbnail(req: req, url: url),
            let image = UIImage(data: data)
        else { return nil }
        return image
    }
}
