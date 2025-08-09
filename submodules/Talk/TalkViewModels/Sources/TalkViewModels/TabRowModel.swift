//
//  TabRowModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import Combine
import TalkModels
import SwiftUI

@MainActor
public final class TabRowModel: ObservableObject {
    public let message: Message
    public nonisolated let id: Int
    
    @Published public var shareDownloadedFile = false
    @Published public var state: MessageFileState = MessageFileState()
    @Published public var degree: Double = 0
    @Published public var fileName: String = ""
    @Published public var time: String = ""
    @Published public var fileSizeString: String = ""
    @Published public var showFullScreen = false
    @Published public var smallText: String? = nil
    @Published public var links: [String] = []
    @Published public var thumbnailImage: UIImage?
    @Published public var itemPlayer: AVAudioPlayerItem?
    
    private var cancellableSet = Set<AnyCancellable>()
    private var timer: Timer?
    public private(set) var playerVM: VideoPlayerViewModel?
    public private(set) var tempShareURL: URL?
    public private(set) var metadata: FileMetaData?
    public private(set) var fileURL: URL?
    
    private var manager: DownloadsManager { AppState.shared.objectsContainer.downloadsManager }
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    
    init(message: Message) async {
        self.message = message
        self.id = message.id ?? -1
        metadata = await metaData(message: message)
        fileURL = await message.fileURL
        fileName = metadata?.name ?? message.messageTitle
        time = message.time?.date.localFormattedTime ?? ""
        fileSizeString = metadata?.file?.size?.toSizeStringShort(locale: Language.preferredLocale) ?? ""
        
        /// Initial state by fetching the curretn element state.
        if let vm = manager.element(for: message.id ?? -1)?.viewModel {
            state.state = vm.state
            state.progress = CGFloat(CGFloat(vm.downloadPercent) / 100.0)
        }
        
        if await message.isFileExistOnDisk() {
            state.state = .completed
        }
        
        if message.type == .link {
            await calculateLinkText(message: message.message)
        }
        
        if state.state != .completed {
            registerNotifications(messageId: message.id ?? -1)
        }
       
        if let url = fileURL {
            let audioURL = AudioFileURLCalculator(fileURL: url, message: message).audioURL()
            let item = await MessageRowCalculators.calculatePlayerItem(audioURL, message.fileMetaData, message)
            self.itemPlayer = item
        }
    }
    
    public func onTap(viewModel: ThreadDetailViewModel) {
        Task {
            if message.isImage {
                showPictureInGallery(viewModel)
                return
            }
            if state.state != .completed {
                if state.state == .error {
                    manager.redownload(message: message)
                } else if state.state == .undefined {
                    /// Fake showing only downloading mode
                    state.state = .downloading
                    
                    /// It will be moved to download queue if it was free it will start real downlaod
                    manager.toggleDownloading(message: message)
                } else {
                    manager.toggleDownloading(message: message)
                }
            } else if state.state == .completed {
                if message.isVideo {
                    showFullScreenPlayer()
                } else if message.isAudio {
                    await playAudio(viewModel)
                } else {
                    await showShareFileSheet()
                }
            }
        }
    }
}

/// Identifiable
extension TabRowModel: Identifiable {}

