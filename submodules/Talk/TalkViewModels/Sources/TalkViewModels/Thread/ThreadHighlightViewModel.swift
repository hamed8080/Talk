//
//  ThreadHighlightViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import UIKit

final class ThreadHighlightViewModel {
    // Stored properties
    private weak var viewModel: ThreadHistoryViewModel?
    private var highlightTask: Task<Void, Never>?
    private var prevhighlightedMessageId: Int?
    private var task: Task<(), Never>?

    // Computed properties
    private var sections: ContiguousArray<MessageSection> { viewModel?.sections ?? [] }
    private var delegate: HistoryScrollDelegate? { viewModel?.delegate }

    init(){}

    public func setup(_ viewModel: ThreadHistoryViewModel) {
        self.viewModel = viewModel
    }

    @HistoryActor
    private func setHighlight(_ messageId: Int) async {
        // Check if prevhighlightedMessageId is equal to message id, it means that we click twice and we are currently in the middle of an highlight animation.
        if prevhighlightedMessageId == messageId { return }
        guard let vm = sections.messageViewModel(for: messageId), let indexPath = sections.indexPath(for: vm) else { return }
        vm.calMessage.state.isHighlited = true
        await MainActor.run {
            delegate?.setHighlightRowAt(indexPath, highlight: true)
        }

        // Cancel immediately old highlighted item
        await cancelOldHighlighted()

        prevhighlightedMessageId = messageId
        highlightTask?.cancel()
        highlightTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            if !Task.isCancelled {
                // Be sure and make current indexPath, there is a chance the indexPath position is incorrect due to so many factor
                if let tuple = sections.viewModelAndIndexPath(for: messageId) {
                    await unHighlightTimer(vm: tuple.vm, indexPath: tuple.indexPath)
                    prevhighlightedMessageId = nil
                }
            }
        }
    }

    private func cancelOldHighlighted() async {
        guard
            let prevhighlightedMessageId = prevhighlightedMessageId,
            let tuple = sections.viewModelAndIndexPath(for: prevhighlightedMessageId)
        else { return }
        await unHighlightTimer(vm: tuple.vm, indexPath: tuple.indexPath)
    }

    @MainActor
    private func unHighlightTimer(vm: MessageRowViewModel, indexPath: IndexPath) async {
        highlightTask?.cancel()
        highlightTask = nil
        vm.calMessage.state.isHighlited = false
        delegate?.setHighlightRowAt(indexPath, highlight: false)
    }

    private func cancelOldHighlighingIndexPath(vm: MessageRowViewModel) -> IndexPath? {
        guard
            let prevhighlightedMessageId = prevhighlightedMessageId,
            let vm = sections.messageViewModel(for: prevhighlightedMessageId),
            let indexPath = sections.indexPath(for: vm)
        else { return nil }
        return indexPath
    }

    public func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, position: UITableView.ScrollPosition = .bottom, animate: Bool = false) async {
        if highlight {
            await setHighlight(messageId)
        }
        await MainActor.run { [weak self] in
            self?.delegate?.scrollTo(uniqueId: uniqueId, position: position, animate: animate)
        }
    }
}
