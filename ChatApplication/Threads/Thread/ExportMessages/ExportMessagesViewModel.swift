//
//  ExportMessagesViewModel.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import FanapPodChatSDK
import Foundation

protocol ExportMessagesViewModelProtocol {
    init(thread: Conversation)
    var thread: Conversation { get }
    var filePath: URL? { get set }
    var threadId: Int { get }
    func exportChats(startDate: Date, endDate: Date)
    func deleteFile()
}

class ExportMessagesViewModel: ObservableObject, ExportMessagesViewModelProtocol {
    let thread: Conversation
    var threadId: Int { thread.id ?? 0 }
    @Published var filePath: URL?

    required init(thread: Conversation) {
        self.thread = thread
    }

    func exportChats(startDate: Date, endDate: Date) {
        ChatManager.activeInstance.exportChat(.init(threadId: threadId, fromTime: UInt(startDate.millisecondsSince1970), toTime: UInt(endDate.millisecondsSince1970))) { [weak self] response in
            self?.filePath = response.result
        }
    }

    func deleteFile() {
        guard let url = filePath else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
