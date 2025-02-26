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
    func onStableVisibleMessages(_ messages: [HistoryMessageType]) async
}

actor GlobalVisibleActor {}

@globalActor actor VisibleActor: GlobalActor {
    static var shared = GlobalVisibleActor()
}

@VisibleActor
class VisibleMessagesTracker {
    public private(set) var visibleMessages: [HistoryMessageType] = []
    private var onVisibleMessagesTask: Task <Void, Error>?
    public weak var delegate: StabledVisibleMessageDelegate?
    
    nonisolated init() {
        
    }

    func append(message: HistoryMessageType) {
        visibleMessages.append(message)
        stableScrolledVisibleMessages()
    }
    
    func remove(message: HistoryMessageType) {
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
