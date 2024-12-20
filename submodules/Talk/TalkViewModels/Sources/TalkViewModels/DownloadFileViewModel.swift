import Chat
import TalkModels
import Combine
import Foundation
import SwiftUI

public protocol DownloadFileViewModelProtocol {
    var message: Message? { get }
    var fileHashCode: String { get }
    var data: Data? { get }
    var state: DownloadFileState { get }
    var url: URL? { get }
    var fileURL: URL? { get }
    func setObservers()
    func startDownload()
    func pauseDownload()
    func resumeDownload()
}

public final class DownloadFileViewModel: ObservableObject, DownloadFileViewModelProtocol {
    private var downloadPercent: Int64 = 0
    public var state: DownloadFileState = .undefined
    public var thumbnailData: Data?
    public var data: Data?
    public var fileHashCode: String { message?.fileHashCode ?? "" }
    var chat: Chat? { ChatManager.activeInstance }
    var uniqueId: String = ""
    public var message: Message?
    private var cancellableSet: Set<AnyCancellable> = .init()
    public var fileURL: URL? { message?.fileURL }
    public var url: URL? { message?.url }
    public var isInCache: Bool = false
    private let queue: DispatchQueue
    private var thumbnailVM: ThumbnailDownloadManagerViewModel?
    private var isConverting = false

    public init(message: Message, queue: DispatchQueue) {
        self.queue = queue
        self.message = message
        thumbnailVM = .init()
        setObservers()
    }

    /// It should be on the background thread because it decodes metadata in message.url.
    public func setup() async {
        if let url = url {
            isInCache = chat?.file.isFileExist(url) ?? false || chat?.file.isFileExistInGroup(url) ?? false
        }
        if isInCache {
            await MainActor.run {
                state = .completed
                thumbnailData = nil
                animateObjectWillChange()
            }
        }
    }

