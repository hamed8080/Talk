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

public struct ImageLoaderConfig: Sendable {
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

@MainActor
public final class ImageLoaderViewModel: ObservableObject {
    @Published public private(set) var image: UIImage = .init()
    public var onImage: (@Sendable (UIImage) -> Void)?
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
        register()
    }

    public func register() {
        NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onDownloadEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) async {
        switch event {
        case .image(let chatResponse, let url):
            if chatResponse.uniqueId == uniqueId {
                await onGetImage(chatResponse, url)
            }
        default:
            break
        }
    }

    public var isImageReady: Bool {
        image.size.width > 0
    }

    @AppBackgroundActor
    private func setImage(data: Data, configSize: ImageSize) async {
        var image: UIImage? = nil
        if configSize == .ACTUAL {
            autoreleasepool {
                image = UIImage(data: data) ?? UIImage()
            }
        } else {
            guard let cgImage = data.imageScale(width: configSize == .SMALL ? 128 : 256)?.image else { return }
            autoreleasepool {
                image = UIImage(cgImage: cgImage)
            }
        }

        if let image = image {
            await MainActor.run {
                updateImage(image: image)
            }
        }
    }

    @AppBackgroundActor
    private func setCachedImage(fileURL: URL, configSize: ImageSize) async {
        var image: UIImage? = nil
        if configSize == .ACTUAL, let data = fileURL.data {
            image = UIImage(data: data) ?? UIImage()
        } else {
            guard let cgImage = fileURL.imageScale(width: configSize == .SMALL ? 128 : 256)?.image else { return }
            image = UIImage(cgImage: cgImage)
        }
        if let image = image {
            await MainActor.run {
                updateImage(image: image)
            }
        }
    }

    private func updateImage(image: UIImage) {
        self.image = image
        isFetching = false
        onImage?(image)
    }

    /// The hashCode decode FileMetaData so it needs to be done on the background thread.
    public func fetch() {
        Task { @AppBackgroundActor in
            await fetchAsync()
        }
    }
    
    private func fetchAsync() async {
        if config.url.isEmpty { return }
        let hashCode = await getHashCode()
        isFetching = true
        fileMetadata = config.metaData
        if let hashCode = hashCode {
            getFromSDK(hashCode: hashCode)
        } else if isPodURL() {
            await downloadRestImageFromPodURL()
        } else if let fileURL = await getCachedFileURL() {
            await setCachedImage(fileURL: fileURL, configSize: config.size)
        }
    }

