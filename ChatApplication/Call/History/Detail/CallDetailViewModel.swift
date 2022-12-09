//
//  CallDetailViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation

class CallDetailViewModel: ObservableObject {
    @Published  var isLoading = false

    @Published  private(set) var model: CallDetailModel

    private(set) var connectionStatusCancelable: AnyCancellable?

    init(call: Call) {
        model = CallDetailModel(call: call)
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.model.calls.count == 0, status == .connected {
                self.getCallsHistory()
            }
        }
    }

    func getCallsHistory() {
        guard let threadId = model.call.conversation?.id else { return }
        Chat.sharedInstance.callsHistory(.init(count: 10, offset: 1, threadId: threadId)) { [weak self] calls, _, pagination, _ in
            if let calls = calls {
                self?.model.setCalls(calls: calls)
                self?.model.setHasNext(pagination?.hasNext ?? false)
            }
        }
    }

    func loadMore() {
        guard let threadId = model.call.conversation?.id else { return }
        if !model.hasNext || isLoading { return }
        isLoading = true
        model.preparePaginiation()
        Chat.sharedInstance.callsHistory(.init(count: model.count, offset: model.offset, threadId: threadId)) { [weak self] calls, _, _, _ in
            if let calls = calls {
                self?.model.appendCalls(calls: calls)
                self?.isLoading = false
            }
        }
    }

    func refresh() {
        clear()
        getCallsHistory()
    }

    func clear() {
        model.clear()
    }

    func setupPreview() {
        model.setupPreview()
    }
}
