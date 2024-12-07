//
//  ExportMessagesViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Chat
import Foundation
import Combine

@MainActor
public final class ExportMessagesViewModel {
    private weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    public var threadId: Int { thread?.id ?? 0 }
    public var filePath: URL?
    private var cancelable: Set<AnyCancellable> = []

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] value in
                if case let .export(response) = value {
                    self?.onExport(response)
                }
            }
            .store(in: &cancelable)
    }

    private func onExport(_ response: ChatResponse<URL>) {
        filePath = response.result
    }

    public func exportChats(startDate: Date, endDate: Date) {
        let req = GetHistoryRequest(threadId: threadId, fromTime: UInt(startDate.millisecondsSince1970), toTime: UInt(endDate.millisecondsSince1970))
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.export(req)
        }
    }

    public func deleteFile() {
        guard let url = filePath else { return }
        try? FileManager.default.removeItem(at: url)
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
