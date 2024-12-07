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
        #if DEBUG
            NotificationCenter.logs.publisher(for: .logs)
                .compactMap { $0.object as? Log }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] log in
                    self?.logs.insert(log, at: 0)
                }
                .store(in: &cancellableSet)
        #endif
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

    public func startExporting() async {
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
        logs.forEach { _ in
            Logger.clear(prefix: "CHAT_SDK")
            Logger.clear(prefix: "ASYNC_SDK")
            clearLogs()
        }
    }

    public func clearLogs() {
        logs.removeAll()
    }
}
