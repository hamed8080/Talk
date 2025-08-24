//
//  CallDetailViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatModels
import Combine
import Foundation
import TalkModels

public class CallDetailViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public private(set) var model: CallDetailModel
    public private(set) var connectionStatusCancelable: AnyCancellable?

    public init(call: Call) {
        model = CallDetailModel(call: call)
//        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
//            if self.model.calls.count == 0, status == .connected {
//                self.getCallsHistory()
//            }
//        }
    }

    public func getCallsHistory() {
//        guard let threadId = model.call.conversation?.id else { return }
//        ChatManager.call?.callsHistory(.init(count: 10, offset: 1, threadId: threadId)) { [weak self] response in
//            if let calls = response.result {
//                self?.model.setCalls(calls: calls)
//                self?.model.setHasNext(response.pagination?.hasNext ?? false)
//            }
//        }
    }

    public func loadMore() {
//        guard let threadId = model.call.conversation?.id else { return }
//        if !model.hasNext || isLoading { return }
//        isLoading = true
//        model.preparePaginiation()
//        ChatManager.call?.callsHistory(.init(count: model.count, offset: model.offset, threadId: threadId)) { [weak self] response in
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
