//
//  VideoPlayerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 3/16/23.
//

import UIKit
import Combine
import Foundation
import AVKit
import OSLog
import TalkModels

@MainActor
public class VideoPlayerViewModel: NSObject, ObservableObject, AVAssetResourceLoaderDelegate {
    @Published public var player: AVPlayer?
    public let fileURL: URL
    let ext: String?
    var title: String?
    var subtitle: String?
    var timer: Timer?
    @Published public var timerString = "00:00"

    public init(fileURL: URL, ext: String? = nil, title: String? = nil, subtitle: String? = nil, directLink: Bool = false) {
        self.fileURL = fileURL
        self.ext = ext
        self.title = title
        self.subtitle = subtitle
        super.init()
        do {
            var url: URL
            if !directLink {
                let hardLinkURL = fileURL.appendingPathExtension(ext ?? "mp4")
                if !FileManager.default.fileExists(atPath: hardLinkURL.path()) {
                    try FileManager.default.linkItem(at: fileURL, to: hardLinkURL)
                }
                url = hardLinkURL
            } else {
                url = fileURL
            }
            let asset = AVURLAsset(url: url)
            asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
            let item = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: item)
            item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(finishedPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        } catch {
            log("error in hardlinking: \(error.localizedDescription)")
        }
    }

    @objc private func finishedPlaying(_ notif: Notification) {
        NotificationCenter.default.post(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        player?.seek(to: .zero)
    }

    override public func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }
        Task { @MainActor in
            onVideoStatusChanged(item)
        }
    }
    
    private func onVideoStatusChanged(_ item: AVPlayerItem) {
        switch item.status {
        case .unknown:
            log("unkown state video player")
        case .readyToPlay:
            log("reday video player")
        case .failed:
            guard let error = item.error else { return }
            log("failed state video player\(error.localizedDescription)")
        @unknown default:
            log("default status video player")
        }
    }

    public func toggle() {
        if player?.timeControlStatus == .paused {
            player?.play()
            startTimer()
        } else {
            player?.pause()
            stopTimer()
        }
    }

    public func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let elapsed = self?.player?.currentTime() else { return }
                self?.timerString = elapsed.seconds.rounded().timerString(locale: Language.preferredLocale) ?? "00:00"
            }            
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }

    deinit {
        print("deinit VideoPlayerViewModel")
    }
}
