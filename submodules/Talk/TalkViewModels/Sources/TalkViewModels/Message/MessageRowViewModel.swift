//
//  MessageRowViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 3/9/23.
//

import Chat
import SwiftUI
import TalkModels
import Logger

@MainActor
public final class MessageRowViewModel: @preconcurrency Identifiable, @preconcurrency Hashable, @unchecked Sendable {
    public static func == (lhs: MessageRowViewModel, rhs: MessageRowViewModel) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public let uniqueId: String = UUID().uuidString
    public var id: Int { message.id ?? -1 }
    public var message: HistoryMessageType
    public var isInvalid = false

    public var reactionsModel: ReactionRowsCalculated
    public weak var threadVM: ThreadViewModel?

    public var calMessage = MessageRowCalculatedData()
    public private(set) var fileState: MessageFileState = .init()
    public var uploadElementUniqueId: String?

    public init(message: HistoryMessageType, viewModel: ThreadViewModel) {
        self.reactionsModel = .init(messageId: message.id ?? -1, rows: [])
        self.message = message
        self.threadVM = viewModel
    }

    public func recalculateWithAnimation(mainData: MainRequirements) async {
        await recalculate(mainData: mainData)
    }
    
    @AppBackgroundActor
    public func recalculate(appendMessages: [HistoryMessageType] = [], mainData: MainRequirements) async {
        var calMessage = await MessageRowCalculators.calculate(message: message, mainData: mainData, appendMessages: appendMessages)
        calMessage = await MessageRowCalculators.calculateColorAndFileURL(mainData: mainData, message: message, calculatedMessage: calMessage)
        
        var fileState = await fileState
        if calMessage.fileURL != nil {
            fileState.state = .completed
            fileState.showDownload = false
            fileState.iconState = await message.iconName ?? ""
        }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.calMessage = calMessage
            self.fileState = fileState
        }
    }
    
    public func setFileState(_ state: MessageFileState, fileURL: URL?) {
        fileState.update(state)
        if state.state == .completed, let fileURL = fileURL {
            calMessage.fileURL = fileURL
        }
    }

    public func setRelyImage(image: UIImage?) {
        fileState.replyImage = image
    }

    func invalid() {
        isInvalid = true
    }

    deinit {
        let string = "Deinit get called for message: \(self.message.message ?? "") and message isFileTye:\(self.message.isFileType) and id is: \(self.message.id ?? 0)"
        Logger.log( title: "MessageRowViewModel", message: string, persist: false)
    }
}

// MARK: Upload Completion
public extension MessageRowViewModel {
    func swapUploadMessageWith(_ message: HistoryMessageType) {
        self.message = message
        Task { [weak self] in
            guard let self = self else { return }
            calMessage.fileURL = await message.fileURL
        }
    }
}

// MARK: Tap actions
public extension MessageRowViewModel {
    
    func onTap(sourceView: UIView? = nil) {
        if fileState.state == .completed {
            doAction(sourceView: sourceView)
        } else if message is UploadProtocol {
            cancelUpload()
        } else {
            manageDownload()
        }
    }

