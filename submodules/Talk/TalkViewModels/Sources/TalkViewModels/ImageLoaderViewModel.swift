//
//  ImageLoaderViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation
import UIKit
import TalkModels
import TalkExtensions
import Combine

public struct ImageLoaderConfig {
    public let url: String
    public let metaData: String?
    public let userName: String?
    public let size: ImageSize
    public let forceToDownloadFromServer: Bool
    public let thumbnail: Bool
    
    public init(url: String, size: ImageSize = .SMALL, metaData: String? = nil, userName: String? = nil, thumbnail: Bool = false, forceToDownloadFromServer: Bool = false) {
        self.url = url
        self.metaData = metaData
        self.userName = userName
        self.size = size
        self.forceToDownloadFromServer = forceToDownloadFromServer
        self.thumbnail = thumbnail
    }
}

public final class ImageLoaderViewModel: ObservableObject {
    @Published public private(set) var image: UIImage = .init()
    public var onImage: ((UIImage) -> Void)?
    private(set) var fileMetadata: String?
    public private(set) var cancelable: Set<AnyCancellable> = []
    private var uniqueId: String?
    public private(set) var config: ImageLoaderConfig
    private var isFetching: Bool = false
    private var objectId = UUID().uuidString
    private let IMAGE_LOADER_KEY: String

    public init(config: ImageLoaderConfig) {
        IMAGE_LOADER_KEY = "IMAGE-LOADER-\(objectId)"
        self.config = config
        NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink{ [weak self] event in
                Task { [weak self] in
                    await self?.onDownloadEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    @HistoryActor
    private func onDownloadEvent(_ event: DownloadEventTypes) async {
        switch event {
        case .image(let chatResponse, let url):
            await onGetImage(chatResponse, url)
        default:
            break
        }
    }

    public var isImageReady: Bool {
        image.size.width > 0
    }

    private func setImage(data: Data) async {
        var image: UIImage? = nil
        if config.size == .ACTUAL {
            autoreleasepool {
                image = UIImage(data: data) ?? UIImage()
            }
        } else {
            guard let cgImage = data.imageScale(width: config.size == .SMALL ? 128 : 256)?.image else { return }
            autoreleasepool {
                image = UIImage(cgImage: cgImage)
            }
        }

        if let image = image {
            await updateImage(image: image)
        }
    }

    private func setCachedImage(fileURL: URL) async {
        var image: UIImage? = nil
        if config.size == .ACTUAL, let data = fileURL.data {
            image = UIImage(data: data) ?? UIImage()
        } else {
            guard let cgImage = fileURL.imageScale(width: config.size == .SMALL ? 128 : 256)?.image else { return }
            image = UIImage(cgImage: cgImage)
        }
        if let image = image {
            await updateImage(image: image)
        }
    }

    @MainActor
    private func updateImage(image: UIImage) {
        self.image = image
        isFetching = false
        onImage?(image)
    }

    /// The hashCode decode FileMetaData so it needs to be done on the background thread.
    public func fetch() {
        Task { @HistoryActor [weak self] in
            guard let self = self else { return }
            let hashCode = await getHashCode()
            isFetching = true
            fileMetadata = config.metaData
            if let hashCode = hashCode {
                getFromSDK(hashCode: hashCode)
            } else if isPodURL() {
                await downloadRestImageFromPodURL()
            } else if let fileURL = getCachedFileURL() {
                await setCachedImage(fileURL: fileURL)
            }
        }
    }

    private func getFromSDK(hashCode: String) {
        let req = ImageRequest(hashCode: hashCode, forceToDownloadFromServer: config.forceToDownloadFromServer, size: config.size, thumbnail: config.thumbnail)
        uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: IMAGE_LOADER_KEY, value: req)
        ChatManager.activeInstance?.file.get(req)
    }

    @HistoryActor
    private func onGetImage(_ response: ChatResponse<Data>, _ url: URL?) async {
        guard response.uniqueId == uniqueId else { return }
        if response.uniqueId == uniqueId, !response.cache, let data = response.result {
            response.pop(prepend: IMAGE_LOADER_KEY)
            await update(data: data)
            await storeInCache(data: data) // For retrieving Widgetkit images with the help of the app group.
        } else {
            guard let url = url else { return }
            response.pop(prepend: IMAGE_LOADER_KEY)
            await setCachedImage(fileURL: url)
        }
    }

    private func update(data: Data) async {
        guard isRealImage(data) else { return }
        await setImage(data: data)
    }

    @MainActor
    private func storeInCache(data: Data) {
        guard isRealImage(data), let url = getURL() else { return }
        ChatManager.activeInstance?.file.saveFileInGroup(url: url, data: data) { _ in }
    }

    private var headers: [String: String] {
        token != nil ? ["Authorization": "Bearer \(token ?? "")"] : [:]
    }

    private var token: String? {
        guard let data = UserDefaults.standard.data(forKey: TokenManager.ssoTokenKey),
              let ssoToken = try? JSONDecoder().decode(SSOTokenResponse.self, from: data)
        else {
            return nil
        }
        return ssoToken.accessToken
    }

    public func clear() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
        cancelable.removeAll()
        image = .init()
        isFetching = false
    }

    public func updateCondig(config: ImageLoaderConfig) {
        image = .init()
        isFetching = false
        self.config = config
    }

    private func getMetaData() async ->  FileMetaData? {
        guard let fileMetadata = (config.metaData ?? fileMetadata)?.data(using: .utf8) else { return nil }
        return try? JSONDecoder.instance.decode(FileMetaData.self, from: fileMetadata)
    }

    @HistoryActor
    private func getHashCode() async -> String? {
        let parsedMetadata = await getMetaData()
        return parsedMetadata?.fileHash ?? getOldURLHash() ?? getHashByLastPath()
    }

    private func getOldURLHash() -> String? {
        guard let url = getURL(), let comp = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        return comp.queryItems?.first(where: { $0.name == "hash" })?.value
    }
    
    private func getHashByLastPath() -> String? {
        guard let url = getURL(), let comp = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        let isPodspaceFile = url.absoluteString.contains("https://podspace.pod.ir/api/files/")
        let isPodspaceImage = url.absoluteString.contains("https://podspace.pod.ir/api/images/")
        if isPodspaceFile || isPodspaceImage {
            return url.lastPathComponent
        }
        return nil
    }

    private func getCachedFileURL() -> URL? {
        guard let url = getURL(),
              let fileManager = ChatManager.activeInstance?.file
        else { return nil }
        if fileManager.isFileExist(url) {
            return fileManager.filePath(url)
        } else if fileManager.isFileExistInGroup(url) {
            return fileManager.filePathInGroup(url)
        }
        return nil
    }

    private func getURL() -> URL? {
        URL(string: config.url)
    }

    private func isRealImage(_ data: Data) -> Bool {
        return UIImage(data: data) != nil
    }

    private func isPodURL() -> Bool {
        let url = getURL()
        return url?.host() == "core.pod.ir"
    }

    @HistoryActor
    private func downloadRestImageFromPodURL() async {
        guard let url = getURL() else { return }
        var request = URLRequest(url: url)
        uniqueId = "\(request.hashValue)"
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        let response = try? await URLSession.shared.data(for: request)
        guard let data = response?.0 else { return }
        await update(data: data)
        uniqueId = nil
        await storeInCache(data: data)
    }
}
