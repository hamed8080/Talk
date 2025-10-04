//
//  IncommingForwardMessagesQueue.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import Chat
import Logger

@MainActor
public class IncommingForwardMessagesQueue {
    private var messageSubjects: [Int: PassthroughSubject<ChatResponse<Message>, Never>] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private let batchInterval: TimeInterval = 0.3 // Interval to batch messages
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
        // Process the batch of messages
        let messages = messages.compactMap({$0.result})
        log("Processing \(messages.count) messages for thread \(subjectId)")
        let sorted = messages.sorted(by: { $0.id ?? 0 < $1.id ?? 0} )
        
        /// Update the lastMessage of the thread inside the thread list, and then sort the list to bring the
        /// thread to the top.
        /// If the thread is not inside the list it will try to fetch it from the server.
        await viewModel?.onNewForwardMessage(conversationId: subjectId, forwardMessage: sorted.last ?? .init())
        await AppState.shared.objectsContainer.archivesVM.onNewForwardMessage(conversationId: subjectId, forwardMessage: sorted.last ?? .init())
        
        /// If result is false it means it ignored inserting the message,
        /// so we have to precess insertion by manullay.
        if let activeThreadVM = AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel {
            if subjectId == activeThreadVM.id {
                await activeThreadVM.historyVM.onForwardMessageForActiveThread(sorted)
            }
        }
    }
    
    func log(_ string: String) {
        Logger.log( title: "IncommingForwardMessagesQueue", message: string)
    }
}
