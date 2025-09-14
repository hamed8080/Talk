//
//  FirstMessageOfTheDayViewModel.swift
//
//
//  Created by hamed on 10/13/24.
//

import Chat
import Combine
import Foundation
import Logger

@MainActor
final class FirstMessageOfTheDayViewModel {
    private let threadId: Int
    private let readOnly: Bool
    private let FIRST_MESSAGE_KEY: String
    private var highlight: Bool = false
    typealias ResponseType = ChatResponse<[Message]>
    public var completion: ((Message?) -> Void)?
    private var uniqueId: String?
    private var cancelable: AnyCancellable?

    public init(threadId: Int, readOnly: Bool) {
        self.threadId = threadId
        self.readOnly = readOnly
        let objectId = UUID().uuidString
        FIRST_MESSAGE_KEY = "FIRST-MESSAGE-OF-DAY-\(objectId)"
        Task { [weak self] in
            guard let self = self else { return }
            await registerObservers()
        }
    }

    private func registerObservers() {
        cancelable = NotificationCenter.message.publisher(for: .message).sink { [weak self] notif in
            if let event = notif.object as? MessageEventTypes {
                Task { [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
        }
    }

    func startOfDate(time: UInt, highlight: Bool) {
        let date = Date(milliseconds: Int64(time))
        let comp = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let startOfDate = Calendar.current.date(from: comp)?.millisecondsSince1970 else { return }
        self.highlight = highlight
        let req = makeRequest(fromTime: UInt(startOfDate), offset: 0, count: 1)
        uniqueId = req.uniqueId
        doRequest(req, FIRST_MESSAGE_KEY)
    }

    func onFirstMessage(_ response: ResponseType) async {
        completion?(response.result?.first)
    }

    private func doRequest(_ req: GetHistoryRequest, _ prepend: String) {
        RequestsManager.shared.append(prepend: prepend, value: req)
        log(req: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.history(req)
        }
    }

    private func makeRequest(fromTime: UInt? = nil, toTime: UInt? = nil, offset: Int?, count: Int = 25) -> GetHistoryRequest {
        GetHistoryRequest(threadId: threadId,
                          count: count,
                          fromTime: fromTime,
                          offset: offset,
                          order: fromTime != nil ? "asc" : "desc",
                          toTime: toTime,
                          readOnly: readOnly)
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

            if response.pop(prepend: FIRST_MESSAGE_KEY) != nil {
                await onFirstMessage(response)
            }
        }
    }

    func isContaninsKeys(_ response: ResponseType) -> Bool {
        response.uniqueId == uniqueId
    }

    private func log(req: GetHistoryRequest) {
        Logger.log(title: "FirstMessageOfTheDayViewModel",
                   message: "Start of sending history request: \(Date().millisecondsSince1970) milliseconds")
    }
}
