//
//  DeleteMessagesQueue.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import Chat
import Logger
import OSLog

@MainActor
public class DeleteMessagesQueue {
    private var messageSubjects: [Int: PassthroughSubject<ChatResponse<Message>, Never>] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private let batchInterval: TimeInterval = 1.0 // Interval to batch messages
    private let maxBatchSize: Int = 50 // Maximum number of messages per batch
    public weak var viewModel: ThreadHistoryViewModel?

    public nonisolated init() {}

    public func onDeleteEvent(_ chatResponse: ChatResponse<Message>) {
        guard let subjectId = chatResponse.subjectId else { return }

        // Create a PassthroughSubject for this thread if it doesn't exist
        if messageSubjects[subjectId] == nil {
            let subject = PassthroughSubject<ChatResponse<Message>, Never>()
            messageSubjects[subjectId] = subject

            // Subscribe to the subject to handle batching
            subject
                .collect(.byTimeOrCount(RunLoop.main, .seconds(batchInterval), maxBatchSize)) // Batch messages
                .sink { [weak self] messages in
                    Task {
                        await self?.processBatch(messages, for: subjectId)
                    }
                }
                .store(in: &cancellables)
        }

        // Send the new message to the appropriate subject
        messageSubjects[subjectId]?.send(chatResponse)
    }

    private func processBatch(_ responses: [ChatResponse<Message>], for subjectId: Int) async {
        // Process the batch of messages
        let messages = responses.compactMap({$0.result})
        log("Processing deleting \(messages.count) messages for thread \(subjectId) messageIds: \(messages.compactMap{$0.id ?? -1})")        
        await viewModel?.onDeleteMessage(messages, conversationId: subjectId)
    }
    
    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
