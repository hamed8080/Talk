//
//  Contact+.swift
//  TalkExtensions
//
//  Created by hamed on 11/26/22.
//

import ChatModels
import Foundation

extension Contact: ObservableObject {}

public extension Contact {
    func update(_ newContact: Contact) {
        blocked = newContact.blocked
        cellphoneNumber = newContact.cellphoneNumber
        email = newContact.email
        firstName = newContact.firstName
        hasUser = newContact.hasUser
        id = newContact.id
        image = newContact.image
        lastName = newContact.lastName
        user = newContact.user
        notSeenDuration = newContact.notSeenDuration
        time = newContact.time
        userId = newContact.userId
    }

    var computedUserIdentifire: String? {
        var id: String?
        if let cellphoneNumber = cellphoneNumber, !cellphoneNumber.isEmpty {
            id = cellphoneNumber
        }
        if let email = email, !email.isEmpty {
            id = email
        }

        if let userName = user?.username, !userName.isEmpty {
            id = userName
        }
        return id
    }

    var toParticipant: Participant {
        return Participant(
            contactId: id,
            coreUserId: user?.coreUserId,
            id: user?.id ?? user?.coreUserId ?? -1,
            image: image ?? user?.image,
            name: "\(firstName ?? "") \(lastName ?? "")"
        )
    }
}
