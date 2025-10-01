import AVFoundation
import Chat
import Combine
import Foundation
import Logger
import SwiftUI
import MediaPlayer

@MainActor
public final class AVAudioPlayerViewModel: NSObject, ObservableObject, @preconcurrency AVAudioPlayerDelegate {
    @Published public var player: AVAudioPlayer?
    public var message: Message?
    public var item: AVAudioPlayerItem?
    private var displayLink: CADisplayLink?
    private let appIcon = UIImage(named: "global_app_icon", in: .main, compatibleWith: nil)
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var albumArtImage: MPMediaItemArtwork?
    
    public override init() {
        super.init()
        setupCommander()
    }

    public func setup(item: AVAudioPlayerItem, message: Message? = nil, category: AVAudioSession.Category = .playback) throws {
        /// Pause the older player if it was playing
        if item.messageId != self.item?.messageId {
            pause()
        } else {
            /// Set isFinished is required to make UI appear again in the Thread itself,
            /// if it was finished before.
            item.isFinished = false
        }
        
        self.item = item
        self.message = message
        do {
            let audioData = try Data( contentsOf: item.fileURL, options: NSData.ReadingOptions.mappedIfSafe)
            try AVAudioSession.sharedInstance().setCategory(category)
            player = try AVAudioPlayer(data: audioData, fileTypeHint: item.ext)
            player?.enableRate = true
            player?.delegate = self
        } catch let error as NSError {
            item.failed = true
            Logger.log(title: "AVAudioPlayerViewModel", message: error.description)
            close()
            throw error
        }
        NotificationCenter.default.post(name: Notification.Name("SWAP_PLAYER"), object: item)
    }

    public func play() {
        startDisplayLink()
        item?.isFinished = false
        item?.isPlaying = true
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.currentTime = item?.currentTime ?? 0
        player?.play()
        Task { [weak self] in
            guard let self = self else { return }
            await setArtwork()
        }
        setupNowPlayingInfo()
    }
    
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        item?.isPlaying = false
        animateObjectWillChange()
    }
    
    @objc private func updatePlaybackTime() {
        guard let currentTime = player?.currentTime else { return }
        item?.currentTime = currentTime
        setupNowPlayingInfo()
    }

    public func pause() {
        try? AVAudioSession.sharedInstance().setActive(false)
        player?.pause()
        stopDisplayLink()
    }

    public func toggle() {
        if item?.isPlaying == false {
            play()
        } else {
            pause()
        }
    }

    public func close() {
        stopDisplayLink()
        item?.isFinished = true
        item?.currentTime = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    public func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        item?.isPlaying = false
        item?.currentTime = item?.duration ?? 0
        stopDisplayLink()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.onCloseTimer()
        }
    }
    
    /// A method to hide the UI with an animation, after it really showed the last second.
    private func onCloseTimer() {
        var transaction = Transaction(animation: .none)
        transaction.disablesAnimations = false
        withTransaction(transaction) {
            close()
        }
    }

    public func setPlaybackSpeed(_ speed: Float) {
        player?.rate = Float(speed)
    }

    public func seek(_ to: Double) {
        player?.currentTime = to * (item?.duration ?? 0)
    }
    
    func setupNowPlayingInfo() {
        guard let player = player, let item = item else { return }
        let isSameTitleAndSubtitle = item.title == item.subtitle
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyPlaybackDuration: item.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying == true ? 1.0 : 0.0
        ]
        
        if !isSameTitleAndSubtitle {
            nowPlayingInfo[MPMediaItemPropertyArtist] = item.artistName ?? item.subtitle ?? ""
        }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = albumArtImage
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    @MainActor
    private func setArtwork() async {
        if let artworkData = try? await item?.artworkMetadata?.load(.dataValue), let image = UIImage(data: artworkData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { @Sendable _ in
                return image
            }
            albumArtImage = artwork
        } else if let appIcon = appIcon {
            let artwork = MPMediaItemArtwork(boundsSize: appIcon.size) { @Sendable _ in
                return appIcon
            }
            albumArtImage = artwork
        }
    }
    
    private func setupCommander() {
        /// We need to implement next/ previous.
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        /// If we don't use these callbacks nowplaying won't show on the screen.
        commandCenter.playCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] notif -> MPRemoteCommandHandlerStatus in
            if let time = (notif as? MPChangePlaybackPositionCommandEvent)?.positionTime {
                self?.player?.currentTime = time
            }
            return .success
        }
    }
}
