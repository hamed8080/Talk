//
//  CallStatus+.swift
//  TalkExtensions
//
//  Created by hamed on 12/4/22.
//

import Chat

public extension CallStatus {
    var key: String? {
        switch self {
        case .requested:
            return "CallStatus.requested"
        case .canceled:
            return "CallStatus.canceled"
        case .miss:
            return "CallStatus.miss"
        case .declined:
            return "CallStatus.declined"
        case .accepted:
            return "CallStatus.accepted"
        case .started:
            return "CallStatus.started"
        case .ended:
            return "CallStatus.ended"
        case .leave:
            return "CallStatus.leave"
        case .unknown:
            return nil
        }
    }
}
