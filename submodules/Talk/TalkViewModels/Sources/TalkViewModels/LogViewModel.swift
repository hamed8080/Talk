//
//  LogViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 6/27/22.
//

import Chat
import Combine
import CoreData
import Foundation
import Logger
import TalkExtensions

@MainActor
public final class LogViewModel: ObservableObject {
    @Published public var logs: [Log] = []
    @Published public var searchText: String = ""
    @Published public var type: LogEmitter?
    @Published public var isFiltering = false
    @Published public var shareDownloadedFile = false
    @Published public var logFileURL: URL?
    public private(set) var cancellableSet: Set<AnyCancellable> = []

    public init() {
        Logger.allLogs { [weak self] logs in
            self?.logs = logs
            self?.sort()
        }
        if ProcessInfo().environment["DELETE_LOG_ON_LAUNCH"] == "1" {
            deleteLogs()
        }
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            /// Get new logs from last log in the list
            Task { [weak self] in
                await self?.onTimer()
            }
        }
    }
    
    private func onTimer() {
        let lastLogTime = logs.first?.time ?? .now.advanced(by: -5)
        Logger.allLogs(fromTime: lastLogTime) { [weak self] newLogs in
            guard let self = self else { return }
            logs.append(contentsOf: newLogs)
            sort()
        }
    }

    public var filtered: [Log] {
        if searchText.isEmpty {
            return type == nil ? logs : logs.filter { $0.type == type }
        } else {
            if let type = type {
                return logs.filter {
                    $0.message?.lowercased().contains(searchText.lowercased()) ?? false && $0.type == type
                }
            } else {
                return logs.filter {
                    $0.message?.lowercased().contains(searchText.lowercased()) ?? false
                }
            }
        }
    }

    @AppBackgroundActor
    public func startExporting(logs: [Log]) async {
        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .full
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
            formatter.locale = Locale(identifier: "en_US")
            return formatter
        }()
        let name = Date().getDate()
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).txt")
        let url = tmp
        let logMessages = logs.compactMap{ log in
            var message = "==================================\n"
            message += "Type: \(String(describing: log.type ?? .internalLog).uppercased())\n"
            message += "Level: \(String(describing: log.level ?? .verbose).uppercased())\n"
            message += "Prefix: \(log.prefix ?? "")\n"
            message += "UserInfo: \(log.userInfo ?? [:])\n"
            message += "DateTime: \(formatter.string(from: log.time ?? .now))\n"
            message += "\(log.message ?? "")\n"
            message += "==================================\n"
            return message
        }
        let string = logMessages.joined(separator: "\n")
        try? string.write(to: url, atomically: true, encoding: .utf8)
        await MainActor.run {
            self.logFileURL = url
            shareDownloadedFile.toggle()
        }
    }

    public func deleteLogs() {
        DispatchQueue.global(qos: .background).async {
            Logger.clear(prefix: "CHAT_SDK")
        }
        
        DispatchQueue.global(qos: .background).async {
            Logger.clear(prefix: "ASYNC_SDK")
        }
        
        DispatchQueue.global(qos: .background).async {
            Logger.clear(prefix: "TALK_VIEW_MODELS")
        }
        
        DispatchQueue.global(qos: .background).async {
            Logger.clear(prefix: "TALK_APP")
        }
        
        clearLogs()
    }

    public func clearLogs() {
        logs.removeAll()
    }
    
    private func sort() {
        logs.sort(by: { ($0.time ?? .now) > ($1.time ?? .now) })
    }
}
