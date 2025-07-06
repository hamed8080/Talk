//
//  AVAudioPlayerItem.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 7/6/25.
//

import UIKit
import TalkModels

public class AVAudioPlayerItem: ObservableObject {
    @Published public var currentTime: Double = 0
    @Published public var isPlaying: Bool = false
    @Published public var isFinished: Bool = false
    @Published public var failed: Bool = false
    @MainActor @Published public var waveFormImage: UIImage?
    public let messageId: Int
    public let duration: Double    
    public let fileURL: URL
    public let ext: String?
    public let title: String?
    public let subtitle: String?
    public let uniqueId = UUID()

    public init(
        messageId: Int,
        duration: Double, fileURL: URL, ext: String?, currentTime: Double = 0,
        isPlaying: Bool = false, title: String? = nil, subtitle: String? = nil, isFinished: Bool = false
    ) {
        self.messageId = messageId
        self.duration = duration
        self.fileURL = fileURL
        self.ext = ext
        self.currentTime = currentTime
        self.isPlaying = isPlaying
        self.title = title ?? fileURL.lastPathComponent
        self.subtitle = subtitle
        self.isFinished = isFinished
    }
}

extension AVAudioPlayerItem {
    public func audioTimerString() -> String {
        let duration = duration.timerString(locale: Language.preferredLocale) ?? " "
        let currentTime = currentTime.timerString(locale: Language.preferredLocale) ?? " "
        return "\(currentTime) / \(duration)"
    }
    
    @MainActor
    public func createWaveform(height: CGFloat = 32) async -> UIImage? {
        if waveFormImage != nil { return waveFormImage }
        do {
            let waveImage = try await WaveformGenerator(url: fileURL, height: height).generate()
            waveFormImage = waveImage
            return waveImage
        } catch {
#if DEBUG
            print(error)
#endif
            return nil
        }
    }
    
    public var progress: CGFloat {
        return min(currentTime / duration, 1.0)
    }
}
