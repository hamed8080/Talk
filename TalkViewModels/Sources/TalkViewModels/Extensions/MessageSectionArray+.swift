//
//  MessageSectionArray+.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat

public typealias MyIndicies = (message: MessageType, indexPath: IndexPath)

extension ContiguousArray where Element == MessageSection {
    internal func sectionIndexByUniqueId(_ message: MessageType) -> SectionIndex? {
        sectionIndexByUniqueId(message.uniqueId ?? "")
    }

    internal func sectionIndexByUniqueId(_ uniqueId: String) -> SectionIndex? {
        firstIndex(where: { $0.vms.contains(where: {$0.message.uniqueId == uniqueId }) })
    }

    internal func insertedIndices(insertTop: Bool, beforeSectionCount: Int, _ viewModels: [MessageRowViewModel]) -> (sections: IndexSet, rows: [IndexPath]) {
        // When beforeSectionCount == newSectionCount it means there is no change.
        var sectionsSet = IndexSet()
        let newSectionCount = count
        let newInsertedTopSectionCount = newSectionCount - beforeSectionCount
        if !insertTop, beforeSectionCount < newSectionCount {
            sectionsSet = IndexSet(beforeSectionCount..<newSectionCount)
        } else if insertTop, newInsertedTopSectionCount > 0 {
            sectionsSet = IndexSet(0..<newInsertedTopSectionCount)
        }
        let rows = viewModels.compactMap({ indexPath(for: $0) })
        return (sectionsSet, rows)
    }

    public func viewModelWith(_ indexPath: IndexPath) -> MessageRowViewModel? {
        if indices.contains(indexPath.section), self[indexPath.section].vms.indices.contains(indexPath.row) {
            return self[indexPath.section].vms[indexPath.row]
        } else {
            return nil
        }
    }

    internal func sectionIndexByMessageId(_ message: MessageType) -> SectionIndex? {
        sectionIndexByMessageId(message.id ?? 0)
    }

    internal func sectionIndexByMessageId(_ id: Int) -> SectionIndex? {
        firstIndex(where: { $0.vms.contains(where: {$0.message.id == id }) })
    }

    internal func sectionIndexByDate(_ date: Date) -> SectionIndex? {
        firstIndex(where: { Calendar.current.isDate(date, inSameDayAs: $0.date)})
    }

    internal func messageIndex(_ messageId: Int, in section: SectionIndex) -> MessageIndex? {
        self[section].vms.firstIndex(where: { $0.id == messageId })
    }

    private func messageIndex(_ uniqueId: String, in section: SectionIndex) -> MessageIndex? {
        self[section].vms.firstIndex(where: { $0.message.uniqueId == uniqueId })
    }

    internal func message(for id: Int?) -> MyIndicies? {
        guard
            let id = id,
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        let message = self[sectionIndex].vms[messageIndex].message
        return (message: message, indexPath: IndexPath(row: messageIndex, section: sectionIndex))
    }

    public func indicesByMessageUniqueId(_ uniqueId: String) -> IndexPath? {
        guard
            let sectionIndex = sectionIndexByUniqueId(uniqueId),
            let messageIndex = messageIndex(uniqueId, in: sectionIndex)
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    internal func findIncicesBy(uniqueId: String?, _ id: Int?) -> IndexPath? {
        guard
            uniqueId?.isEmpty == false,
            let sectionIndex = firstIndex(where: { $0.vms.contains(where: { $0.message.uniqueId == uniqueId || $0.id == id }) }),
            let messageIndex = self[sectionIndex].vms.firstIndex(where: { $0.message.uniqueId == uniqueId || $0.id == id })
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    public func indexPath(for viewModel: MessageRowViewModel) -> IndexPath? {
        guard
            let sectionIndex = firstIndex(where: { $0.vms.contains(where: { $0.id == viewModel.id }) }),
            let messageIndex = self[sectionIndex].vms.firstIndex(where: { $0.id == viewModel.id })
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    public func viewModelAndIndexPath(for id: Int?) -> (vm: MessageRowViewModel, indexPath: IndexPath)? {
        guard
            let id = id,
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        let vm = self[sectionIndex].vms[messageIndex]
        return (vm: vm, indexPath: IndexPath(row: messageIndex, section: sectionIndex))
    }

    @discardableResult
    public func messageViewModel(for messageId: Int) -> MessageRowViewModel? {
        return flatMap{$0.vms}.first(where: { $0.message.id == messageId })
    }

    @discardableResult
    public func messageViewModel(for uniqueId: String) -> MessageRowViewModel? {
        guard let indicies = indicesByMessageUniqueId(uniqueId) else {return nil}
        return self[indicies.section].vms[indicies.row]
    }


    /*
     In upload, we need speed to redraw the row so it's better to reverse search for the index path.
     And it prevents the use of the reverse function which is O(n), however,
     the function below is likely to be O(1) because we always insert at the bottom of a thread.
     */
    @discardableResult
    public func viewModelAndIndexPath(viewModelUniqueId uniqueId: String) -> (vm: MessageRowViewModel, indexPath: IndexPath)? {
        var sectionIndex = count - 1
        var rowIndex: Int? = nil
        while sectionIndex >= 0 {
            if let index = self[sectionIndex].vms.firstIndex(where: {$0.uniqueId == uniqueId}) {
                rowIndex = index
                break
            } else {
                sectionIndex = sectionIndex - 1
            }
        }
        guard let rowIndex = rowIndex else { return nil }
        let vm = self[sectionIndex].vms[rowIndex]
        return (vm, IndexPath(row: rowIndex, section: sectionIndex))
    }

    public func isLastSeenMessageExist(thread: Conversation?) -> Bool {
        let lastSeenId = thread?.lastSeenMessageId
        if lastSeenIsGreaterThanLastMessage(thread: thread) { return true }
        guard let lastSeenId = lastSeenId else { return false }
        var isExist = false
        // we get two bottom to check if it is in today list or previous day
        for section in suffix(2) {
            if section.vms.contains(where: {$0.message.id == lastSeenId }) {
                isExist = true
            }
        }
        return isExist
    }

    /// When we delete the last message, lastMessageSeenId is greater than currently lastMessageVO.id
    /// which is totally wrong and causes a lot of problems.
    private func lastSeenIsGreaterThanLastMessage(thread: Conversation?) -> Bool {
        return thread?.lastSeenMessageId ?? 0 > thread?.lastMessageVO?.id ?? 0
    }

    public func viewModel(_ thread: Conversation, _ response: ChatResponse<MessageResponse>) -> MessageRowViewModel? {
        guard
            thread.id == response.result?.threadId,
            let messageId = response.result?.messageId,
            let uniqueId = response.uniqueId
        else { return nil }
        let vm = messageViewModel(for: messageId) ?? messageViewModel(for: uniqueId)
        return vm
    }

    public func indexPathsForUpload(requests: [MessageType], beforeSectionCount: Int) -> (indices: [IndexPath], sectionIndex: IndexSet?) {
        var indicies: [IndexPath] = []
        for request in requests {
            if let uniqueId = request.uniqueId, let indexPath = indicesByMessageUniqueId(uniqueId) {
                indicies.append(indexPath)
            }
        }
        let afterSectionCount = count
        if afterSectionCount > beforeSectionCount {
            let secitonSet = IndexSet(beforeSectionCount..<afterSectionCount)
            return (indicies, secitonSet)
        }
        return (indicies, nil)
    }
}
