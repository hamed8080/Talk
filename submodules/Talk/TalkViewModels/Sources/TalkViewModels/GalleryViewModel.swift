import Foundation
import Chat
import Combine
import TalkModels
import SwiftUI

@MainActor
public class GalleryImageItemViewModel: ObservableObject, @preconcurrency Identifiable {
    public var id: Int { message.id ?? -1 }
    public let message: Message
    @Published public var image: UIImage?
    
    @Published public var percent: Int64 = 0
    @Published public var state: DownloadFileState = .undefined
    @Published public var fileURL: URL?
    private var uniqueId: String = ""
    private let DOWNLOAD_IMAGE_GALLERY_VIEW_KEY: String
    private var objectId = UUID().uuidString
    private var cancelable: AnyCancellable?
    public var isFetchingImage: Bool = false
    
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
            self.updateHistoryMessageImageView()
        }
    }
    
    /// Update MessageImageView row if the user open up the gallery and scroll to another image.
    private func updateHistoryMessageImageView() {
        guard
            let threadId = message.threadId ?? message.conversation?.id,
            let threadVM = AppState.shared.objectsContainer.navVM.viewModel(for: threadId),
            let messageId = message.id,
            let tuple = threadVM.historyVM.sections.viewModelAndIndexPath(for: messageId)
        else { return }
        Task { [weak self] in
            guard let self = self else { return }
            await tuple.vm.recalculate(mainData: threadVM.historyVM.getMainData())
            threadVM.historyVM.delegate?.reload(at: tuple.indexPath)
        }
    }
    
    public func getImage(scale: CGFloat) async -> UIImage? {
        if state == .completed {
            return await prepareImage(url: fileURL, scale: scale)
        }
        return nil
    }
    
    @AppBackgroundActor
    private func prepareImage(url: URL?, scale: CGFloat) async -> UIImage? {
        guard let url = url else { return nil }
        if scale == 1.0, let cgImage = url.imageScale(width: 1024)?.image {
            return UIImage(cgImage: cgImage)
        } else if let image = UIImage(contentsOfFile: url.path()) {
            return image
        } else {
            return nil
        }
    }
}

@MainActor
public final class GalleryViewModel: ObservableObject {
    public var starter: Message
    @Published public var pictures: ContiguousArray<GalleryImageItemViewModel> = []
    var thread: Conversation? { starter.conversation }
    var threadId: Int? { thread?.id ?? starter.threadId }
    private var cancelable: Set<AnyCancellable> = .init()
    @Published public var selectedTabId: Int?
    
    public init(message: Message) {
        self.starter = message
        selectedTabId = message.id
        loadStarterFileURL()
        Task {
            try await getLeftAndRightMessages(message: starter)
        }
        /// We will wait for 200 milliseconds to then send the request
        /// to the server to prvent the page stay in the middle
        /// while user was scrolling and we were appending at the same time at the end of the list.
        $selectedTabId
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    try? await self?.handleScrollFinished()
                }
            }
            .store(in: &cancelable)
    }
    
    private func loadStarterFileURL() {
        let vm = GalleryImageItemViewModel(message: starter)
        if !pictures.contains(where: { $0.id == starter.id }) {
            let vm = GalleryImageItemViewModel(message: starter)
            pictures.append(vm)
            downloadImage(item: vm)
        }
    }
    
    private func appendAndSort(_ newPictures: [Message]) {
        for newPicture in newPictures {
            if !pictures.contains(where: { $0.id == newPicture.id }) {
                let vm = GalleryImageItemViewModel(message: newPicture)
                pictures.append(vm)
            }
        }
        pictures.sort(by: { $0.message.time ?? 0 > $1.message.time ?? 0 })
    }
    
    private func getLeftAndRightMessages(message: Message) async throws {
        async let leftMessages = getPictureMessages(toTime: message.time?.advanced(by: 1)) // to get the message itself
        async let rightMessages = getPictureMessages(fromTime: message.time?.advanced(by: 1)) // to do not getting the message itself but get them in advance if user want to scroll to leading side
        let allMessages = (try await leftMessages) + (try await rightMessages)
        appendAndSort(allMessages)
    }
    
    private func getPictureMessages(count: Int = 15, fromTime: UInt? = nil, toTime: UInt? = nil) async throws -> [Message] {
        guard let threadId else { return [] }
        let req = GetHistoryRequest(threadId: threadId,
                                    count: count,
                                    fromTime: fromTime,
                                    messageType: ChatCore.MessageType.podSpacePicture.rawValue,
                                    order: toTime != nil ? "DESC" : "ASC",
                                    toTime: toTime
        )
        return try await GetHistoryReuqester(key: "").getMessages(req)
    }
    
    public func downloadImage(item: GalleryImageItemViewModel) {
        item.downloadImage()
    }
    
    public func onAppeared(item: GalleryImageItemViewModel) {
        downloadImage(item: item)
    }
    
    private func handleScrollFinished() async throws {
        guard let item = pictures.first(where: {$0.id == selectedTabId}) else { return }
        if pictures.first?.message.id == item.id {
            let leftMessages = try await getPictureMessages(fromTime: item.message.time)
            appendAndSort(leftMessages)
        } else if pictures.last?.message.id == item.id {
            let rightMessages = try await getPictureMessages(toTime: item.message.time)
            appendAndSort(rightMessages)
        }
    }
    
    public var selectedVM: GalleryImageItemViewModel? {
        pictures.first(where: {$0.id == selectedTabId})
    }
    
    public func saveAction(iconColor: Color, messageColor: Color) async throws {
        if let fileURL = selectedVM?.fileURL {
            try await SaveToAlbumViewModel(fileURL: fileURL).save()
        }
    }
    
    public func goToHistory() {
        let message = selectedVM?.message
        let vm = AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let time = message?.time, let id = message?.id {
                vm?.historyVM.cancelTasks()
                let task: Task<Void, any Error> = Task {
                    await vm?.historyVM.moveToTime(time, id)
                }
                vm?.historyVM.setTask(task)
            }
        }
    }
    
    deinit {
#if DEBUG
        print("GalleryViewModel deinit called")
#endif    
    }
}
