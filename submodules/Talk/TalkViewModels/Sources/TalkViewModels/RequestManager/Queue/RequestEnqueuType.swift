//
//  RequestEnqueuType.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat

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
