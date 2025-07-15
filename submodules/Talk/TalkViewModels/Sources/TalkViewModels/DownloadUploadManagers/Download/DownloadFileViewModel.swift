import Chat
import TalkModels
import Combine
import Foundation
import SwiftUI

@MainActor
public protocol DownloadFileViewModelProtocol {
    var message: Message { get }
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

@MainActor
public final class DownloadFileViewModel: ObservableObject, DownloadFileViewModelProtocol {
    /// A value between 0...100
    public private(set) var downloadPercent: Int64 = 0
    public var state: DownloadFileState = .undefined
    public var data: Data?
    
    public var fileHashCode: String = ""
    var uniqueId: String = ""
    public let message: Message
    private var cancellableSet: Set<AnyCancellable> = .init()
    public var fileURL: URL? = nil
    public var url: URL? = nil
    public var isInCache: Bool = false
    private var isConverting = false

    public init(message: Message) {
        self.message = message
        setObservers()
        Task { @AppBackgroundActor in
            await prepare()
        }
    }
    
    public init(message: Message) async {
        self.message = message
        setObservers()
        await prepare()
        await setup()
    }
    
    @AppBackgroundActor
    private func prepare() async {
        let url = await message.url
        let fileURL = await message.fileURL
        let fileHashCode = await message.fileHashCode
        await MainActor.run {
            self.url = url
            self.fileURL = fileURL
            self.fileHashCode = fileHashCode
        }
    }

    /// It should be on the background thread because it decodes metadata in message.url.
    public func setup() async {
        if let url = url {
            isInCache = await message.isFileExistOnDisk()
            if isInCache {
                state = .completed
                animateObjectWillChange()
            }
        }
    }

    public func setObservers() {
        NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] value in
                Task { @MainActor [weak self] in
                    self?.onDownloadEvent(value)
                }
            }
            .store(in: &cancellableSet)
        
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<any Sendable> }
            .filter { $0.uniqueId == self.uniqueId }
            .sink { [weak self] result in
                Task { @MainActor [weak self] in
                    self?.onFailed()
                }
            }
            .store(in: &cancellableSet)

        NotificationCenter.galleryDownload.publisher(for: .galleryDownload)
            .compactMap { $0.object as? (request: ImageRequest, data: Data) }
            .sink { [weak self] result in
                self?.onGalleryDownload(result)
            }
            .store(in: &cancellableSet)
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
        case .downloadFile(let chatResponse):
            onResponse(chatResponse)
        case .image(let chatResponse, let url):
            onResponse(chatResponse, url)
        case .downloadImage(let chatResponse):
            onResponse(chatResponse)
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
        if message.isImage == true {
            downloadImage()
        } else {
            downloadFile()
        }
    }

    /// We use a Task to decode fileMetaData and hashCode inside the fileHashCode.
    private func downloadFile() {
        Task { [weak self] in
            guard let self = self else { return }
            let fileHashCode = await getHashCode()
            state = .downloading
            let req = FileRequest(hashCode: fileHashCode, conversationId: message.threadId ?? message.conversation?.id)
            uniqueId = req.uniqueId
            RequestsManager.shared.append(value: req, autoCancel: false)
            Task { @ChatGlobalActor in
                do {
                    try ChatManager.activeInstance?.file.download(req)
                } catch {
                    print(error.localizedDescription)
                }
            }
            animateObjectWillChange()
        }
    }

    /// We use a Task to decode fileMetaData and hashCode inside the fileHashCode.
    private func downloadImage() {
        Task { [weak self] in
            guard let self = self else { return }
            let fileHashCode = await getHashCode()
            state = .downloading
            let req = ImageRequest(hashCode: fileHashCode, size: .ACTUAL, conversationId: message.threadId ?? message.conversation?.id)
            uniqueId = req.uniqueId
            RequestsManager.shared.append(value: req, autoCancel: false)
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.file.get(req)
            }
            animateObjectWillChange()
        }
    }
    
    /// We will test to see if fileHashCode inside init has been set or not,
    /// If it has been set, we can use it properly and it has decoded on the background thread,
    /// If not we have got to decode it on the main thread with message file
    /// There is a chance to upload a file for example a map where it takes time to decode on AppBackgroundActor actor so it immediately call this function and start downloading a file/image with an empty hashcode.
    @AppBackgroundActor
    private func getHashCode() async -> String {
        let fileHashCode = await fileHashCode
        if !fileHashCode.isEmpty {
            return fileHashCode
        } else {
            let copied = await message
            return copied.fileHashCode ?? ""
        }
    }

    private func onResponse(_ response: ChatResponse<Data>, _ url: URL?) {
        if response.uniqueId != uniqueId { return }

        if response.cache, let data = response.result {
            setData(data: data)
        }

        if RequestsManager.shared.contains(key: uniqueId), let data = response.result {
            setData(data: data)
        }

        if isGalleryURL(isCache: response.cache, url: url) {
            RequestsManager.shared.remove(key: uniqueId)
            setData(data: response.result)
        }
    }
    
    private func onResponse(_ response: ChatResponse<URL>) {
        if response.uniqueId != uniqueId { return }
        guard let url = response.result, let data = try? Data(contentsOf: url) else { return }
        if response.cache {
            setData(data: data)
        }

        if RequestsManager.shared.contains(key: uniqueId) {
            setData(data: data)
        }

        if isGalleryURL(isCache: response.cache, url: url) {
            RequestsManager.shared.remove(key: uniqueId)
            setData(data: data)
        }
    }

    private func setData(data: Data?) {
        guard let filePath = fileURL, !isConverting else { return }
        Task { [weak self] in
            guard let self = self else { return }
            let isVoice = message.type == .podSpaceVoice || message.type == .voice
            if isVoice, await isOpus(filePath: filePath) {
                await convertIfIsOpus(message: message)
            } else {
                setDataSync(data: data)
            }
        }
    }
    
    private func onFailed() {
        state = .error
        animateObjectWillChange()
    }
    
    private func isOpus(filePath: URL) async -> Bool {
#if canImport(ffmpegkit)
        return await OpusConverter.isOpus(path: filePath)
#endif
        return false
    }

