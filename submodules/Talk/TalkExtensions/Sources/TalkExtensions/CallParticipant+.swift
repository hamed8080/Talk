//
//  CallParticipant+.swift
//  TalkExtensions
//
//  Created by hamed on 12/4/22.
//

import Foundation
import SwiftUI
import Chat

public extension CallParticipant {
    var title: String? {
        participant?.name ?? participant?.firstName ?? participant?.lastName ?? participant?.email ?? participant?.username
    }

    var callStatusStringColor: Color {
        switch callStatus {
        case .requested:
            return .clear
        case .canceled:
            return .red
        case .miss:
            return .red
        case .declined:
            return .red
        case .accepted:
            return .green
        case .started:
            return .green
        case .ended:
            return .clear
        case .leave:
            return .red
        case .unknown:
            return .clear
        case .none:
            return .clear
        }
    }

    var callStatusString: String? {
        switch callStatus {
        case .requested:
            return "Call.requested"
        case .canceled:
            return "Call.canceled"
        case .miss:
            return "Call.miss"
        case .declined:
            return "Call.declined"
        case .accepted:
            return "Call.accepted"
        case .started:
            return "Call.started"
        case .ended:
            return "Call.ended"
        case .leave:
            return "Call.leave"
        case .unknown:
            return nil
        case .none:
            return nil
        }
    }

    var canRecall: Bool {
        let statuses: [CallStatus] = [.canceled, .declined, .ended, .leave, .miss]
        guard let callStatus = callStatus else { return false }
        return statuses.contains(callStatus)
    }
}
