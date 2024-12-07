//
//  CallDetailModel.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat

public struct CallDetailModel: Sendable {
    public private(set) var count = 15
    public private(set) var offset = 0
    public private(set) var hasNext = true
    public private(set) var call: Call
    public private(set) var calls: [Call] = []

    public init(count: Int = 15, offset: Int = 0, hasNext: Bool = true, call: Call, calls: [Call] = []) {
        self.count = count
        self.offset = offset
        self.hasNext = hasNext
        self.call = call
        self.calls = calls
    }

    public mutating func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    public  mutating func preparePaginiation() {
        offset = calls.count
    }

    public mutating func setCalls(calls: [Call]) {
        self.calls = calls
    }

    public mutating func appendCalls(calls: [Call]) {
        self.calls.append(contentsOf: calls)
    }

    public mutating func clear() {
        offset = 0
        count = 15
        hasNext = true
        calls = []
    }
}
