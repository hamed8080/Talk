//
//  HistoryHelpers.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import TalkModels
import ChatCore
import ChatModels

public typealias MessageIndex = Array<HistoryMessageType>.Index
public typealias SectionIndex = Array<MessageSection>.Index
public typealias HistoryResponse = ChatResponse<[Message]>

extension ThreadHistoryViewModel {
    func canSetSeen(for message: HistoryMessageType, newMessageId: Int, isMeId: Int) -> Bool {
        let notDelivered = message.delivered ?? false == false
        let notSeen = message.seen ?? false == false
        let isValidToChange = (message.id ?? 0 < newMessageId) && (notSeen || notDelivered) && message.ownerId == isMeId
        return isValidToChange
    }
}
