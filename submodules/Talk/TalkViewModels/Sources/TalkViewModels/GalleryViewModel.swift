import Foundation
import Chat
import Combine
import TalkModels
import SwiftUI

@MainActor
public class GalleryImageItemViewModel: ObservableObject, @preconcurrency Identifiable {
    public var id: Int { message.id ?? -1 }
    public let message: Message
    
    @Published public var percent: Int64 = 0
    @Published public var state: DownloadFileState = .undefined
    @Published public var fileURL: URL?
    private var uniqueId: String = ""
    private let DOWNLOAD_IMAGE_GALLERY_VIEW_KEY: String
    private var objectId = UUID().uuidString
    private var cancelable: AnyCancellable?
    
    public init(message: Message) {
        self.message = message
        DOWNLOAD_IMAGE_GALLERY_VIEW_KEY = "DOWNLOAD-IMAGE-GALLERY-VIEW-\(objectId)"
        cancelable = NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] value in
                self?.onDownloadEvent(value)
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
    
    public func downloadImage() {
        if state == .completed { return }
        guard let hashCode = message.fileMetaData?.file?.hashCode else { return }
        let req = ImageRequest(hashCode: hashCode, size: .ACTUAL)
        self.uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: DOWNLOAD_IMAGE_GALLERY_VIEW_KEY, value: req)
        Task { @ChatGlobalActor in
            await ChatManager.activeInstance?.file.get(req)
        }
    }
    
    private func onProgress(_ uniqueId: String, _ progress: DownloadFileProgress?) {
        if uniqueId == self.uniqueId, let progress = progress {
            state = .downloading
            percent = progress.percent
        }
    }
    
    private func onImage(_ response: ChatResponse<Data>, _ fileURL: URL?) {
        if let data = response.result, let request = response.pop(prepend: DOWNLOAD_IMAGE_GALLERY_VIEW_KEY) as? ImageRequest {
            state = .completed
            self.fileURL = fileURL
            /// Send a notification to update a message if it's exist when the user back to the messages page.
            NotificationCenter.galleryDownload.post(name: .galleryDownload, object: (request, data))
        }
    }
    
    public func getImage() async -> UIImage? {
        if state == .completed {
            return await prepareImage(url: fileURL)
        }
        return nil
    }
    
    @AppBackgroundActor
    private func prepareImage(url: URL?) async -> UIImage? {
        if let url = url, let image = UIImage(contentsOfFile: url.path()) {
            return image
        }
        return nil
    }
}

@MainActor
public final class GalleryViewModel: ObservableObject {
    public var starter: Message
    @Published public var pictures: ContiguousArray<GalleryImageItemViewModel> = []
    var thread: Conversation? { starter.conversation }
    var threadId: Int? { thread?.id ?? starter.threadId }
    private var cancelable: Set<AnyCancellable> = .init()
    private var objectId = UUID().uuidString
    private let FETCH_GALLERY_MESSAGES_KEY: String
    @Published public var selectedTabId: Int?
    
    public init(message: Message) {
        FETCH_GALLERY_MESSAGES_KEY = "FETCH-GALLERY-MESSAGES-KEY-\(objectId)"
        self.starter = message
        selectedTabId = message.id
        loadStarterFileURL()
        getPictureMessages(toTime: message.time?.advanced(by: 1)) // to get the message itself
        getPictureMessages(fromTime: message.time?.advanced(by: 1)) // to do not getting the message itself but get them in advance if user want to scroll to leading side
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] value in
                self?.onMessageEvent(value)
            }
            .store(in: &cancelable)
        /// We will wait for 200 milliseconds to then send the request
        /// to the server to prvent the page stay in the middle
        /// while user was scrolling and we were appending at the same time at the end of the list.
        $selectedTabId
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleScrollFinished()
            }
            .store(in: &cancelable)
    }
    
    private func loadStarterFileURL() {
        let vm = GalleryImageItemViewModel(message: starter)
        if !pictures.contains(where: { $0.id == starter.id }) {
            let vm = GalleryImageItemViewModel(message: starter)
            pictures.append(vm)
        }
    }
    
    private func onMessageEvent(_ event: MessageEventTypes){
        switch event {
        case .history(let chatResponse):
            onMessages(chatResponse)
        default:
            break
        }
    }
    
    private func onMessages(_ response: ChatResponse<[Message]>) {
        if response.pop(prepend: FETCH_GALLERY_MESSAGES_KEY) == nil { return }
        let newPictures = response.result ?? []
        for newPicture in newPictures {
            if !pictures.contains(where: { $0.id == newPicture.id }) {
                let vm = GalleryImageItemViewModel(message: newPicture)
                pictures.append(vm)
            }
        }
        pictures.sort(by: { $0.message.time ?? 0 > $1.message.time ?? 0 })
    }
    
    private func getPictureMessages(count: Int = 15, fromTime: UInt? = nil, toTime: UInt? = nil) {
        guard let threadId else { return }
        let req = GetHistoryRequest(threadId: threadId,
                                    count: count,
                                    fromTime: fromTime,
                                    messageType: ChatCore.MessageType.podSpacePicture.rawValue,
                                    order: toTime != nil ? "DESC" : "ASC",
                                    toTime: toTime
        )
        RequestsManager.shared.append(prepend: FETCH_GALLERY_MESSAGES_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.history(req)
        }
    }
    
    public func downloadImage(item: GalleryImageItemViewModel) {
        item.downloadImage()
    }
    
    public func onAppeared(item: GalleryImageItemViewModel) {
        downloadImage(item: item)
    }
    
    private func handleScrollFinished() {
        guard let item = pictures.first(where: {$0.id == selectedTabId}) else { return }
        if pictures.first?.message.id == item.id {
            getPictureMessages(fromTime: item.message.time)
        } else if pictures.last?.message.id == item.id {
            getPictureMessages(toTime: item.message.time)
        }
    }
    
    public var selectedVM: GalleryImageItemViewModel? {
        pictures.first(where: {$0.id == selectedTabId})
    }
    
    public func saveAction(iconColor: Color, messageColor: Color) {
        Task {
            if let fileURL = selectedVM?.fileURL,
               let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                let icon = Image(systemName: "externaldrive.badge.checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(iconColor)
                AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.imageSaved", messageColor: messageColor)
            }
        }
    }
    
    public func goToHistory() {
        let message = selectedVM?.message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let time = message?.time, let id = message?.id {
                Task {
                    await AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel.historyVM.moveToTime(time, id)
                }
            }
        }
    }
    
#if DEBUG
    deinit {
        print("GalleryViewModel deinit called")
    }
#endif    
}
