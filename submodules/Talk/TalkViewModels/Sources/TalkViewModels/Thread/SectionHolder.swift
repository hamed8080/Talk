//
//  SectionHolder.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 2/24/25.
//

import Foundation
import Chat

@MainActor
public final class SectionHolder {
    public private(set) var sections: ContiguousArray<MessageSection> = .init()
    public private(set) var isUpdating: Bool = false
    public weak var delegate: HistoryScrollDelegate?
    
    public nonisolated init() {}
    
    public func setSections(_ sections: ContiguousArray<MessageSection>) {
        self.sections = sections
    }
    
    public func removeAll() {
        sections.removeAll()
        delegate?.reload()
    }
    
    public func deleteIndices(_ indices: [IndexPath]) {
        var sectionsToDelete: [Int] = []
        var rowsToDelete: [IndexPath] = indices
        
        Dictionary(grouping: indices, by: {$0.section}).forEach { section, indexPaths in
            for indexPath in indexPaths.sorted(by: {$0.row > $1.row}) {
                guard isSectionAndRowExist(indexPath) else {
                    /// We couldn't find the indexPath as a result of a bug that we should investigate.
                    /// To prevent the crash we will remove it from pending delete rows
                    rowsToDelete.removeAll(where: { $0.section == indexPath.section && $0.row == indexPath.row})
                    continue
                }
                sections[indexPath.section].vms.remove(at: indexPath.row)
                if sections[indexPath.section].vms.isEmpty {
                    sections.remove(at: indexPath.section)
                    sectionsToDelete.append(indexPath.section)
                }
            }
        }
        
        /// Remove all deleted sections from rowsToDelete to just delete rows in a section.
        rowsToDelete.removeAll(where: { sectionsToDelete.contains($0.section) })
        
        let sectionsSet = sectionsToDelete.sorted().map{ IndexSet($0..<$0+1) }
        delegate?.delete(sections: sectionsSet, rows: rowsToDelete)
    }
    
    public func append(section: Int, vm: MessageRowViewModel) {
        sections[section].vms.append(vm)
        if let lastIndex = sections[section].vms.indices.last {
            let indexPath = IndexPath(row: lastIndex, section: section)
            delegate?.inserted(at: indexPath)
        }
    }
    
    public func reload(at: IndexPath, vm: MessageRowViewModel) {
        sections[at.section].vms[at.row] = vm
        delegate?.reloadData(at: at)
    }

    private func isSectionAndRowExist(_ indexPath: IndexPath) -> Bool {
        guard sections.indices.contains(where: {$0 == indexPath.section}) else { return false }
        return sections[indexPath.section].vms.indices.contains(where: {$0 == indexPath.row})
    }
}
