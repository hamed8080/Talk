//
//  ChatRequestQueue.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/28/25.
//

import Foundation
import Chat
import Logger

@MainActor
public class ChatRequestQueue {
    private var requestQueue = PriorityQueue<RequestEnqueueType>()
    private var throttleInterval: TimeInterval = 0.01
    private let resetThrottleValue: TimeInterval = 0.5
    
    public func enqueue(_ type: RequestEnqueueType) {
        log("Enqueuing request: \(type) with throttleInterval: \(throttleInterval)")
        removeOldRequests(for: type)
        requestQueue.enqueue(type)
        let delay: DispatchTime = .now() + throttleInterval
        processWithDelay(deadline: delay)
        throttleInterval += 1.0
    }
    
    private func processWithDelay(deadline: DispatchTime){
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self = self, let nextRequest = requestQueue.dequeue() else {
                self?.throttleInterval = self?.resetThrottleValue ?? 0.5
                return
            }
            
            processQueue(nextRequest)
            
            if requestQueue.isEmpty() {
                throttleInterval = resetThrottleValue
            }
        }
    }
    
    private func processQueue(_ request: RequestEnqueueType) {
        Task {
            await sendRequest(request)
        }
    }
    
    @ChatGlobalActor
    private func sendRequest(_ request: RequestEnqueueType) {
        switch request {
        case .getConversations(let req):
            ChatManager.activeInstance?.conversation.get(req)
        case .getArchives(let req):
            ChatManager.activeInstance?.conversation.get(req)
        case .getContacts(let req):
            ChatManager.activeInstance?.contact.get(req)
        case .history(let req):
            ChatManager.activeInstance?.message.history(req)
        case .mentions(let req):
            ChatManager.activeInstance?.message.history(req)
        case .reactionCount(let req):
            ChatManager.activeInstance?.reaction.count(req)
        case .callsToJoin(req: let req):
            ChatManager.activeInstance?.call.callsToJoin(req)
        }
    }
    
    public func cancellAll() {
        throttleInterval = resetThrottleValue
        requestQueue.removeAll()
        log("Removed all reuqest by cancell all")
    }
    
    private func removeOldRequests(for newReq: RequestEnqueueType) {
        let match: (RequestEnqueueType) -> Bool = { item in
            switch (newReq, item) {
            case (.getConversations, .getConversations),
                (.getArchives, .getArchives),
                (.getContacts, .getContacts),
                (.history, .history),
                (.mentions, .mentions),
                (.callsToJoin, .callsToJoin),
                (.reactionCount, .reactionCount):
                return true
            default:
                return false
            }
        }
        
        let indicesToRemove = requestQueue.indices().filter {
            let item = requestQueue.indexOf($0)
            return match(item)
        }
        
        if !indicesToRemove.isEmpty {
            indicesToRemove.reversed().forEach {
                let element = requestQueue.indexOf($0)
                log("Removed duplicate request with uniqueId: \(element.uniqueId)")
                requestQueue.remove(at: $0)
            }
        }
    }
    
    private func log(_ string: String) {
        Logger.log(title: "ChatRequestQueue", message: string)
    }
}
