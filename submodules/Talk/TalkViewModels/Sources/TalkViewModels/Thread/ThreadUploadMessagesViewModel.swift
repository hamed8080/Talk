//
//  ThreadUploadMessagesViewModel.swift
//
//
//  Created by hamed on 11/27/23.
//

import Foundation
import Chat
import TalkModels
import Combine
import SwiftUI

@MainActor
public final class ThreadUploadMessagesViewModel {
    weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    private var cancelable: Set<AnyCancellable> = []

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] event in
                self?.onUploadEvent(event)
            }
            .store(in: &cancelable)
    }

    internal func append(_ requests: [HistoryMessageType]) {
        if requests.isEmpty { return }
        Task { [weak self] in
            guard let self = self, let historyVM = viewModel?.historyVM else { return }
            let beforeSectionCount = historyVM.mSections.count
            await historyVM.injectMessagesAndSort(requests)
            let tuple = historyVM.mSections.indexPathsForUpload(requests: requests, beforeSectionCount: beforeSectionCount)
            if let sectionSet = tuple.sectionIndex {
                viewModel?.delegate?.inserted(sectionSet, tuple.indices, .left, nil)
            } else {
                viewModel?.delegate?.inserted(at: tuple.indices)
            }
            // Sleep for better animation when we insert something at the end of the list in upload for multiple items.
            try? await Task.sleep(for: .seconds(0.2))
            let sectionCount = historyVM.mSections.count
            let rowCount = historyVM.mSections.last?.vms.count ?? 0
            let indexPath = IndexPath(row: rowCount - 1, section: sectionCount - 1)
            await viewModel?.scrollVM.scrollToLastUploadedMessageWith(indexPath)
        }
    }

    public func cancel(_ uniqueId: String?) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        }
        Task { @HistoryActor [weak self] in
            await self?.viewModel?.historyVM.removeByUniqueId(uniqueId)
        }
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .canceled(uniqueId: let uniqueId):
            Task { @HistoryActor [weak self] in
                await self?.viewModel?.historyVM.removeByUniqueId(uniqueId)
            }
        default:
            break
        }
    }

    public func hasAnyUploadMessage() -> Bool {
        let hasUploadMessages = viewModel?.historyVM.mSections.last?.vms
            .filter{$0.message is UploadProtocol}.count ?? 0 > 0
        return hasUploadMessages
    }

    public func lastUploadingViewModel() -> MessageRowViewModel? {
        return viewModel?.historyVM.mSections.last?.vms.last(where: {$0.message is UploadProtocol})
    }

    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
