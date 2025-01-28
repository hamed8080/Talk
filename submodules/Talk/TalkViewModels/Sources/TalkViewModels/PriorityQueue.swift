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
}
