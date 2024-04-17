//
//  BotViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatDTO
import ChatCore
import Additive
import OSLog

class RequestsManager {
    public static let shared = RequestsManager()
    fileprivate var requests: [String: ChatDTO.UniqueIdProtocol] = [:]
    private var queue = DispatchQueue(label: "RequestQueue")

    private init(){}

    func append(value: ChatDTO.UniqueIdProtocol, autoCancel: Bool = true) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let key = "\(value.uniqueId)"
            requests[key] = value
            if autoCancel {
                addCancelTimer(key: key)
            }
        }
    }

    func append(prepend: String, value: ChatDTO.UniqueIdProtocol, autoCancel: Bool = true) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let key = "\(prepend)-\(value.uniqueId)"
            requests[key] = value
            if autoCancel {
                addCancelTimer(key: key)
            }
        }
    }

    func remove(prepend: String, for key: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            log("removing key: \(key) prepend: \(prepend)")
            remove(key: "\(prepend)-\(key)")
        }
    }

    func remove(key: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if !requests.keys.contains(key) { return }
            log("removing key: \(key)")
            requests.removeValue(forKey: key)
        }
    }

    func pop(prepend: String, for key: String) -> ChatDTO.UniqueIdProtocol? {
        queue.sync {
            let prependedKey = "\(prepend)-\(key)"
            if !requests.keys.contains(prependedKey) { return nil }
            log("poping prepend: \(prepend) with uniqueId \(key)")
            let value = requests[prependedKey]
            requests.removeValue(forKey: prependedKey)
            return value
        }
    }

    func pop(for key: String) -> ChatDTO.UniqueIdProtocol? {
        queue.sync {
            if !requests.keys.contains(key) { return nil }
            log("poping uniqueId \(key)")
            let value = requests[key]
            requests.removeValue(forKey: key)
            return value
        }
    }

    /// Automatically cancel a request if there is no response come back from the chat server after 25 seconds.
    func addCancelTimer(key: String) {
        let timer = SourceTimer()
        timer.start(duration: 25) { [weak self] in
            self?.queue.async {  [weak self] in
                guard let self = self else { return }
                if requests.keys.contains(where: { $0 == key}) {
                    log("addCancelTimer remvove: uniqueId \(key)")
                    remove(key: key)
                    DispatchQueue.main.async {
                        NotificationCenter.onRequestTimer.post(name: .onRequestTimer, object: key)
                    }
                }
            }
        }
    }

    func contains(key: String) -> Bool {
        queue.sync {
            return requests.contains(where: {$0.key == key})
        }
    }

    func containsPartial(prependedKey: String) -> Bool {
        queue.sync {
            return requests.contains(where: {$0.key.contains(prependedKey)})
        }
    }

    func clear() {
        queue.sync {
            log("remove all requests")
            requests.removeAll()
        }
    }

    func getAllKeys() -> [String] {
        queue.sync {
            Array(requests.keys)
        }
    }
    
    // MARK: Logs
    private func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}

public extension ChatResponse {

    @discardableResult
    func pop() -> ChatDTO.UniqueIdProtocol? {
        guard let uniqueId = uniqueId else { return nil }
        return RequestsManager.shared.pop(for: uniqueId)
    }

    @discardableResult
    func pop(prepend: String) -> ChatDTO.UniqueIdProtocol? {
        guard let uniqueId = uniqueId else { return nil }
        return RequestsManager.shared.pop(prepend: prepend, for: uniqueId)
    }

    @discardableResult
    func contains(prepend: String) -> Bool {
        guard let uniqueId = uniqueId else { return false }
        return RequestsManager.shared.contains(key: "\(prepend)-\(uniqueId)")
    }

    @discardableResult
    func containsPartial(prependedKey: String) -> Bool {
        guard let uniqueId = uniqueId else { return false }
        return RequestsManager.shared.containsPartial(prependedKey: "\(prependedKey)-\(uniqueId)")
    }
}
