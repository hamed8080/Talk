//
//  PriorityQueue.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

public struct PriorityQueue<Element: Comparable> {
    private var elements: [Element] = []
    
    public mutating func enqueue(_ element: Element) {
        elements.append(element)
        elements.sort(by: >) // Higher priority first
    }
    
    public mutating func dequeue() -> Element? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }
    
    public mutating func removeAll() {
        elements.removeAll()
    }
    
    public func isEmpty() -> Bool {
        return elements.isEmpty
    }
    
    public mutating func remove(at index: Int) {
        elements.remove(at: index)
    }
    
    public func firstIndex(where predicate: (Element) -> Bool ) -> Int? {
        elements.firstIndex(where: predicate)
    }
    
    public func indices() -> Range<Int> {
        elements.indices
    }
    
    public func indexOf(_ index: Int) -> Element {
        return elements[index]
    }
}
