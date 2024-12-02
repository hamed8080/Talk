//
//  MiddleHistoryFetcherViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Foundation
import OSLog
import Chat
import Combine

final class MiddleHistoryFetcherViewModel {
    private weak var historyVM: ThreadHistoryViewModel?
    private let TO_TIME_KEY: String
    private let FROM_TIME_KEY: String
    private var messageId: Int = -1
    private var time: UInt = 0
    private var highlight: Bool = false
    private var messages: [Message] = []
    private let threadId: Int
    typealias ResponseType = ChatResponse<[Message]>
    public var completion: ((ResponseType) -> Void)?
    private var toTimeUniqueId: String?
    private var fromTimeUniqueId: String?
    private var topPartCompleted: Bool = false
    private var bottomPartCompleted: Bool = false
    private var cancelable: AnyCancellable?

    public init(historyVM: ThreadHistoryViewModel) {
        self.threadId = historyVM.viewModel?.threadId ?? -1
        self.historyVM = historyVM
        let objectId = UUID().uuidString
        TO_TIME_KEY = "TO-TIME-\(objectId)"
        FROM_TIME_KEY = "FROM-TIME-\(objectId)"
        registerObservers()
    }

    private func registerObservers() {
        cancelable = NotificationCenter.message.publisher(for: .message).sink { [weak self] notif in
            Task { @HistoryActor [weak self] in
                if let event = notif.object as? MessageEventTypes {
                    await self?.onMessageEvent(event)
                }
            }
        }
    }

    func start(time: UInt, messageId: Int, highlight: Bool) {
        self.time = time
        self.messageId = messageId
        self.highlight = highlight
        messages.removeAll()
        topPart()
    }

    func topPart() {
        let toTimeReq = makeRequest(toTime: time, offset: nil)
        toTimeUniqueId = toTimeReq.uniqueId
        doRequest(toTimeReq, TO_TIME_KEY)
    }

    func onTopPart(_ response: ResponseType) {
        messages.append(contentsOf: response.result ?? [])
        fetchBottomPart()
    }

    func fetchBottomPart() {
        let fromTimeRequest = makeRequest(fromTime: time, offset: nil)
        fromTimeUniqueId = fromTimeRequest.uniqueId
        doRequest(fromTimeRequest, FROM_TIME_KEY)
    }

    func onBottomPart(_ response: ResponseType) async {
        await processBottomPart(response)
    }

    private func processBottomPart(_ response: ResponseType) async {
        messages.append(contentsOf: response.result ?? [])
        let response = ResponseType(uniqueId: response.uniqueId,
                                    result: messages,
                                    error: response.error,
                                    contentCount: response.contentCount,
                                    hasNext: messages.count >= 25,
                                    cache: response.cache,
                                    subjectId: response.subjectId,
                                    time: response.time,
                                    typeCode: response.typeCode)
        completion?(response)
    }

    private func doRequest(_ req: GetHistoryRequest, _ prepend: String) {
        RequestsManager.shared.append(prepend: prepend, value: req)
        log(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func makeRequest(fromTime: UInt? = nil, toTime: UInt? = nil, offset: Int?) -> GetHistoryRequest {
        GetHistoryRequest(threadId: threadId,
                          count: 25,
                          fromTime: fromTime,
                          offset: offset,
                          order: fromTime != nil ? "asc" : "desc",
                          toTime: toTime,
                          readOnly: historyVM?.viewModel?.readOnly == true)
    }

    private func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .history(let response):
            await onHistory(response)
        default:
            break
        }
    }

    private func onHistory(_ response: ResponseType) async {
        if !response.cache, response.subjectId == threadId {
            /// For the sixth scenario.
            if let request = response.pop(prepend: TO_TIME_KEY) {
                await onTopPart(response)
            }

            if let request = response.pop(prepend: FROM_TIME_KEY) {
                await onBottomPart(response)
            }
        }
    }

    private func cleanUp() {
        messageId = -1
        time = 0
        highlight = false
        messages = []
    }

    func isContaninsKeys(_ response: ResponseType) -> Bool {
        fromTimeUniqueId == response.uniqueId || response.uniqueId == toTimeUniqueId
    }

    private func log(req: GetHistoryRequest) {
#if DEBUG
        Task.detached {
            let date = Date().millisecondsSince1970
            Logger.viewModels.debug("Start of sending history request: \(date) milliseconds")
        }
#endif
    }
}
