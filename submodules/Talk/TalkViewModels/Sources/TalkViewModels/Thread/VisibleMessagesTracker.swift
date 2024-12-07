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
    func onStableVisibleMessages(_ messages: [any HistoryMessageProtocol]) async
}

actor GlobalVisibleActor {}

@globalActor actor VisibleActor: GlobalActor {
    static var shared = GlobalVisibleActor()
}

@VisibleActor
class VisibleMessagesTracker {
    typealias MessageType = any HistoryMessageProtocol
    public private(set) var visibleMessages: [MessageType] = []
    private var onVisibleMessagesTask: Task <Void, Error>?
    public weak var delegate: StabledVisibleMessageDelegate?
    
    nonisolated init() {
        
    }

    func append(message: any HistoryMessageProtocol) {
        visibleMessages.append(message)
        stableScrolledVisibleMessages()
    }
    
    func remove(message: any HistoryMessageProtocol) {
        visibleMessages.removeAll(where: {$0.id == message.id})
    }

    private func stableScrolledVisibleMessages() {
        onVisibleMessagesTask?.cancel()
        onVisibleMessagesTask = nil
        onVisibleMessagesTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                await delegate?.onStableVisibleMessages(visibleMessages)
            }
        }
    }
}
