//
//  MessageSectionArray+.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import TalkModels

public typealias MyIndicies = (message: HistoryMessageType, indexPath: IndexPath)

extension ContiguousArray where Element == MessageSection {
    internal func sectionIndexByUniqueId(_ message: HistoryMessageType) -> SectionIndex? {
        sectionIndexByUniqueId(message.uniqueId ?? "")
    }

    internal func sectionIndexByUniqueId(_ uniqueId: String) -> SectionIndex? {
        if isEmpty { return nil }
        return firstIndex(where: { $0.vms.contains(where: {$0.message.uniqueId == uniqueId }) })
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
        if isEmpty { return nil }
        if indices.contains(indexPath.section), self[indexPath.section].vms.indices.contains(indexPath.row) {
            return self[indexPath.section].vms[indexPath.row]
        } else {
            return nil
        }
    }

    internal func sectionIndexByMessageId(_ message: HistoryMessageType) -> SectionIndex? {
        sectionIndexByMessageId(message.id ?? 0)
    }

    internal func sectionIndexByMessageId(_ id: Int) -> SectionIndex? {
        if isEmpty { return nil }
        return firstIndex(where: { $0.vms.contains(where: {$0.message.id == id }) })
    }

    internal func sectionIndexByDate(_ date: Date) -> SectionIndex? {
        if isEmpty { return nil }
        return firstIndex(where: { Calendar.current.isDate(date, inSameDayAs: $0.date)})
    }

    internal func messageIndex(_ messageId: Int, in section: SectionIndex) -> MessageIndex? {
        if isEmpty { return nil }
        return self[section].vms.firstIndex(where: { $0.id == messageId })
    }

    private func messageIndex(_ uniqueId: String, in section: SectionIndex) -> MessageIndex? {
        if isEmpty { return nil }
        return self[section].vms.firstIndex(where: { $0.message.uniqueId == uniqueId })
    }

    internal func message(for id: Int?) -> MyIndicies? {
        if isEmpty { return nil }
        guard
            let id = id,
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        let message = self[sectionIndex].vms[messageIndex].message
        return (message: message, indexPath: IndexPath(row: messageIndex, section: sectionIndex))
    }

    public func indicesByMessageUniqueId(_ uniqueId: String) -> IndexPath? {
        if isEmpty { return nil }
        guard
            let sectionIndex = sectionIndexByUniqueId(uniqueId),
            let messageIndex = messageIndex(uniqueId, in: sectionIndex)
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    internal func findIncicesBy(uniqueId: String?, _ id: Int?) -> IndexPath? {
        if isEmpty { return nil }
        guard
            uniqueId?.isEmpty == false,
            let sectionIndex = firstIndex(where: { $0.vms.contains(where: { $0.message.uniqueId == uniqueId || $0.id == id }) }),
            let messageIndex = self[sectionIndex].vms.firstIndex(where: { $0.message.uniqueId == uniqueId || $0.id == id })
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    public func indexPath(for viewModel: MessageRowViewModel) -> IndexPath? {
        if isEmpty {
            return nil
        }
        guard
            let sectionIndex = firstIndex(where: { $0.vms.contains(where: { $0.id == viewModel.id }) }),
            let messageIndex = self[sectionIndex].vms.firstIndex(where: { $0.id == viewModel.id })
        else {
            return nil
        }
        return .init(row: messageIndex, section: sectionIndex)
    }

    public func viewModelAndIndexPath(for id: Int?) -> (vm: MessageRowViewModel, indexPath: IndexPath)? {
        if isEmpty { return nil }
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
    public func indexPathBy(messageUniqueId uniqueId: String) -> IndexPath? {
        if isEmpty { return nil }
        var row: Int?
        var sectionIndex: Int?
        for (sIndex, section) in enumerated() {
            for (mIndex, vm) in section.vms.enumerated() {
                if vm.message.uniqueId == uniqueId {
                    row = mIndex
                    sectionIndex = sIndex
                    break
                }
            }
        }
        guard let sectionIndex = sectionIndex, let row = row else { return nil }
        return IndexPath(row: row, section: sectionIndex)
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
        if isEmpty { return nil }
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
        if isEmpty { return false }
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
        if isEmpty { return nil }
        guard
            thread.id == response.result?.threadId,
            let messageId = response.result?.messageId,
            let uniqueId = response.uniqueId
        else { return nil }
        let vm = messageViewModel(for: messageId) ?? messageViewModel(for: uniqueId)
        return vm
    }

    public func indexPathsForUpload(requests: [HistoryMessageType], beforeSectionCount: Int) -> (indices: [IndexPath], sectionIndex: IndexSet?) {
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

    public func previousIndexPath(_ currentIndexPath: IndexPath) -> IndexPath? {
        if isEmpty { return nil }
        // Check for end of the list
        if currentIndexPath.row == 0, currentIndexPath.section == 0 {
            return nil
        }

        // Check inside current section
        let previousIndexInSameSection = currentIndexPath.row - 1
        if self[currentIndexPath.section].vms.indices.contains(previousIndexInSameSection) {
            return IndexPath(row: previousIndexInSameSection, section: currentIndexPath.section)
        }

        // Check for previous section
        let previousSectionIndex = currentIndexPath.section - 1
        if indices.contains(previousSectionIndex) {
            let index = self[previousSectionIndex].vms.count - 1
            return IndexPath(row: Swift.max(0, index), section: previousSectionIndex)
        }

        return nil
    }

    public func nextIndexPath(_ currentIndexPath: IndexPath) -> IndexPath? {
        if isEmpty { return nil }
        // Check for end of the list
        if currentIndexPath.section > count - 1 {
            return nil
        }

        // Check inside current section
        let nextIndexInSameSection = currentIndexPath.row + 1
        if self[currentIndexPath.section].vms.indices.contains(nextIndexInSameSection) {
            return IndexPath(row: nextIndexInSameSection, section: currentIndexPath.section)
        }

        // Check for previous section
        let nextSectionIndex = currentIndexPath.section + 1
        if indices.contains(nextSectionIndex) {
            return IndexPath(row: 0, section: nextSectionIndex)
        }

        return nil
    }

    public func sameUserPrevIndex(_ message: Message) -> IndexPath? {
        if isEmpty { return nil }
        guard
            let uniqueId = message.uniqueId,
            let indexPath = indexPathBy(messageUniqueId: uniqueId),
            let prevIndexPath = previousIndexPath(indexPath)
        else { return nil }
        let isSame = self[prevIndexPath.section].vms[prevIndexPath.row].message.participant?.id == message.participant?.id
        return isSame ? prevIndexPath : nil
    }
    
    public func indexPathsAfter(indexPath: IndexPath, n: Int) -> [IndexPath] {
        var cells: [IndexPath] = []
        var indexPath = indexPath
        for i in 0..<n {
            if let nextIndexPath = nextIndexPath(indexPath) {
                cells.append(nextIndexPath)
                indexPath = nextIndexPath
            }
        }
        return cells
    }
    
    public func indexPathsBefore(indexPath: IndexPath, n: Int) -> [IndexPath] {
        var cells: [IndexPath] = []
        var indexPath = indexPath
        for i in 0..<n {
            if let nextIndexPath = previousIndexPath(indexPath) {
                cells.append(nextIndexPath)
                indexPath = nextIndexPath
            }
        }
        return cells
    }
}
