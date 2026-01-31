//
//  MessagePlayerItemCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit
import AVFoundation
import Chat
import TalkModels

public final class MessagePlayerItemCalculator {
    private let message: HistoryMessageType
    private let url: URL?
    private let metadata: FileMetaData?
    
    public init(message: HistoryMessageType, url: URL?, metadata: FileMetaData?) {
        self.message = message
        self.url = url
        self.metadata = metadata
    }
    
    public func playerItem() async -> AVAudioPlayerItem? {
        guard let url = url,
              let asset = try? AVAsset(url: url)
        else { return nil }
        let convrtedURL = message.convertedFileURL
        let convertedExist = FileManager.default.fileExists(atPath: convrtedURL?.path() ?? "")
        let assetMetadata = try? await asset.load(.commonMetadata)
        let artworkMetadata = assetMetadata?.first(where: { $0.commonKey?.rawValue == AVMetadataKey.commonKeyArtwork.rawValue })
        let artistName = assetMetadata?.first(where: { $0.commonKey?.rawValue == AVMetadataKey.commonKeyArtist.rawValue }) as? String
        return AVAudioPlayerItem(messageId: message.id ?? -1,
                                 duration: Double(CMTimeGetSeconds(asset.duration)),
                                 fileURL: url,
                                 ext: convertedExist ? "mp4" : metadata?.file?.mimeType?.ext,
                                 title: metadata?.file?.originalName ?? metadata?.name ?? "",
                                 subtitle: metadata?.file?.originalName ?? "",
                                 artworkMetadata: artworkMetadata,
                                 artistName: artistName
        )
    }
    
    public class func audioURL(fileURL: URL, message: HistoryMessageType, isAudio: Bool) -> URL? {
        if !isAudio { return nil }
        return AudioFileURLCalculator(fileURL: fileURL, message: message).audioURL()
    }
}

extension AVMetadataItem: @unchecked Sendable {}
