//
//  CallsHistoryViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import TalkModels

@MainActor
public class CallsHistoryViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public private(set) var model = CallsHistoryModel()
    public private(set) var connectionStatusCancelable: AnyCancellable?

    public init() {
//        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
//            if self.model.calls.count == 0, status == .connected {
//                self.getCallsHistory()
//            }
//        }
    }
    
    public func getCallsHistory() {
//        ChatManager.activeInstance?.call.callsHistory(.init(count: model.count, offset: model.offset)) { [weak self] response in
//            if let calls = response.result {
//                self?.model.setCalls(calls: calls)
//                self?.model.setHasNext(response.pagination?.hasNext ?? false)
//            }
//        }
    }
    
    public func loadMore() {
//        if !model.hasNext || isLoading { return }
//        isLoading = true
//        model.preparePaginiation()
//        ChatManager.activeInstance?.call.callsHistory(.init(count: model.count, offset: model.offset)) { [weak self] response in
//            if let calls = response.result {
//                self?.model.appendCalls(calls: calls)
//                self?.isLoading = false
//            }
//        }
    }

    public func refresh() {
        clear()
        getCallsHistory()
    }

    public func clear() {
        model.clear()
    }
}
