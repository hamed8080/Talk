//
//  File.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/19/25.
//

import Foundation
import TalkModels

public class AudioFileURLCalculator {
    private let fileURL: URL
    private let message: HistoryMessageType

    public init(fileURL: URL, message: HistoryMessageType) {
        self.fileURL = fileURL
        self.message = message
    }
    
    public func audioURL() -> URL? {
        if let convertedURL = convertedAudioURL() {
            return convertedURL
        }
        
        let mimeType = message.fileMetaData?.file?.mimeType
        var fileExtension: String? = message.fileMetaData?.file?.extension
        
        /// Find file extension by file name such "MySong.mp3" if the metadata from the server was nil
        if fileExtension == nil, let lastPathExt = message.fileMetaData?.file?.originalName?.split(separator: ".").last {
            fileExtension = String(lastPathExt)
        }
        
        switch (fileExtension, mimeType) {
        case ("mp3", _):
            return fileURL.createHardLink(for: fileURL, ext: "mp3")
        case (_, "audio/wave"), (_, "audio/x-wav"):
            return fileURL.createHardLink(for: fileURL, ext: "wav")
        default:
            return fileURL.createHardLink(for: fileURL, ext: "mp4")
        }
    }
    
    private func convertedAudioURL() -> URL? {
        if let convertedURL = message.convertedFileURL, FileManager.default.fileExists(atPath: convertedURL.path()) {
            return convertedURL
        }
        return nil
    }
}