    private func manageDownload() {
        guard let message = message as? Message else { return }
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let manager = AppState.shared.objectsContainer.downloadsManager
                if let element = manager.element(for: message.id ?? -1), element.viewModel.state == .error {
                    manager.redownload(message: message)
                } else {
                    try manager.toggleDownloading(message: message)
                }
            } catch {
                if let error = error as? DownloadsManagerError, error == .duplicate {
                    Logger.log(title: "A duplicate download rejected for messageId: \(message.id ?? -1)")
                }
            }
        }
    }

    private func doAction(sourceView: UIView? = nil) {
        if calMessage.rowType.isMap {
            openMap()
        } else if calMessage.rowType.isImage {
            openImageViewer()
        } else if calMessage.rowType.isAudio {
            toggleAudio()
        } else {
            shareFile(sourceView: sourceView)
        }
    }

    private func shareFile(sourceView: UIView? = nil) {
        Task { [weak self] in
            guard let self = self else { return }
            _ = await message.makeTempURL()
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                threadVM?.delegate?.openShareFiles(urls: [message.tempURL], title: message.fileMetaData?.file?.originalName, sourceView: sourceView)
            }
        }
    }

    private func openMap() {
        if let url = message.neshanURL(basePath: AppState.shared.spec.server.neshan), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let mapLink = message.fileMetaData?.mapLink, let url = URL(string: mapLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func openImageViewer() {
        guard let message = message as? Message else { return }
        AppState.shared.objectsContainer.appOverlayVM.galleryMessage = .init(message: message)
    }

    func cancelUpload() {
        Task { [weak self] in
            guard let self = self, let uniqueId = uploadElementUniqueId else { return }
            if let element = AppState.shared.objectsContainer.uploadsManager.element(uniqueId: uniqueId) {
                AppState.shared.objectsContainer.uploadsManager.cancel(element: element, userCanceled: true)
            }
        }
    }
}

// MARK: Audio file
public extension MessageRowViewModel {
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    
    @MainActor
    private func toggleAudio() {
        if let item = calMessage.avPlayerItem {
            try? audioVM.setup(item: item, message: message as? Message)
            audioVM.toggle()
        }
    }
}

// MARK: Reaction
public extension MessageRowViewModel {

    func clearReactions() {
        isInvalid = false
        reactionsModel = .init(messageId: message.id ?? -1)
    }
    
    func setReactionRowsModel(model: ReactionRowsCalculated) {
        isInvalid = false
        self.reactionsModel = model
    }
    
    func reactionDeleted(_ reaction: Reaction) {
        reactionsModel = MessageRowCalculators.reactionDeleted(reactionsModel, reaction, myId: AppState.shared.user?.id ?? -1)
    }
    
    func reactionAdded(_ reaction: Reaction) {
        reactionsModel = MessageRowCalculators.reactionAdded(reactionsModel, reaction, myId: AppState.shared.user?.id ?? -1)
    }
    
    func reactionReplaced(_ reaction: Reaction, oldSticker: Sticker) {
        reactionsModel = MessageRowCalculators.reactionReplaced(reactionsModel, reaction, myId: AppState.shared.user?.id ?? -1, oldSticker: oldSticker)
    }

    func canReact() -> Bool {
        if calMessage.rowType.isSingleEmoji, calMessage.rowType.isBareSingleEmoji { return false }
        if threadVM?.thread.reactionStatus == .disable { return false }
        // Two weeks
        return Date().millisecondsSince1970 < Int64(message.time ?? 0) + (1_209_600_000)
    }
}

// MARK: Pin/UnPin Message
public extension MessageRowViewModel {
    func unpinMessage() {
        Task { [weak self] in
            guard let self = self else { return }
            message.pinned = false
            message.pinTime = nil
            let mainData = await getMainData()
            await recalculateWithAnimation(mainData: mainData)
        }
    }

    func pinMessage(time: UInt? ) {
        Task { [weak self] in
            guard let self = self else { return }
            message.pinned = true
            message.pinTime = time
            let mainData = await getMainData()
            await recalculateWithAnimation(mainData: mainData)
        }
    }
}

public extension MessageRowViewModel {    
    func getMainData() -> MainRequirements {
        return MainRequirements(appUserId: AppState.shared.user?.id,
                                thread: threadVM?.thread,
                                participantsColorVM: threadVM?.participantsColorVM,
                                isInSelectMode: threadVM?.selectedMessagesViewModel.isInSelectMode ?? false,
                                joinLink: AppState.shared.spec.paths.talk.join
        )
    }
}

public extension MessageRowViewModel {
    func downloadThumbnailImage() async -> UIImage? {
        guard calMessage.fileURL == nil, /// Check if it is already downloaded
              let message = message as? Message,
              let hashCode = calMessage.fileMetaData?.file?.hashCode ?? calMessage.fileMetaData?.hashCode
        else { return nil }
        let req = ImageRequest(hashCode: hashCode, quality: 0.5, size: .SMALL, thumbnail: true)
        let thumbnailImage = await ThumbnailDownloadManagerViewModel.get(message: message)
        fileState.preloadImage = thumbnailImage
        return thumbnailImage
    }
}

public extension MessageRowViewModel {
    func relaod() {
        if let indexPath = threadVM?.historyVM.sections.indexPath(for: self) {
            threadVM?.historyVM.delegate?.reload()
        }
    }
}

public extension MessageRowViewModel {
    
    func getReplyImage() async -> UIImage? {
        if fileState.replyImage != nil {
            return fileState.replyImage
        }
        
        let metadata = message.replyInfo?.metadata
        let threadId = message.threadId
        
        /// Fetch from disk or server
        let image = await getReplyImage(threadId: threadId, metadata: metadata)
        
        /// Store image in viewModel
        setRelyImage(image: image)
        return image
    }
    
    @AppBackgroundActor
    private func getReplyImage(threadId: Int?, metadata: String?) async -> UIImage? {
        /// Convert replyInfo to Message to calculate URL
        let replyMessage = Message(threadId: threadId, messageType: .podSpacePicture, metadata: metadata)
        
        /// Get url
        guard let url = await replyMessage.url else { return nil }
        
        /// Fetch from disk or server
        let req = ImageRequest(hashCode: replyMessage.fileHashCode, quality: 0.5, size: .SMALL, thumbnail: true)
        guard let data = await ThumbnailDownloadManagerViewModel().downloadThumbnail(req: req, url: url) else { return nil }
        return UIImage(data: data)
    }
}
