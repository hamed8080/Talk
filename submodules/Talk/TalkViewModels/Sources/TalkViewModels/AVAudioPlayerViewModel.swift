import Combine
import Foundation
import AVFoundation
import OSLog
import SwiftUI
import Chat

#if canImport(MobileVLCKit)
import MobileVLCKit
#endif

public final class AVAudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published public var isPlaying: Bool = false
    @Published public var isClosed: Bool = true
    @Published public var player: AVAudioPlayer?
    @Published public var title: String = ""
    public var subtitle: String = ""
    @Published public var duration: Double = 0
    @Published public var currentTime: Double = 0
    public var fileURL: URL?
    public var message: Message?
    @Published public var failed: Bool = false
    private var isVLC = false

#if canImport(MobileVLCKit)
    private let vlcPlayer = VLCMediaPlayer()
#endif

    private var timer: Timer?
    public override init() {}

    public func setup(message: Message? = nil, fileURL: URL, ext: String?, category: AVAudioSession.Category = .playback, title: String? = nil, subtitle: String = "") throws {
        self.message = message
        self.title = title ?? fileURL.lastPathComponent
        self.subtitle = subtitle
        self.fileURL = fileURL
        self.currentTime = 0
        isVLC = false
        do {
            let audioData = try Data(contentsOf: fileURL, options: NSData.ReadingOptions.mappedIfSafe)
            try AVAudioSession.sharedInstance().setCategory(category)
            player = try AVAudioPlayer(data: audioData, fileTypeHint: ext)
            player?.delegate = self
            duration = player?.duration ?? 0
        } catch let error as NSError {
            failed = true
#if DEBUG
            Logger.viewModels.info("\(error.description)")
#endif
            close()
            throw error
        }
    }

    public func setupWithVLC(message: Message? = nil, fileURL: URL, ext: String?, category: AVAudioSession.Category = .playback, title: String? = nil, subtitle: String = "") {
        self.message = message
        self.title = title ?? fileURL.lastPathComponent
        self.subtitle = subtitle
        self.fileURL = fileURL
    }

    public func play() {
        if isVLC { return }
        isClosed = false
        isPlaying = true
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.prepareToPlay()
        player?.play()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let transaction = Transaction(animation: .easeInOut)
            withTransaction(transaction) {
                if self?.duration != self?.currentTime {
                    self?.currentTime = self?.player?.currentTime ?? 0
                    self?.duration = self?.player?.duration ?? 0
                }
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    public func pause() {
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false)
        player?.pause()
#if canImport(MobileVLCKit)
        vlcPlayer.pause()
#endif
        stopTimer()
    }

    public func toggle() {
        if !isPlaying {
            play()
        } else {
            pause()
        }
    }

    public func close() {
        stopTimer()
        isClosed = true
        currentTime = 0
#if canImport(MobileVLCKit)
        vlcPlayer.stop()
#endif
        pause()
        fileURL = nil
    }

    public func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        currentTime = duration
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            var transaction = Transaction(animation: .none)
            transaction.disablesAnimations = false
            withTransaction(transaction) {
                self?.isPlaying = false
                self?.currentTime = self?.duration ?? 0
                self?.close()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        isVLC = false
#if canImport(MobileVLCKit)
        vlcPlayer.stop()
#endif
        animateObjectWillChange()
    }
}

#if canImport(MobileVLCKit)
extension AVAudioPlayerViewModel: VLCMediaPlayerDelegate {
    public func playWithVLC() {
        if isPlaying {
            close()
            return
        }
        guard let fileURL = fileURL else { return }
        vlcPlayer.media = VLCMedia(url: fileURL)
        let duration = Double(vlcPlayer.media.length.intValue)
        vlcPlayer.delegate = self
        vlcPlayer.play()
        isClosed = false
        isPlaying = true
        isVLC = true
        self.duration = duration <= 0 ? 60 : duration
    }

    public func mediaPlayerStateChanged(_ aNotification: Notification!) {
        let state = vlcPlayer.state
        if state == .ended {
            isPlaying = false
            close()
        } else if state == .buffering {
            isPlaying = true
        } else if state == .error {
            isPlaying = false
        }
    }

    public func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        let time = vlcPlayer.time.intValue / 1000
        isPlaying = true
        currentTime = Double(time)
    }
}
#endif
