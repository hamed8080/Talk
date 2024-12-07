import Chat
import Combine
import Foundation

@MainActor
class ThumbnailDownloadManagerViewModel {
    private var objectId = UUID().uuidString
    private let THUMBNAIL_KEY: String
    private var uniqueId: String = ""
    private var cancellable: AnyCancellable?
    public var onDownload: ((Data?) -> Void)?

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
    public func downloadBlurImage(req: ImageRequest) {        
        uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: THUMBNAIL_KEY, value: req, autoCancel: false)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.get(req)
        }
    }

    private func onResponse(_ response: ChatResponse<Data>, _ url: URL?) {
        if response.uniqueId != uniqueId { return }
        if !response.cache, response.pop(prepend: THUMBNAIL_KEY) != nil, let data = response.result {
            onDownload?(data)
        }
    }

    public func removeKey() {
        _ = RequestsManager.shared.pop(prepend: THUMBNAIL_KEY, for: uniqueId)
    }
}
