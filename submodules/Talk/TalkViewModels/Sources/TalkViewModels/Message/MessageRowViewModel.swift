//
//  MessageRowViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 3/9/23.
//

import Chat
import SwiftUI
import TalkModels
import OSLog

public final class MessageRowViewModel: Identifiable, Hashable, @unchecked Sendable {
    public static func == (lhs: MessageRowViewModel, rhs: MessageRowViewModel) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public let uniqueId: String = UUID().uuidString
    public var id: Int { message.id ?? -1 }
    public var message: any HistoryMessageProtocol
    public var isInvalid = false

    @MainActor public var reactionsModel: ReactionRowsCalculated = .init(rows: [], topPadding: 0)
    public weak var threadVM: ThreadViewModel?

    public var calMessage = MessageRowCalculatedData()
    public private(set) var fileState: MessageFileState = .init()

    public init(message: any HistoryMessageProtocol, viewModel: ThreadViewModel) {
        self.message = message
        self.threadVM = viewModel
    }

    public func recalculateWithAnimation() async {
        await performaCalculation()
    }

    @AppBackgroundActor
    public func performaCalculation(appendMessages: [any HistoryMessageProtocol] = []) async {
        let mainData = await getMainData()
        calMessage = await MessageRowCalculators.calculate(message: message, mainData: mainData, appendMessages: appendMessages)
        if calMessage.fileURL != nil {
            fileState.state = .completed
            fileState.showDownload = false
            fileState.iconState = message.iconName?.replacingOccurrences(of: ".circle", with: "") ?? ""
        }
    }

    @MainActor
    public func register() async {
        if message is UploadProtocol {
            threadVM?.uploadFileManager.register(message: message, viewModelUniqueId: uniqueId)
        }
        if fileState.state != .completed {
            threadVM?.downloadFileManager.register(message: message)
        }
        
        if calMessage.isReplyImage && fileState.replyImage == nil {
            await threadVM?.downloadFileManager.registerIfReplyImage(vm: self)
        }
    }

    @MainActor
    public func setFileState(_ state: MessageFileState, fileURL: URL?) {
        fileState.update(state)
        if state.state == .completed {
            calMessage.fileURL = fileURL
        }
    }

    @MainActor
    public func setRelyImage(image: UIImage?) {
        fileState.replyImage = image
    }

    func invalid() {
        isInvalid = true
    }

    deinit {
#if DEBUG
        Logger.viewModels.info("Deinit get called for message: \(self.message.message ?? "") and message isFileTye:\(self.message.isFileType) and id is: \(self.message.id ?? 0)")
#endif
    }
}

// MARK: Prepare download managers
public extension MessageRowViewModel {
    func prepareForTumbnailIfNeeded() {
        if fileState.state != .completed && fileState.state != .thumbnail {
            manageDownload() // Start downloading thumbnail for the first time
        }
    }

    func downloadMap() {
        if calMessage.rowType.isMap && fileState.state != .completed {
            manageDownload() // Start downloading thumbnail for the first time
        }
    }
}

// MARK: Upload Completion
public extension MessageRowViewModel {
    func swapUploadMessageWith(_ message: any HistoryMessageProtocol) {
        self.message = message
        Task {
            calMessage.fileURL = await message.fileURL
        }
    }
}

// MARK: Tap actions
public extension MessageRowViewModel {
    
    @MainActor
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
        if let messageId = message.id {
            Task { [weak self] in
                guard let self = self else { return }
                await threadVM?.downloadFileManager.manageDownload(messageId: messageId, isImage: calMessage.rowType.isImage, isMap: calMessage.rowType.isMap)
            }
        }
    }

    @MainActor
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

    @MainActor
    private func openMap() {
        if let url = message.neshanURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @MainActor
    private func openImageViewer() {
        AppState.shared.objectsContainer.appOverlayVM.galleryMessage = message as? Message
    }

    func cancelUpload() {
        Task { [weak self] in
            guard let self = self else { return }
            await threadVM?.uploadFileManager.cancel(viewModelUniqueId: uniqueId)
        }
    }
}

// MARK: Audio file
public extension MessageRowViewModel {
    @MainActor
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }

    @MainActor
    private var isSameAudioFile: Bool {
        if audioVM.fileURL == nil { return true } // It means it has never played a audio.
        guard let fileURL = calMessage.fileURL else { return false }
        return audioVM.fileURL?.absoluteString == fileURL.absoluteString
    }

    @MainActor
    private func toggleAudio() {
        if isSameAudioFile {
            togglePlaying()
        } else {
            audioVM.close()
            togglePlaying()
        }
    }

    @MainActor
    private func togglePlaying() {
        if let fileURL = calMessage.fileURL {
            let convrtedURL = message.convertedFileURL
            let convertedExist = FileManager.default.fileExists(atPath: convrtedURL?.path() ?? "")
            let mtd = calMessage.fileMetaData
            do {
                try audioVM.setup(message: message as? Message,
                                  fileURL: (convertedExist ? convrtedURL : fileURL) ?? fileURL,
                                  ext: convertedExist ? "mp4" : mtd?.file?.mimeType?.ext,
                                  title: mtd?.file?.originalName ?? mtd?.name ?? "",
                                  subtitle: mtd?.file?.originalName ?? "")
                audioVM.toggle()
            } catch {}
        }
    }
}

// MARK: Reaction
public extension MessageRowViewModel {

    @HistoryActor
    func clearReactions() async {
        isInvalid = false
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            reactionsModel = .init()
        }
    }

    @HistoryActor
    func setReaction(reactions: ReactionInMemoryCopy) async {
        isInvalid = false
        let reactionsModel = await MessageRowCalculators.calulateReactions(reactions: reactions)
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.reactionsModel = reactionsModel
        }
    }

    func canReact() async -> Bool {
        if await threadVM?.thread.reactionStatus == .disable { return false }
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
            await recalculateWithAnimation()
        }
    }

    func pinMessage(time: UInt? ) {
        Task { [weak self] in
            guard let self = self else { return }
            message.pinned = true
            message.pinTime = time
            await recalculateWithAnimation()
        }
    }
}

extension MessageRowViewModel {
    
    @MainActor
    func getMainData() async -> MainRequirements {
        return MainRequirements(appUserId: AppState.shared.user?.id,
                                thread: threadVM?.thread,
                                participantsColorVM: threadVM?.participantsColorVM,
                                isInSelectMode: threadVM?.selectedMessagesViewModel.isInSelectMode ?? false)
    }
}