    private func getFromSDK(hashCode: String) {
        let req = ImageRequest(hashCode: hashCode, forceToDownloadFromServer: config.forceToDownloadFromServer, size: config.size, thumbnail: config.thumbnail)
        uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: IMAGE_LOADER_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.get(req)
        }
    }

    @AppBackgroundActor
    private func onGetImage(_ response: ChatResponse<Data>, _ url: URL?) async {
        if !response.cache, let data = response.result {
            response.pop(prepend: IMAGE_LOADER_KEY)
            await update(data: data)
            await storeInCache(data: data) // For retrieving Widgetkit images with the help of the app group.
        } else {
            guard let url = url else { return }
            response.pop(prepend: IMAGE_LOADER_KEY)
            await setCachedImage(fileURL: url, configSize: config.size)
        }
    }

    @AppBackgroundActor
    private func update(data: Data) async {
        guard isRealImage(data) else { return }
        await setImage(data: data, configSize: config.size)
    }

    @AppBackgroundActor
    private func storeInCache(data: Data) async {
        let isRealImage = isRealImage(data)
        guard let url = await getURL() else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.saveFileInGroup(url: url, data: data) { _ in }
        }
    }

    @AppBackgroundActor
    private var headers: [String: String] {
        if let token = token() {
           return ["Authorization": "Bearer \(token ?? "")"]
        }
        return [:]
    }

    @AppBackgroundActor
    private func token() -> String? {
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

    @AppBackgroundActor
    private func getMetaData() async -> FileMetaData? {
        let metadata = await getMetaDataAsync()
        guard let fileMetadata = metadata?.data(using: .utf8) else { return nil }
        return try? JSONDecoder.instance.decode(FileMetaData.self, from: fileMetadata)
    }

    @AppBackgroundActor
    private func getHashCode() async -> String? {
        let parsedMetadata = await getMetaData()
        if let hashCode = parsedMetadata?.fileHash {
            return hashCode
        }
        if let oldHashCode = await getOldURLHash() {
            return oldHashCode
        }
        
        return await getHashByLastPath()
    }

    @AppBackgroundActor
    private func getOldURLHash() async -> String? {
        guard let url = await getURLHistoryActor(), let comp = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        return comp.queryItems?.first(where: { $0.name == "hash" })?.value
    }
    
    @AppBackgroundActor
    private func getHashByLastPath() async -> String? {
        guard let url = await getURL() else { return nil }
        let (images, files) = await getPaths()
        let isPodspaceFile = url.absoluteString.contains(images)
        let isPodspaceImage = url.absoluteString.contains(files)
        if isPodspaceFile || isPodspaceImage {
            return url.lastPathComponent
        }
        return nil
    }
    
    private func getPaths() -> (images: String, files: String) {
        let podspace = AppState.shared.spec.server.file
        let images = "\(podspace)\(AppState.shared.spec.paths.podspace.download.images)"
        let files = "\(podspace)\(AppState.shared.spec.paths.podspace.download.files)"
        return (images, files)
    }

    private func getCachedFileURL() async -> URL? {
        guard
            let url = getURL(),
            let cachedURL = await fileURLOnChatActor(url)
        else { return nil }
        return cachedURL
    }
   
    @ChatGlobalActor
    private func fileURLOnChatActor(_ url: URL) -> URL? {
        guard let fileManager = ChatManager.activeInstance?.file else { return nil }
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
    
    @AppBackgroundActor
    private func getURLHistoryActor() async -> URL? {
        URL(string: await config.url)
    }

    private nonisolated func isRealImage(_ data: Data) -> Bool {
        return UIImage(data: data) != nil
    }

    private func isPodURL() -> Bool {
        let url = getURL()
        let subDomains = AppState.shared.spec.subDomains
        return url?.host() == subDomains.core || url?.host() == subDomains.podspace
    }

    @AppBackgroundActor
    private func downloadRestImageFromPodURL() async {
        guard let url = await getURL() else { return }
        var request = URLRequest(url: url)
        await setUniqueId("\(request.hashValue)")
        let headers = headers
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        let response = try? await URLSession.shared.data(for: request)
        guard let data = response?.0 else { return }
        await update(data: data)
        await setUniqueId(nil)
        await storeInCache(data: data)
    }
    
    private func getMetaDataAsync() async -> String? {
        return config.metaData ?? fileMetadata
    }
    
    private func setUniqueId(_ uniqueId: String?) async {
        self.uniqueId = uniqueId
    }
}

extension ImageLoaderViewModel {
    convenience init(conversation: CalculatedConversation) {
        let httpsImage = conversation.image?.replacingOccurrences(of: "http://", with: "https://") ?? conversation.metaData?.file?.link ?? ""
        let name = conversation.computedTitle
        let config = ImageLoaderConfig(
            url: httpsImage,
            metaData: conversation.metadata,
            userName: String.splitedCharacter(name ?? ""),
            forceToDownloadFromServer: true
        )
        self.init(config: config)
    }
    
    convenience init(conversation: Conversation) {
        let httpsImage = conversation.image?.replacingOccurrences(of: "http://", with: "https://") ?? ""
        let name = conversation.computedTitle
        let config = ImageLoaderConfig(
            url: httpsImage,
            metaData: conversation.metadata,
            userName: String.splitedCharacter(name ?? ""),
            forceToDownloadFromServer: true
        )
        self.init(config: config)
    }
    
    convenience init(contact: Contact) {
        let image = contact.image ?? contact.user?.image ?? ""
        let httpsImage = image.replacingOccurrences(of: "http://", with: "https://")
        let contactName = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
        let isEmptyContactString = contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let name = !isEmptyContactString ? contactName : contact.user?.name
        let config = ImageLoaderConfig(url: httpsImage, userName: String.splitedCharacter(name ?? ""))
        self.init(config: config)
    }
}
