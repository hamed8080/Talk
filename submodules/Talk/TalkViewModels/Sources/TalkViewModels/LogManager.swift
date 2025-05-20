//
//  LogManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/18/25.
//

import Foundation

@MainActor
public class LogManager {
    let isLogOnDiskEnabled = ProcessInfo().environment["ENABLE_TALK_LOG_ON_DISK"] == "1"
    @MainActor public static let shared = LogManager()
    
    private let fileName = "debug_log.txt"
    private let fileURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = directory.appendingPathComponent(fileName)
    }

    public func log(_ message: String) {
        if !isLogOnDiskEnabled { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        // Use actual newline character (\n), not literal "\\n"
        let fullMessage = "[\(timestamp)] \(message)\n"
        
        guard let data = fullMessage.data(using: .utf8) else { return }
        
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: self.fileURL) {
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
        } else {
            try? data.write(to: self.fileURL, options: .atomic)
        }
    }

    public func readLogs() -> String {
        (try? String(contentsOf: fileURL)) ?? ""
    }

    public func clearLogs() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    func logFilePath() -> URL {
        return fileURL
    }
}
