//
//  ThreadTypes+.swift
//  TalkExtensions
//
//  Created by hamed on 2/5/23.
//

import Chat

public extension ThreadTypes {
    var stringValue: String? {
        switch self {
        case .normal:
            return "Thread.normal"
        case .ownerGroup:
            return "Thread.ownerGroup"
        case .publicGroup:
            return "Thread.publicGroup"
        case .channelGroup:
            return "Thread.channelGroup"
        case .channel:
            return "Thread.channel"
        case .notificationChannel:
            return "Thread.notificationChannel"
        case .publicThread:
            return "Thread.publicThread"
        case .publicChannel:
            return "Thread.publicChannel"
        case .selfThread:
            return "Thread.selfThread"
        case .unknown:
            return nil
        }
    }

    var isPrivate: Bool { self == .channel || self == .normal || self == .ownerGroup || self == .channelGroup }

    /// Get Public type equivalent of the thread.
    var publicType: ThreadTypes {
        switch self {
        case .channel, .channelGroup:
            return .publicChannel
        case .normal, .ownerGroup:
            return .publicGroup
        default:
            return self
        }
    }

    /// Get Private type equivalent of the thread.
    var privateType: ThreadTypes {
        switch self {
        case .publicChannel:
            return .channel
        case .publicGroup:
            return .normal
        default:
            return self
        }
    }

    var isChannelType: Bool {
        self == .channel || self == .channelGroup || self == .publicChannel
    }
}
