//
//  ThreadPinMessageViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatModels
import UIKit
import ChatDTO
import Chat
import Combine
import SwiftUI
import ChatCore
import TalkModels

public protocol ThreadPinMessageViewModelDelegate: AnyObject {
    func onUpdate()
}

public final class ThreadPinMessageViewModel: ObservableObject {
    private weak var viewModel: ThreadViewModel?
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
    public weak var historyVM: ThreadHistoryViewModel?
    public weak var delegate: ThreadPinMessageViewModelDelegate?

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
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
                delegate?.onUpdate()
            }
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case let .pin(response):
            if threadId == response.subjectId {
                thread.pinMessage = response.result
                message = response.result
                downloadImageThumbnail()
                Task { [weak self] in
                    guard let self = self else { return }
                    await calculate()
                }
            }
        case let .unpin(response):
            if threadId == response.subjectId {
                thread.pinMessage = nil
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

    public func calculate() async {
        let hasPinMessage = message != nil
        let isFileType = fileMetadata != nil
        let icon = fileMetadata?.file?.mimeType?.systemImageNameForFileExtension
        let isEnglish = isFileType && Language.isRTL ? false : message?.text?.naturalTextAlignment == .leading
        let title = messageText
        let canUnpinMessage = thread.admin == true
        await MainActor.run {
            self.hasPinMessage = hasPinMessage
            self.icon = icon
            self.isEnglish = isEnglish
            self.title = title
            self.canUnpinMessage = canUnpinMessage
            delegate?.onUpdate()
        }
    }

    private var messageText: String {
        if let text = message?.text, !text.isEmpty {
            return text.prefix(150).replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let fileName = fileMetadata?.name {
            return fileName
        } else {
            return ""
        }
    }

    var fileMetadata: FileMetaData? {
        guard let metdataData = message?.metadata?.data(using: .utf8),
              let file = try? JSONDecoder.instance.decode(FileMetaData.self, from: metdataData)
        else { return nil }
        return file
    }

    /// We use a Task due to fileMetadata decoding.
    public func downloadImageThumbnail() {
        Task { [weak self] in
            guard let self = self else { return }
            guard let file = fileMetadata,
                  let hashCode = file.file?.hashCode,
                  file.file?.mimeType == "image/jpeg" || file.file?.mimeType == "image/png"
            else {
                image = nil
                return
            }

            let req = ImageRequest(hashCode: hashCode, quality: 0.1, size: .SMALL, thumbnail: true)
            requestUniqueId = req.uniqueId
            ChatManager.activeInstance?.file.get(req)
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
        ChatManager.activeInstance?.message.pin(.init(messageId: messageId, notifyAll: notifyAll))
    }

    public func unpinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.unpin(.init(messageId: messageId))
    }

    public func moveToPinnedMessage() {
        if let time = message?.time, let messageId = message?.messageId {
            historyVM?.moveToTime(time, messageId)
        }
    }

    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
