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
import Combine

@MainActor
public class ChatRequestQueue {
    private var requestQueue = PriorityQueue<RequestEnqueuType>()
    private var throttleInterval: TimeInterval = 0.01
    private var cancellables = Set<AnyCancellable>()
    
    public enum RequestEnqueuType: Comparable {
        case getConversations(req: ThreadsRequest)
        case getContacts(req: ContactsRequest)
        case history(req: GetHistoryRequest)
        case reactionCount(req: ReactionCountRequest)
        
        // Define priority for each request type
        var priority: Int {
            switch self {
            case .getConversations: return 4
            case .getContacts: return 1
            case .history: return 3
            case .reactionCount: return 2
            }
        }
        
        var uniqueId: String {
            switch self {
            case .getConversations(let value): return value.uniqueId
            case .getContacts(let value): return value.uniqueId
            case .history(let value): return value.uniqueId
            case .reactionCount(let value): return value.uniqueId
            }
        }
        
        public static func < (lhs: RequestEnqueuType, rhs: RequestEnqueuType) -> Bool {
            return lhs.priority < rhs.priority
        }
        
        public static func == (lhs: RequestEnqueuType, rhs: RequestEnqueuType) -> Bool {
            return lhs.uniqueId < rhs.uniqueId
        }
    }
    
    public func enqueue(_ type: RequestEnqueuType) {
        let deadline: DispatchTime = .now() + throttleInterval
        log("Enqueuing the request: \(type) and deadline to start from now is:\(throttleInterval)")
        requestQueue.enqueue(type)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self = self else { return }
            if requestQueue.isEmpty() {
                throttleInterval = 0
            }
            guard let nextRequest = requestQueue.dequeue() else { return }
            processQueue(nextRequest)
        }
        throttleInterval += 3
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
        requestQueue.removeAll()
    }
    
    private func log(_ string: String) {
#if DEBUG
        let log = Log(prefix: "TALK_APP", time: .now, message: string, level: .warning, type: .internalLog, userInfo: nil)
        NotificationCenter.logs.post(name: .logs, object: log)
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
