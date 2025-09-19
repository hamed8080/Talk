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
            deselectTableView(vm: viewModel)
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

    private func deselectTableView(vm: MessageRowViewModel) {
        if let indexPath = viewModel?.historyVM.sections.indexPath(for: vm) {
            viewModel?.delegate?.tb.deselectRow(at: indexPath, animated: false)
        }
    }
    
    /// Reselct rows if move to a time where the messages where selected,
    /// after tableView did completed inserted is completed
    public func reSelectTableView() {
        guard let sections = viewModel?.historyVM.sections else { return }
        
        for vm in getSelectedMessages() {
            if let indexPath = sections.indexPath(for: vm), vm.calMessage.state.isSelected {
                
                /// Set is selected for setValues method is essential
                /// Also this is different object that above checking
                /// it is for selected messages
                sections[indexPath.section].vms[indexPath.row].calMessage.state.isSelected = true
                
                /// First, we have to reload the row and
                /// then try to select the row to force call the setValues
                viewModel?.delegate?.tb.reloadRows(at: [indexPath], with: .none)
                
                /// After reload we can make sure that the viewModel has been set and
                /// Now we can select the row
                viewModel?.delegate?.tb.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }
}
