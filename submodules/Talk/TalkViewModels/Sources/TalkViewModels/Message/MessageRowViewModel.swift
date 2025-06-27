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

public final class MessageRowViewModel: Identifiable, Hashable, @unchecked Sendable {
    public static func == (lhs: MessageRowViewModel, rhs: MessageRowViewModel) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public let uniqueId: String = UUID().uuidString
    public var id: Int { message.id ?? -1 }
    public var message: HistoryMessageType
    @MainActor
    public var isInvalid = false

    @MainActor public var reactionsModel: ReactionRowsCalculated = .init(rows: [])
    public weak var threadVM: ThreadViewModel?

    public var calMessage = MessageRowCalculatedData()
    public private(set) var fileState: MessageFileState = .init()

    public init(message: HistoryMessageType, viewModel: ThreadViewModel) {
        self.message = message
        self.threadVM = viewModel
    }

    public func recalculateWithAnimation(mainData: MainRequirements) async {
        await recalculate(mainData: mainData)
    }
    
    @HistoryActor
    public func recalculate(appendMessages: [HistoryMessageType] = [], mainData: MainRequirements) async {
        calMessage = await MessageRowCalculators.calculate(message: message, mainData: mainData, appendMessages: appendMessages)
        calMessage = await MessageRowCalculators.calculateColorAndFileURL(mainData: mainData, message: message, calculatedMessage: calMessage)
        if calMessage.fileURL != nil {
            fileState.state = .completed
            fileState.showDownload = false
            fileState.iconState = message.iconName?.replacingOccurrences(of: ".circle", with: "") ?? ""
        }
    }
    
    @MainActor
    public func register() {
        if message is UploadProtocol {
            threadVM?.uploadFileManager.register(message: message, viewModelUniqueId: uniqueId)
        }
        if fileState.state != .completed {
            threadVM?.downloadFileManager.register(message: message)
        }
        
        if calMessage.isReplyImage && fileState.replyImage == nil {
            threadVM?.downloadFileManager.registerIfReplyImage(vm: self)
        }
    }

    @MainActor
    public func setFileState(_ state: MessageFileState, fileURL: URL?) {
        fileState.update(state)
        if state.state == .completed {
            calMessage.fileURL = fileURL
        }
    }
    
    nonisolated public func setFileStateNonIsloated(_ state: MessageFileState) {
        fileState = state
    }

    @MainActor
    public func setRelyImage(image: UIImage?) {
        fileState.replyImage = image
    }

    @MainActor
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
        if let url = message.neshanURL(basePath: AppState.shared.spec.server.neshan), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let mapLink = message.fileMetaData?.mapLink, let url = URL(string: mapLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @MainActor
    private func openImageViewer() {
        guard let message = message as? Message else { return }
        AppState.shared.objectsContainer.appOverlayVM.galleryMessage = .init(message: message)
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
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            isInvalid = false
            reactionsModel = .init()
        }
    }

    @HistoryActor
    func setReaction(reactions: ReactionCountList) async {        
        let reactionsModel = MessageRowCalculators.calulateReactions(reactions)
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            isInvalid = false
            self.reactionsModel = reactionsModel
        }
    }
    
    @MainActor
    func reactionDeleted(_ reaction: Reaction) {
        reactionsModel = MessageRowCalculators.reactionDeleted(reactionsModel, reaction, myId: AppState.shared.user?.id ?? -1)
    }
    
    @MainActor
    func reactionAdded(_ reaction: Reaction) {
        reactionsModel = MessageRowCalculators.reactionAdded(reactionsModel, reaction, myId: AppState.shared.user?.id ?? -1)
    }
    
    @MainActor
    func reactionReplaced(_ reaction: Reaction, oldSticker: Sticker) {
        reactionsModel = MessageRowCalculators.reactionReplaced(reactionsModel, reaction, myId: AppState.shared.user?.id ?? -1, oldSticker: oldSticker)
    }

    @MainActor
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
    @MainActor
    func getMainData() -> MainRequirements {
        return MainRequirements(appUserId: AppState.shared.user?.id,
                                thread: threadVM?.thread,
                                participantsColorVM: threadVM?.participantsColorVM,
                                isInSelectMode: threadVM?.selectedMessagesViewModel.isInSelectMode ?? false,
                                joinLink: AppState.shared.spec.paths.talk.join
        )
    }
}
//
//public extension MessageRowViewModel {
//    @MainActor
//    func copy() -> MessageRowViewModel? {
//        guard let threadVM = threadVM else { return nil }
//        let copyViewModel = MessageRowViewModel(message: message, viewModel: threadVM)
//        
//        /// TextStack should have a new copy for each TextView
//        copyViewModel.calMessage = calMessage
//        copyViewModel.fileState = fileState
//        copyViewModel.reactionsModel = reactionsModel
//        return copyViewModel
//    }
//}
