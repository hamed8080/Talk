//
//  DeleteMessagesViewModelModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Chat
import TalkModels

@MainActor
public final class DeleteMessagesViewModelModel {
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init() }
    public var deleteForMe: Bool = true
    public var deleteForOthers: Bool = false
    public var deleteForOthserIfPossible: Bool = false
    public var hasPinnedMessage: Bool = false
    public var isSingle: Bool = false
    public var isVstackLayout: Bool = false
    public var isSelfThread: Bool { viewModel?.thread.type == .selfThread }
    /// 86_400_000 is equal to the number of milliseconds in a day
    public var pastDeleteTimeForOthers: [HistoryMessageType] = []
    public var notPastDeleteTime: [HistoryMessageType] = []

    private var isGroup: Bool { thread.group == true }
    private var isAdmin: Bool { thread.admin == true }
    private var meUserId: Int { AppState.shared.user?.id ?? -1 }
    private var containsMe: Bool = false
    private var containsNotMe: Bool = false
    private var onlyMyMessages: Bool { !containsNotMe }
    private var onlyOthersMessages: Bool { !containsMe }
    private var isOnlyContainsPastMessages: Bool = false

    public init() {}

    public func setup(viewModel: ThreadViewModel) async {
        self.viewModel = viewModel
        await calculate()
        deleteForOthers = isDeletableForOthers()
        deleteForOthserIfPossible = isDeletableForOthersIfPossible()
        isVstackLayout = deleteForOthserIfPossible && !deleteForOthers
    }

    public static func isDeletable(isMe: Bool, message: Message, thread: Conversation?) -> Bool {
        let isChannel = thread?.type?.isChannelType == true
        let isAdmin = thread?.admin == true
        if isChannel && !isAdmin {
            return false
        }
        return true
    }

    private func isDeletableForOthers() -> Bool {
        if isSelfThread { return false }
        if !pastDeleteTimeForOthers.isEmpty { return false }
        if hasPinnedMessage { return false }
        if (isAdmin && isGroup) {
           return true
        }

        if !isGroup && onlyMyMessages {
            return true
        }

        if !isAdmin && isGroup && onlyMyMessages {
            return true
        }

        return false
    }

    private func isDeletableForOthersIfPossible() -> Bool {
        if isSelfThread { return false }
        if onlyOthersMessages { return false }
        if isOnlyContainsPastMessages { return false }
        if hasPinnedMessage { return false }
        return true
    }

    public func deleteMessagesForMe() {
        Task {
            let selectedMessages = await getSelectedMessages()
            await viewModel?.historyVM.deleteMessages(selectedMessages)
            viewModel?.selectedMessagesViewModel.setInSelectionMode(false)
            viewModel?.delegate?.showSelectionBar(false)
            viewModel?.delegate?.setSelection(false)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        }
    }

    public func deleteForAll() {
        Task {
            let selectedMessages = await getSelectedMessages()
            viewModel?.historyVM.deleteMessages(selectedMessages, forAll: true)
            viewModel?.selectedMessagesViewModel.setInSelectionMode(false)
            viewModel?.delegate?.showSelectionBar(false)
            viewModel?.delegate?.setSelection(false)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        }
    }

    public func deleteForMeAndAllOthersPossible() {
        if pastDeleteTimeForOthers.count > 0 {
            viewModel?.historyVM.deleteMessages(pastDeleteTimeForOthers, forAll: false)
        }
        if notPastDeleteTime.count > 0 {
            viewModel?.historyVM.deleteMessages(notPastDeleteTime, forAll: true)
        }
        viewModel?.selectedMessagesViewModel.setInSelectionMode(false)
        viewModel?.delegate?.showSelectionBar(false)
        viewModel?.delegate?.setSelection(false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
    }

    public func cleanup() {
        viewModel?.selectedMessagesViewModel.clearSelection()
        viewModel?.selectedMessagesViewModel.setInSelectionMode(false)
        viewModel?.delegate?.setSelection(false)
        viewModel?.delegate?.showSelectionBar(false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
    }

    private func getSelectedMessages() -> [HistoryMessageType] {
        viewModel?.selectedMessagesViewModel.getSelectedMessages().compactMap({$0.message}) ?? []
    }

    private func calculate() {
        let selectedMessages = getSelectedMessages()
        isSingle = selectedMessages.count == 1
        hasPinnedMessage = selectedMessages.contains(where: {$0.id == viewModel?.thread.pinMessage?.id })
        pastDeleteTimeForOthers = selectedMessages.filter({ Int64($0.time ?? 0) + (86_400_000) < Date().millisecondsSince1970 })
        containsMe = selectedMessages.contains(where: { $0.isMe(currentUserId: meUserId) })
        containsNotMe = selectedMessages.contains(where: { !$0.isMe(currentUserId: meUserId) })
        notPastDeleteTime = selectedMessages.filter { message in
            !pastDeleteTimeForOthers.contains(where: { $0.uniqueId == message.uniqueId} )
        }
        isOnlyContainsPastMessages = pastDeleteTimeForOthers.count == selectedMessages.count
    }
}
