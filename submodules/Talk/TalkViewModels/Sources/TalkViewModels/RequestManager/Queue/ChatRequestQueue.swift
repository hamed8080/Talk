//
//  ChatRequestQueue.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/28/25.
//

import Foundation
import Chat
import Logger
import OSLog

@MainActor
public class ChatRequestQueue {
    private var requestQueue = PriorityQueue<RequestEnqueuType>()
    private var throttleInterval: TimeInterval = 0.01
    
    public func enqueue(_ type: RequestEnqueuType) {
        let deadline: DispatchTime = .now() + throttleInterval
        log("Enqueuing the request: \(type) and deadline to start from now is:\(throttleInterval)")
        let isDuplicateRemoved = removeOldConversaionReq(newReq: type)
        requestQueue.enqueue(type)
        processWithDelay(deadline: isDuplicateRemoved ? .now() + 0 : deadline)
        throttleInterval += 3
    }
    
    private func processWithDelay(deadline: DispatchTime){
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self = self else { return }
            if requestQueue.isEmpty() {
                throttleInterval = 0
            }
            guard let nextRequest = requestQueue.dequeue() else { return }
            processQueue(nextRequest)
        }
    }
    
    private func processQueue(_ request: RequestEnqueuType) {
        Task {
            await sendRequest(request)
        }
    }
    
    @ChatGlobalActor
    private func sendRequest(_ request: RequestEnqueuType) {
        switch request {
        case .getConversations(let req):
            ChatManager.activeInstance?.conversation.get(req)
        case .getContacts(let req):
            ChatManager.activeInstance?.contact.get(req)
        case .history(let req):
            ChatManager.activeInstance?.message.history(req)
        case .reactionCount(let req):
            ChatManager.activeInstance?.reaction.count(req)
        }
    }
    
    public func cancellAll() {
        throttleInterval = 0
        requestQueue.removeAll()
    }
    
    /// Prevent duplication of GET threads requests by only sending the new one; the old one should be canceled.
    private func removeOldConversaionReq(newReq: RequestEnqueuType) -> Bool {
        if case let .getConversations = newReq, let index = oldConversationReqeustIndex() {
            requestQueue.remove(at: index)
            return true
        }
        return false
    }
    
    private func oldConversationReqeustIndex() -> Int? {
        requestQueue.firstIndex {
            if case .getConversations = $0 as? RequestEnqueuType { return true }
            return false
        }
    }
    
    private func log(_ string: String) {
#if DEBUG
        let log = Log(prefix: "TALK_APP", time: .now, message: string, level: .warning, type: .internalLog, userInfo: nil)
        NotificationCenter.logs.post(name: .logs, object: log)
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
