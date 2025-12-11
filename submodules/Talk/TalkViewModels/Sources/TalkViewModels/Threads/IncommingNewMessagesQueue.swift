//
//  IncommingNewMessagesQueue.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import Chat
import Logger

@MainActor
public class IncommingNewMessagesQueue {
    private var messageSubjects: [Int: PassthroughSubject<ChatResponse<Message>, Never>] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private let batchInterval: TimeInterval = 0.2 // Interval to batch messages
    private let maxBatchSize: Int = 50 // Maximum number of messages per batch
    public weak var viewModel: ThreadsViewModel?

    public init() {}

    public func onMessageEvent(_ chatResponse: ChatResponse<Message>) {
        guard let subjectId = chatResponse.subjectId else { return }

        // Create a PassthroughSubject for this thread if it doesn't exist
        if messageSubjects[subjectId] == nil {
            let subject = PassthroughSubject<ChatResponse<Message>, Never>()
            messageSubjects[subjectId] = subject

            // Subscribe to the subject to handle batching
            subject
                .collect(.byTimeOrCount(RunLoop.main, .seconds(batchInterval), maxBatchSize)) // Batch messages
                .sink { [weak self] messages in
                    Task { [weak self] in
                        guard let self = self else { return }
                        await self.processBatch(messages, for: subjectId)
                    }
                }
                .store(in: &cancellables)
        }

        // Send the new message to the appropriate subject
        messageSubjects[subjectId]?.send(chatResponse)
    }

    private func processBatch(_ messages: [ChatResponse<Message>], for subjectId: Int) async {
        log("Processing \(messages.count) messages for thread \(subjectId)")
        
        // Process the batch of messages
        let messages = messages.compactMap({$0.result})
        
        // Deduplicate based on message.id
        let uniqueDict = Dictionary(grouping: messages, by: { $0.id ?? -1 }).compactMapValues { $0.first }
        let uniqueMessages = Array(uniqueDict.values)
        
        // Sort by ID
        let sorted = uniqueMessages.sorted(by: { $0.id ?? 0 < $1.id ?? 0} )
       
        await viewModel?.onNewMessage(sorted, conversationId: subjectId)
    }
    
    func log(_ string: String) {
        Logger.log( title: "IncommingNewMessagesQueue", message: string)
    }
}
