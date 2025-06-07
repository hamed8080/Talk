//
//  IncommingMessagesQueue.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import Chat
import Logger

@MainActor
public class IncommingMessagesQueue {
    private var messageSubjects: [Int: PassthroughSubject<ChatResponse<Message>, Never>] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private let batchInterval: TimeInterval = 1.0 // Interval to batch messages
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
                    Task {
                        await self?.processBatch(messages, for: subjectId)
                    }
                }
                .store(in: &cancellables)
        }

        // Send the new message to the appropriate subject
        messageSubjects[subjectId]?.send(chatResponse)
    }

    private func processBatch(_ messages: [ChatResponse<Message>], for subjectId: Int) async {
        // Process the batch of messages
        let messages = messages.compactMap({$0.result})
        log("Processing \(messages.count) messages for thread \(subjectId)")
        let sorted = messages.sorted(by: { $0.id ?? 0 < $1.id ?? 0} )
        let result = await viewModel?.onNewMessage(sorted, conversationId: subjectId) ?? false

        /// NOTE: When you forward a message to a thread that is old.
        /// Calling onNewMessage in above line won't insert the message,
        /// because the thread is not exits in ThreadsViewModel list,
        /// so it will ignore the message and just go for fetching the thread.
        
        /// If result is false it means it ignored inserting the message,
        /// so we have to precess insertion by manullay.
        if !result, let activeThreadVM = AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel {
            if subjectId == activeThreadVM.threadId {
                await activeThreadVM.historyVM.onForwardMessageForActiveThread(sorted)
            }
        }
    }
    
    func log(_ string: String) {
        Logger.log( title: "IncommingMessagesQueue", message: string)
    }
}
