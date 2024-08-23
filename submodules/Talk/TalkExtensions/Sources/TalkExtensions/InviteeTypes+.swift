//
//  InviteeTypes+.swift
//  TalkExtensions
//
//  Created by hamed on 3/29/23.
//

import Chat

extension InviteeTypes: Identifiable {}
public extension InviteeTypes {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .ssoId:
            return "Invitee.ssoId"
        case .contactId:
            return "Invitee.contactId"
        case .cellphoneNumber:
            return "Invitee.cellphoneNumber"
        case .username:
            return "Invitee.username"
        case .userId:
            return "Invitee.userId"
        case .coreUserId:
            return "Invitee.coreUserId"
        case .unknown:
            return ""
        }
    }
}
