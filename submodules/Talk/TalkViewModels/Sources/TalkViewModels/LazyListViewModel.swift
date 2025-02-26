//
//  LazyListViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine

public class LazyListViewModel: ObservableObject {
    @Published public var isLoading: Bool = false
    public let count: Int
    public private(set) var offset: Int = 0
    private var hasNext = true
    private var threasholds: [Int] = []

    public init(count: Int = 15) {
        self.count = count
    }

    public func setLoading(_ value: Bool) {
        isLoading = value
    }

    public func canLoadMore() -> Bool {
        if isLoading || !hasNext { return false }
        return true
    }

    public func canLoadMore(id: Int?) -> Bool {
        if !canLoadMore() { return false }
        return threasholds.contains(where: {$0 == id})
    }

    public func isLoadingStatus() -> Bool {
        return isLoading
    }

    public func prepareForLoadMore() {
        if !hasNext { return }
        offset = offset + count
    }

    public func setHasNext(_ value: Bool) {
        hasNext = value
    }

    public func setThreasholdIds(ids: [Int]) {
        self.threasholds = ids
    }

    public func reset() {
        hasNext = true
        offset = 0
        isLoading = false
    }
}
