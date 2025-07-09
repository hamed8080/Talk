//
//  ThreadSelectedMessagesViewModel.swift
//  
//
//  Created by hamed on 11/27/23.
//

import Foundation
import Chat
import TalkModels

@MainActor
public final class ThreadSelectedMessagesViewModel {
    public private(set) var isInSelectMode: Bool = false
    public weak var viewModel: ThreadViewModel?
    private var selectedMessages: [MessageRowViewModel] = []
    public init() {}

    public func setup(viewModel: ThreadViewModel? = nil) {
        self.viewModel = viewModel
    }
    
    public func clearSelection() {
        getSelectedMessages().forEach { viewModel in
            viewModel.calMessage.state.isSelected = false
        }
        setInSelectionMode(false)
        selectedMessages.removeAll()
    }

    public func setInSelectionMode(_ value: Bool) {
        isInSelectMode = value
        putAllInSeclectionMode(value)
        if !value {
            selectedMessages.removeAll()
        }
    }

    public func getSelectedMessages() -> [MessageRowViewModel] {
        selectedMessages
    }

    private func putAllInSeclectionMode(_ isInSelectionMode: Bool) {
        viewModel?.historyVM.sections.flatMap({$0.vms}).forEach({ vm in
            vm.calMessage.state.isInSelectMode = isInSelectionMode
        })
    }
    
    public func add(_ vm: MessageRowViewModel) {
        selectedMessages.append(vm)
    }
    
    public func remove(_ vm: MessageRowViewModel) {
        selectedMessages.removeAll(where: {$0.message.id == vm.message.id})
    }
}
