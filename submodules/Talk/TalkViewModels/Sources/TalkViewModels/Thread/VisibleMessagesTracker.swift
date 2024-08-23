//
//  VisibleMessagesTracker
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import TalkModels

protocol StabledVisibleMessageDelegate: AnyObject {
    func onStableVisibleMessages(_ messages: [any HistoryMessageProtocol])
}

actor GlobalVisibleActor {}

@globalActor actor VisibleActor: GlobalActor {
    static var shared = GlobalVisibleActor()
}

class VisibleMessagesTracker {
    typealias MessageType = any HistoryMessageProtocol
    @VisibleActor public private(set) var visibleMessages: [MessageType] = []
    private var onVisibleMessagesTask: Task <Void, Error>?
    public weak var delegate: StabledVisibleMessageDelegate?

    func append(message: any HistoryMessageProtocol) {
        Task { @VisibleActor in
            visibleMessages.append(message)
            stableScrolledVisibleMessages()
        }
    }
    
    func remove(message: any HistoryMessageProtocol) {
        Task { @VisibleActor in
            visibleMessages.removeAll(where: {$0.id == message.id})
        }
    }

    private func stableScrolledVisibleMessages() {
        onVisibleMessagesTask?.cancel()
        onVisibleMessagesTask = nil
        onVisibleMessagesTask = Task { @VisibleActor in
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                delegate?.onStableVisibleMessages(visibleMessages)
            }
        }
    }
}
