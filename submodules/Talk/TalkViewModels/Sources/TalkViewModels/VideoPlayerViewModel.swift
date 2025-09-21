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
import Logger
import TalkModels

@MainActor
public class VideoPlayerViewModel: NSObject, ObservableObject, @preconcurrency AVAssetResourceLoaderDelegate {
    @Published public var player: AVPlayer?
    private var timer: Timer?
    private var fileURL: URL
    @Published public var timerString = "00:00"
    @Published public var isFinished: Bool = false

    public init(fileURL: URL, ext: String? = nil) {
        self.fileURL = fileURL
        super.init()
        do {
            let url = try hardLink(fileURL, ext)
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
        isFinished = true
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
        Logger.log( title: "VideoPlayerViewModel", message: string)
    }
    
    private func hardLink(_ fileURL: URL, _ ext: String?) throws -> URL {
        let fm = FileManager.default
        
        let docDIR = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first
        let fileInDOCDIR = docDIR!.appending(path: fileURL.lastPathComponent).appendingPathExtension(ext ?? "mp4")
        
        if !fm.fileExists(atPath: fileInDOCDIR.path()) {
            try fm.linkItem(at: fileURL, to: fileInDOCDIR)
        }
        
        return fileInDOCDIR
    }
    
    public func isSameURL(_ fileURL: URL) -> Bool {
        self.fileURL.absoluteString == fileURL.absoluteString ?? ""
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
#if DEBUG
        print("deinit VideoPlayerViewModel")
#endif
    }
}
