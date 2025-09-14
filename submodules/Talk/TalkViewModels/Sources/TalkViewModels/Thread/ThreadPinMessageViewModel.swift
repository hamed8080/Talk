//
//  ThreadPinMessageViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import UIKit
import Chat
import Combine
import SwiftUI
import TalkModels

@MainActor
public final class ThreadPinMessageViewModel {
    private weak var viewModel: ThreadViewModel?
    public weak var historyVM: ThreadHistoryViewModel?
    public private(set) var text: String? = nil
    public private(set) var image: UIImage? = nil
    public private(set) var message: PinMessage?
    public private(set) var requestUniqueId: String?
    public private(set) var icon: String?
    public private(set) var isEnglish: Bool = true
    public private(set) var title: String = ""
    public private(set) var hasPinMessage: Bool = false
    public private(set) var canUnpinMessage: Bool = false
    private var thread: Conversation { viewModel?.thread ?? .init() }
    private var cancelable: Set<AnyCancellable> = []
    var threadId: Int {thread.id ?? -1}

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        self.historyVM = viewModel.historyVM
        message = thread.pinMessage
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] event in
                self?.onDownloadEvent(event)
            }
            .store(in: &cancelable)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) {
        switch event {
        case let .image(chatResponse, _):
            if requestUniqueId == chatResponse.uniqueId, let data = chatResponse.result {
                image = UIImage(data: data)
                viewModel?.delegate?.onUpdatePinMessage()
            }
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case let .pin(response):
            if threadId == response.subjectId {
                viewModel?.thread.pinMessage = response.result
                message = response.result
                downloadImageThumbnail()
                Task { [weak self] in
                    guard let self = self else { return }
                    await calculate()
                }
            }
        case let .unpin(response):
            if threadId == response.subjectId {
                viewModel?.thread.pinMessage = nil
                message = nil
                Task { [weak self] in
                    guard let self = self else { return }
                    await calculate()
                }
            }
        case .edited(let response):
            if response.result?.id == message?.id, let message = response.result {
                self.message = PinMessage(message: message)
                Task { [weak self] in
                    guard let self = self else { return }
                    await calculate()
                }
            }
        default:
            break
        }
    }

    @AppBackgroundActor
    public func calculate() async {
        let message = await message
        let hasPinMessage = message != nil
        let fileMetaData = await fileMetadata(metadataString: message?.metadata)
        let isFileType = fileMetaData != nil
        let icon = fileMetaData?.file?.mimeType?.systemImageNameForFileExtension
        let isEnglish = isFileType && Language.isRTL ? false : message?.text?.naturalTextAlignment == .leading
        let title = messageText(text: message?.text, fileName: fileMetaData?.name)
        let isAdmin = await viewModel?.thread.admin == true
        await MainActor.run {
            self.hasPinMessage = hasPinMessage
            self.icon = icon
            self.isEnglish = isEnglish
            self.title = title
            self.canUnpinMessage = hasPinMessage && isAdmin
            viewModel?.delegate?.onUpdatePinMessage()
        }
    }

    @AppBackgroundActor
    private func messageText(text: String?, fileName: String?) -> String {
        if let text = text, !text.isEmpty {
            let text = ThreadCalculators.removeMessageTextStyle(message: text)
            return text.prefix(150).replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let fileName = fileName {
            return fileName
        } else {
            return ""
        }
    }

    @AppBackgroundActor
    func fileMetadata(metadataString: String?) -> FileMetaData? {
        guard let metdataData = metadataString?.data(using: .utf8),
              let file = try? JSONDecoder.instance.decode(FileMetaData.self, from: metdataData)
        else { return nil }
        return file
    }

    /// We use a Task due to fileMetadata decoding.
    public func downloadImageThumbnail() {
        Task { [weak self] in
            guard let self = self else { return }
            guard let file = await fileMetadata(metadataString: message?.metadata),
                  let hashCode = file.file?.hashCode,
                  file.file?.mimeType == "image/jpeg" || file.file?.mimeType == "image/png"
            else {
                await MainActor.run { [weak self] in
                    self?.image = nil
                }
                return
            }
            
            if let scaledImage = await getScaledCachePinImage(hashCode: file.file?.hashCode) {
                image = scaledImage
                viewModel?.delegate?.onUpdatePinMessage()
            } else {
                let req = ImageRequest(hashCode: hashCode, quality: 0.1, size: .SMALL, thumbnail: true)
                requestUniqueId = req.uniqueId
                Task { @ChatGlobalActor in
                    ChatManager.activeInstance?.file.get(req)
                }
            }
        }
    }

    public func togglePinMessage(_ message: Message, notifyAll: Bool) {
        guard let messageId = message.id else { return }
        if message.pinned == false || message.pinned == nil {
            pinMessage(messageId, notifyAll: notifyAll)
        } else {
            unpinMessage(messageId)
        }
    }

    public func pinMessage(_ messageId: Int, notifyAll: Bool) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.pin(.init(messageId: messageId, notifyAll: notifyAll))
        }
    }

    public func unpinMessage(_ messageId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.unpin(.init(messageId: messageId))
        }
    }

    public func moveToPinnedMessage() {
        if let time = message?.time, let messageId = message?.messageId {
            Task { [weak self] in
                guard let self = self else { return }
                await historyVM?.moveToTime(time, messageId, highlight: true)
            }
        }
    }

    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
    
    private func getScaledCachePinImage(hashCode: String?) async -> UIImage? {
        guard let hashCode = hashCode,
              let fileURL = await getFileURL(hashCode: hashCode),
              let scaledImage = fileURL.imageScale(width: 24)?.image
        else { return nil }
        return UIImage(cgImage: scaledImage)
    }
    
    @ChatGlobalActor
    private func getFileURL(hashCode: String) -> URL? {
        guard
            let url = ChatManager.activeInstance?.file.hashCodeToImageURL(hashCode: hashCode),
            ChatManager.activeInstance?.file.isFileExist(url) == true
        else { return nil }
        let fileURL = ChatManager.activeInstance?.file.filePath(url)
        return fileURL
    }
}
