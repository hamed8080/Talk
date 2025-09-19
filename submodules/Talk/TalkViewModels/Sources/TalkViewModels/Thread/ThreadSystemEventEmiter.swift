//
//  ThreadSystemEventEmiter.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 8/18/25.
//

import Foundation
import Chat

@MainActor
public class ThreadSystemEventEmiter {
    private let threadId: Int
    private var isTyping = false
    private var signalTimer: Timer?
    
    init(threadId: Int) {
        self.threadId = threadId
    }
    
    public func sendTyping() {
        if isTyping { return }
        let id = threadId
        Task { @ChatGlobalActor [weak self] in
            let req = SendSignalMessageRequest(signalType: .isTyping, threadId: id)
            ChatManager.activeInstance?.system.sendSignalMessage(req)
            await MainActor.run {
                self?.isTyping = false
            }
        }
    }
    
    public func send(smt: SignalMessageType) {
        let id = threadId
        signalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @ChatGlobalActor in
                let req = SendSignalMessageRequest(signalType: smt, threadId: id)
                ChatManager.activeInstance?.system.sendSignalMessage(req)
            }
        }
    }
    
    public func stopTyping() {
        cancelTyping()
    }
    
    public func stopSignal() {
        signalTimer?.invalidateTimer()
        signalTimer = nil
    }
    
    private func cancelTyping() {
        isTyping = false
    }
}
