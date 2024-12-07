import Foundation
import Chat
import Combine
import TalkModels
import SwiftUI

@MainActor
public final class GalleryViewModel: ObservableObject {
    public var starter: Message
    public var pictures: ContiguousArray<Message> = []
    public var isLoading: Bool = false
    var thread: Conversation? { starter.conversation }
    var threadId: Int? { thread?.id }
    public var currentImageMessage: Message?
    public var downloadedImages: [String: Data] = [:]
    public var percent: Int64 = 0
    public var state: DownloadFileState = .undefined
    private var cancelable: Set<AnyCancellable> = []
    private var objectId = UUID().uuidString
    private var uniqueId: String = ""
    private let FETCH_GALLERY_VIEW_KEY: String
    public var currentData: Data? {
        guard let hashCode = currentImageMessage?.fileMetaData?.fileHash else { return nil }
        return downloadedImages[hashCode]
    }

    public init(message: Message) {
        FETCH_GALLERY_VIEW_KEY = "FETCH-GALLERY-VIEW-\(objectId)"
        self.starter = message
        getPictureMessages()

        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] value in
                self?.onMessageEvent(value)
            }
            .store(in: &cancelable)

        NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] value in
                self?.onDownloadEvent(value)
            }
            .store(in: &cancelable)
    }

    private func onMessageEvent(_ event: MessageEventTypes){
        switch event {
        case .history(let chatResponse):
            onMessages(chatResponse)
        default:
            break
        }
    }

    private func onDownloadEvent(_ event: DownloadEventTypes){
        switch event {
        case .progress(let uniqueId, let progress):
            onProgress(uniqueId, progress)
        case .image(let response, let fileURL):
            onImage(response, fileURL)
        default:
            break
        }
    }

    private func onMessages(_ response: ChatResponse<[Message]>) {
        if self.pictures.count == 0 {
            fecthMoreLeadingMessages()
            fecthMoreTrailingMessages()
        }
        pictures.append(contentsOf: response.result ?? [])
    }

    private func onImage(_ response: ChatResponse<Data>, _ fileURL: URL?) {
        if let data = response.result, let request = response.pop(prepend: FETCH_GALLERY_VIEW_KEY) as? ImageRequest {
            state = .completed
            downloadedImages[request.hashCode] = data
            /// Send a notification to update the original.
            NotificationCenter.galleryDownload.post(name: .galleryDownload, object: (request, data))
        }

        isLoading = false
        animateObjectWillChange()
    }

    private func onProgress(_ uniqueId: String, _ progress: DownloadFileProgress?) {
        if uniqueId == self.uniqueId, let progress = progress {
            state = .downloading
            percent = progress.percent
            animateObjectWillChange()
        }
    }

    private func getPictureMessages(count: Int = 5, fromTime: UInt? = nil, toTime: UInt? = nil) {
        //        guard let threadId else { return }
        //        let req = GetHistoryRequest(threadId: threadId,
        //                                    count: count,
        //                                    fromTime: fromTime,
        //                                    messageType: ChatCore.MessageType.podSpacePicture.rawValue,
        //                                    toTime: toTime
        //        )
        //        RequestsManager.shared.append(value: req)
        //        ChatManager.activeInstance?.message.history(req)
    }

    public func fetchImage(message: Message? = nil) {
        currentImageMessage = message ?? starter
        isLoading = true
        animateObjectWillChange()
        guard let hashCode = currentImageMessage?.fileMetaData?.file?.hashCode else { return }
        let req = ImageRequest(hashCode: hashCode, size: .ACTUAL)
        self.uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: FETCH_GALLERY_VIEW_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.file.get(req)
        }
    }

    public func fecthMoreLeadingMessages() {
        getPictureMessages(toTime: currentImageMessage?.time)
    }

    public func fecthMoreTrailingMessages() {
        getPictureMessages(fromTime: currentImageMessage?.time)
    }

    public enum Swipe {
        case next
        case previous
    }

    public func swipeTo(_ swipe: Swipe) {
        guard let currentImageMessage = currentImageMessage,
              let currentIndex = pictures.firstIndex(of: currentImageMessage)
        else { return }
        let index = currentIndex.advanced(by: swipe == .next ? 1 : -1)
        if pictures.indices.contains(index) {
            self.currentImageMessage = pictures[index]
            fetchImage()
        }
    }
}