#if canImport(ffmpegkit)
    private func convertIfIsOpus(message: Message) async {
        isConverting = true
        let convertedURL = await OpusConverter.convert(message)
        if let convertedURL = convertedURL, let data = try? Data(contentsOf: convertedURL) {
            setDataSync(data: data)
        }
    }
#endif
    
    private func setDataSync(data: Data?) {
        autoreleasepool {
            state = .completed
            downloadPercent = 100
            self.data = data
            isInCache = true
            animateObjectWillChange()
        }
    }

    /// When the user clicks on the side of an image not directly hit the download button, it triggers gallery view, and therefore after the user is back to the view the image and file should update properly.
    private func isGalleryURL(isCache: Bool, url: URL?) -> Bool {
        !isCache && RequestsManager.shared.contains(key: uniqueId) && url?.absoluteString == fileURL?.absoluteString
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
            print("Resumable download progress in viewModel: \(progress?.percent ?? 0)")
            self.downloadPercent = progress?.percent ?? 0
            animateObjectWillChange()
        } else {
            print("Resumable download uniqueId is not the same for uniqueId: \(uniqueId)")
        }
    }

    public func pauseDownload() {
        let uniqueId = uniqueId
        Task { @ChatGlobalActor in
            do {
                try ChatManager.activeInstance?.file.pauseResumableDownload(uniqueId: uniqueId)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    public func resumeDownload() {
        let uniqueId = uniqueId
        Task { @ChatGlobalActor in
            do {
                try ChatManager.activeInstance?.file.resumeDownload(uniqueId: uniqueId)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func cancelDownload() {
        let uniqueId = uniqueId
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.manageDownload(uniqueId: uniqueId, action: .cancel)
        }
    }

    private func isSameUnqiueId(_ uniqueId: String) -> Bool {
        RequestsManager.shared.contains(key: self.uniqueId) && uniqueId == self.uniqueId
    }
    
    public func redownload() {
        cancelDownload()
        startDownload()
    }
}
