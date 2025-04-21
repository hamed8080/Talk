//
//  PendingManager.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Foundation
import Combine
import Chat
import TalkModels

@MainActor
public class PendingManager {
    private var pendings: [String: Any] = [:]
    private var cancellableSet = Set<AnyCancellable>()
    
    public init() {
        registerObservers()
    }
    
    private func registerObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancellableSet)
    }
    
    public func append(uniqueId: String, request: Any) {
        pendings[uniqueId] = request
    }
    
    public func remove(uniqueId: String) {
        pendings.removeValue(forKey: uniqueId)
    }
    
    private func onConnectionStatusChanged(_ status: ConnectionStatus) {
        if status == .connected {
            resendPendings()
        }
    }
    
    private func resendPendings() {
        pendings.forEach { (key: String, value: Any) in
            Task {
                await send(message: value)
            }
        }
    }
    
    @ChatGlobalActor
    func send(message: Any) {
        guard let sender = ChatManager.activeInstance?.message else { return }
        if let normal = message as? SendTextMessageRequest {
            sender.send(normal)
        } else if let forward = message as? ForwardMessageRequest {
            sender.send(forward)
        } else if let reply = message as? ReplyMessageRequest {
            sender.reply(reply)
        } else if let replyPrivately = message as? ReplyPrivatelyRequest {
            sender.replyPrivately(replyPrivately)
        } else if let edit = message as? EditMessageRequest {
            sender.edit(edit)
        }
    }
}