/// Hashable
/// Notice: It is required if not it will lead to unexpected crashed in SwiftUI.
extension TabRowModel: Hashable {
    nonisolated public static func == (lhs: TabRowModel, rhs: TabRowModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Audio
extension TabRowModel {
    private func playAudio(_ viewModel: ThreadDetailViewModel) async {
        do {
            if let item = itemPlayer {
                try audioVM.setup(item: item, message: message)
                updateHistoryItemAndReload(viewModel, item)
            }
            audioVM.toggle()
        } catch {
            state.state = .error
        }
    }
    
    /// Update thread history audio to sync itself by reloading it with the new item player.
    private func updateHistoryItemAndReload(_ viewModel: ThreadDetailViewModel, _ item: AVAudioPlayerItem) {
        let historyVM = viewModel.threadVM?.historyVM
        if let tuple = historyVM?.sections.viewModelAndIndexPath(for: message.id ?? -1) {
            tuple.vm.calMessage.avPlayerItem = item
            
            /// Reloading message force it to call set method on MessageAudioView,
            /// and that will lead to call register and syncing audio
            historyVM?.reload(at: tuple.indexPath, vm: tuple.vm)
        }
    }
}

/// Video
extension TabRowModel {
    private func showFullScreenPlayer() {
        guard let fileURL = fileURL else { return }
        playerVM = VideoPlayerViewModel(fileURL: fileURL, ext: message.fileMetaData?.file?.mimeType?.ext)
        playerVM?.toggle()
        playerVM?.animateObjectWillChange()
        DispatchQueue.main.async { [weak self] in
            self?.showFullScreen = true
        }
    }
}

/// Files
extension TabRowModel {
    @AppBackgroundActor
    private func showShareFileSheet() async {
        _ = await message.makeTempURL()
        let tempURL = message.tempURL
        await MainActor.run {
            self.tempShareURL = tempURL
            shareDownloadedFile.toggle()
        }
    }
}

/// Links
extension TabRowModel {
    @AppBackgroundActor
    private func calculateLinkText(message: String?) async {
        var smallText = String(message?.replacingOccurrences(of: "\n", with: " ").prefix(500) ?? "")
        var links: [String] = []
        message?.links().forEach { link in
            links.append(link)
            /// Remove the link itself from the text message to prevent duplicate linked pirmary color.
            smallText = smallText.replacingOccurrences(of: link, with: "")
        }
        await MainActor.run { [links] in
            self.links = links
            self.smallText = smallText.isEmpty ? nil : smallText
        }
    }
}

/// Pictures
extension TabRowModel {
    private func showPictureInGallery(_ viewModel: ThreadDetailViewModel) {
        AppState.shared.objectsContainer.appOverlayVM.galleryMessage = .init(message: message, goToHistoryTapped: {
            /// Dismiss Detail View if it is showing
            viewModel.dismiss = true
        })
    }
    
    public func prepareThumbnail() async {
        if thumbnailImage == nil, let image = await ThumbnailDownloadManagerViewModel.get(message: message) {
            self.thumbnailImage = image
        }
    }
}

/// Common methods
extension TabRowModel {
    @AppBackgroundActor
    private func metaData(message: Message) -> FileMetaData? {
        message.fileMetaData
    }
    
    public var stateIcon: String {
        switch state.state {
        case .completed:
            if message.isVideo || message.isAudio {
                "play.fill"
            } else {
                message.iconName ?? "document"
            }
        case .downloading:
            "pause.fill"
        case .error:
            "exclamationmark"
        case .undefined, .started, .paused:
            "arrow.down"
        }
    }
}

/// Rotation animation timer
extension TabRowModel {
    private func startRotationTimer() {
        stopRotationTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation(.linear(duration: 2)) {
                    self?.degree += 360
                }
            }
        })
    }
    
    private func stopRotationTimer() {
        timer?.invalidate()
        timer = nil
    }
}

/// Move to the Message
extension TabRowModel {
    public func moveToMessage(_ detailVM: ThreadDetailViewModel) {
        Task {
            await detailVM.threadVM?.historyVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            detailVM.dismiss = true
        }
    }
}

/// Notification state change
extension TabRowModel {
    private func registerNotifications(messageId: Int) {
        NotificationCenter.default.publisher(for: .init("DOWNALOD_STATUS_\(messageId)"))
            .sink { [weak self] notif in
                Task { @MainActor [weak self] in
                    if let state = notif.object as? MessageFileState {
                        self?.onStateChange(state)
                    }
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func onStateChange(_ state: MessageFileState) {
        self.state = state
        if state.state == .completed || state.state == .paused || state.state == .error {
            stopRotationTimer()
        } else if timer == nil, state.state == .downloading {
            startRotationTimer()
        }
    }
}
