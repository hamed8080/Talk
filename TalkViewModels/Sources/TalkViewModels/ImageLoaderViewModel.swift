//
//  ImageLoaderViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation
import UIKit
import ChatModels
import TalkModels
import ChatDTO
import ChatCore
import TalkExtensions
import Combine
import ChatTransceiver

private var token: String? {
    guard let data = UserDefaults.standard.data(forKey: TokenManager.ssoTokenKey),
          let ssoToken = try? JSONDecoder().decode(SSOTokenResponse.self, from: data)
    else {
        return nil
    }
    return ssoToken.accessToken
}

public final class ImageLoaderViewModel: ObservableObject {
    @Published public private(set) var image: UIImage = .init()
    private(set) var url: String?
    private(set) var fileMetadata: String?
    private(set) var size: ImageSize?
    private(set) var userName: String?
    public private(set) var cancelable: Set<AnyCancellable> = []
    var uniqueId: String = ""

    private var URLObject: URL? { URL(string: url ?? "") }
    private var isSDKImage: Bool { hashCode != "" }
    private var fileMetadataModel: FileMetaData? {
        guard let fileMetadata = fileMetadata?.data(using: .utf8) else { return nil }
        return try? JSONDecoder.instance.decode(FileMetaData.self, from: fileMetadata)
    }
    private var fileURL: URL? {
        guard let URLObject = URLObject else { return nil }
        let chat = ChatManager.activeInstance
        if chat?.file.isFileExist(URLObject) == true {
            return chat?.file.filePath(URLObject)
        } else if chat?.file.isFileExistInGroup(URLObject) == true {
            return chat?.file.filePathInGroup(URLObject)
        }
        return nil
    }

    var fileServerURL: URL? {
        guard let fileServer = ChatManager.activeInstance?.config.fileServer else { return nil }
        return URL(string: fileServer)
    }

    private var oldURLHash: String? {
        guard let urlObject = URLObject, let comp = URLComponents(url: urlObject, resolvingAgainstBaseURL: true) else { return nil }
        return comp.queryItems?.first(where: { $0.name == "hash" })?.value
    }

    private var hashCode: String { fileMetadataModel?.fileHash ?? oldURLHash ?? "" }

    public init() {
        NotificationCenter.default.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink{ [weak self] event in
                DispatchQueue.global().async {
                    self?.onDownloadEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) {
        switch event {
        case .image(let chatResponse, let url):
            onGetImage(chatResponse, url)
        default:
            break
        }
    }

    public var isImageReady: Bool {
        image.size.width > 0
    }

    private func setImage(data: Data) {
        autoreleasepool {
            var image: UIImage? = nil
            if size == nil || size == .ACTUAL {
                image = UIImage(data: data) ?? UIImage()
            } else {
                guard let cgImage = data.imageScale(width: size == .SMALL ? 128 : 256)?.image else { return }
                image = UIImage(cgImage: cgImage)
            }

            DispatchQueue.main.async { [weak self] in
                guard let image = image else { return }
                self?.image = image
            }
        }
    }

    private func setImage(fileURL: URL) {
        autoreleasepool {
            var image: UIImage? = nil
            if size == nil || size == .ACTUAL, let data = fileURL.data {
                image = UIImage(data: data) ?? UIImage()
            } else {
                guard let cgImage = fileURL.imageScale(width: size == .SMALL ? 128 : 256)?.image else { return }
                image = UIImage(cgImage: cgImage)
            }
            DispatchQueue.main.async { [weak self] in
                guard let image = image else { return }
                self?.image = image
            }
        }
    }

    /// The hashCode decode FileMetaData so it needs to be done on the background thread.
    public func fetch(url: String? = nil, metaData: String? = nil, userName: String? = nil, size: ImageSize = .SMALL, forceToDownloadFromServer: Bool = false, thumbnail: Bool = false) {
        Task {
            fileMetadata = metaData
            self.url = url
            self.userName = userName
            self.size = size
            if url == nil {
                animateObjectWillChange()
                return
            }
            if isSDKImage {
                getFromSDK(forceToDownloadFromServer: forceToDownloadFromServer, thumbnail: thumbnail)
            } else if let fileURL = fileURL {
                setImage(fileURL: fileURL)
            } else {
                downloadFromAnyURL(thumbnail: thumbnail)
            }
        }
    }

    private func getFromSDK(forceToDownloadFromServer: Bool = false, thumbnail: Bool) {
        let req = ImageRequest(hashCode: hashCode, forceToDownloadFromServer: forceToDownloadFromServer, size: size ?? .LARG, thumbnail: thumbnail)
        uniqueId = req.uniqueId
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.file.get(req)
    }

    private func onGetImage(_ response: ChatResponse<Data>, _ url: URL?) {
        guard response.uniqueId == uniqueId, RequestsManager.shared.value(for: uniqueId) != nil else { return }
        if response.uniqueId == uniqueId, response.cache == false, let data = response.result {
            update(data: data)
            storeInCache(data: data) // For retrieving Widgetkit images with the help of the app group.
        } else {
            guard let url = url else { return }
            setImage(fileURL: url)
        }
    }

    private func downloadFromAnyURL(thumbnail: Bool) {
        guard let req = reqWithHeader else { return }
        let task = URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            self?.update(data: data)
            if !thumbnail {
                self?.storeInCache(data: data)
            }
        }
        task.resume()
    }

    private func update(data: Data?) {
        guard let data = data else { return }
        if !isRealImage(data: data) { return }
        setImage(data: data)
    }

    private func storeInCache(data: Data?) {
        guard let data = data else { return }
        if !isRealImage(data: data) { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let url = URL(string: self.url ?? "") else { return }
            ChatManager.activeInstance?.file.saveFileInGroup(url: url, data: data) { _ in }
        }
    }

    /// Check if the response is not a string.
    private func isRealImage(data: Data) -> Bool {
        UIImage(data: data) != nil
    }

    private var headers: [String: String] { token != nil ? ["Authorization": "Bearer \(token ?? "")"] : [:] }

    private var reqWithHeader: URLRequest? {
        guard let URLObject else { return nil }
        let req = URLRequest(url: URLObject)
        uniqueId = "\(req.hashValue)"
        var request = URLRequest(url: URLObject)
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
}