    public func setObservers() {
        NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] value in
                self?.queue.async { [weak self] in
                    self?.onDownloadEvent(value)
                }
            }
            .store(in: &cancellableSet)

        NotificationCenter.galleryDownload.publisher(for: .galleryDownload)
            .compactMap { $0.object as? (request: ImageRequest, data: Data) }
            .sink { [weak self] result in
                self?.onGalleryDownload(result)
            }
            .store(in: &cancellableSet)

        thumbnailVM?.onDownload = { [weak self] data in
            self?.setThumbnail(data: data)
        }
    }

    private func onGalleryDownload(_ result: (request: ImageRequest, data: Data)) {
        if result.request.hashCode == fileHashCode {
            setData(data: result.data)
        }
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) {
        switch event {
        case .resumed(let uniqueId):
            onResumed(uniqueId)
        case .file(let chatResponse, let url):
            onResponse(chatResponse, url)
        case .image(let chatResponse, let url):
            onResponse(chatResponse, url)
        case .suspended(let uniqueId):
            onSuspend(uniqueId)
        case .progress(let uniqueId, let progress):
            onProgress(uniqueId, progress)
        default:
            break
        }
    }

    public func startDownload() {
        if isInCache { return }
        if message?.isImage == true {
            downloadImage()
        } else {
            downloadFile()
        }
    }

    /// We use a Task to decode fileMetaData and hashCode inside the fileHashCode.
    private func downloadFile() {
        Task { [weak self] in
            guard let self = self else { return }
            state = .downloading
            let req = FileRequest(hashCode: fileHashCode, conversationId: message?.threadId ?? message?.conversation?.id)
            uniqueId = req.uniqueId
            RequestsManager.shared.append(value: req, autoCancel: false)
            ChatManager.activeInstance?.file.get(req)
            animateObjectWillChange()
        }
    }

    /// We use a Task to decode fileMetaData and hashCode inside the fileHashCode.
    private func downloadImage() {
        Task { [weak self] in
            guard let self = self else { return }
            state = .downloading
            let req = ImageRequest(hashCode: fileHashCode, size: .ACTUAL, conversationId: message?.threadId ?? message?.conversation?.id)
            uniqueId = req.uniqueId
            RequestsManager.shared.append(value: req, autoCancel: false)
            ChatManager.activeInstance?.file.get(req)
            animateObjectWillChange()
        }
    }

    /// We use a Task to decode fileMetaData and hashCode inside the fileHashCode.
    public func downloadBlurImage(quality: Float = 0.02, size: ImageSize = .SMALL) {
        guard let threadId = message?.threadId ?? message?.conversation?.id else { return }
        let hashCode = fileHashCode
        state = .thumbnailDownloaing
        let req = ImageRequest(hashCode: hashCode, quality: quality, size: size, thumbnail: true, conversationId: threadId)
        thumbnailVM?.downloadBlurImage(req: req)
    }

    private func onResponse(_ response: ChatResponse<Data>, _ url: URL?) {
        if response.uniqueId != uniqueId { return }

        if response.cache, let data = response.result {
            setData(data: data)
        }

        if RequestsManager.shared.contains(key: uniqueId), let data = response.result {
            setData(data: data)
        }

        if isGalleryURL(response, url: url) {
            RequestsManager.shared.remove(key: uniqueId)
            setData(data: response.result)
        }
    }

    private func setData(data: Data?) {
        guard let filePath = fileURL, !isConverting, let message = message else { return }
        Task { [weak self] in
            guard let self = self else { return }
            let isVoice = message.type == .podSpaceVoice || message.type == .voice
            print("isVoice: \(isVoice)")
            if isVoice, await OpusConverter.isOpus(path: filePath) {
                print("Converting the voice file")
                isConverting = true
                let convertedURL = await OpusConverter.convert(message)
                print(convertedURL)
                if let convertedURL = convertedURL, let data = try? Data(contentsOf: convertedURL) {
                    setDataSync(data: data)
                }
            } else {
                setDataSync(data: data)
            }
        }
    }

    private func setDataSync(data: Data?) {
        autoreleasepool {
            state = .completed
            downloadPercent = 100
            self.data = data
            thumbnailData = nil
            thumbnailVM?.removeKey()
            thumbnailVM = nil
            isInCache = true
            animateObjectWillChange()
        }
    }

    private func setThumbnail(data: Data?) {
        //State is not completed and blur view can show the thumbnail
        state = .thumbnail
        autoreleasepool {
            self.thumbnailData = data
            animateObjectWillChange()
        }
    }

    /// When the user clicks on the side of an image not directly hit the download button, it triggers gallery view, and therefore after the user is back to the view the image and file should update properly.
    private func isGalleryURL(_ response: ChatResponse<Data>, url: URL?) -> Bool {
        !response.cache && RequestsManager.shared.contains(key: uniqueId) && url?.absoluteString == fileURL?.absoluteString
    }

    private func onSuspend(_ uniqueId: String) {
        if isSameUnqiueId(uniqueId) {
            state = .paused
            animateObjectWillChange()
        }
    }

    private func onResumed(_ uniqueId: String) {
        if isSameUnqiueId(uniqueId) {
            state = .downloading
            animateObjectWillChange()
        }
    }

    private func onProgress(_ uniqueId: String, _ progress: DownloadFileProgress?) {
        if isSameUnqiueId(uniqueId) {
            self.downloadPercent = progress?.percent ?? 0
            animateObjectWillChange()
        }
    }

    public func pauseDownload() {
        ChatManager.activeInstance?.file.manageDownload(uniqueId: uniqueId, action: .suspend)
    }

    public func resumeDownload() {
        ChatManager.activeInstance?.file.manageDownload(uniqueId: uniqueId, action: .resume)
    }

    private func isSameUnqiueId(_ uniqueId: String) -> Bool {
        RequestsManager.shared.contains(key: self.uniqueId) && uniqueId == self.uniqueId
    }

    public func downloadPercentValue() -> Int64 {
        queue.sync {
            return downloadPercent
        }
    }

    public func downloadPercentValueNoLock() -> Int64 {
        return downloadPercent
    }

    deinit {
        cancellableSet.forEach { cancellable in
            cancellable.cancel()
        }
    }
}
