import AVFoundation
import Chat
import Combine
import Foundation
import Logger
import SwiftUI

@MainActor
public final class AVAudioPlayerViewModel: NSObject, ObservableObject, @preconcurrency AVAudioPlayerDelegate {
    @Published public var player: AVAudioPlayer?
    public var message: Message?
    public var item: AVAudioPlayerItem?
    private var displayLink: CADisplayLink?
    
    public override init() {}

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
            Logger.log(
                title: "AVAudioPlayerViewModel", message: error.description)
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
    }

    public func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        item?.isPlaying = false
        item?.currentTime = item?.duration ?? 0
        stopDisplayLink()
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
}
