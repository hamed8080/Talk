//
//  DetailTabDownloaderViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import Combine
import SwiftUI
import TalkExtensions
import TalkModels

@MainActor
public class DetailTabDownloaderViewModel: ObservableObject {
    public private(set) var messages: ContiguousArray<Message> = []
    private var conversation: Conversation
    private var offset = 0
    private var cancelable = Set<AnyCancellable>()
    public private(set) var isLoading = false
    public private(set) var hasNext = true
    private let messageType: ChatModels.MessageType
    private let count = 25
    public var itemCount = 3
    private var downloadVMS: [DownloadFileViewModel] = []
    private let tabName: String
    private var objectId = UUID().uuidString
    private let DETAIL_HISTORY_KEY: String

    public init(conversation: Conversation, messageType: ChatModels.MessageType, tabName: String) {
        DETAIL_HISTORY_KEY = "DETAIL-HISTORY-\(tabName)-KEY-\(objectId)"
        self.tabName = tabName
        self.conversation = conversation
        self.messageType = messageType
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case let .history(response):
            if !response.cache,
               response.subjectId == conversation.id,
               response.pop(prepend: DETAIL_HISTORY_KEY) != nil,
               let messages = response.result {
                messages.forEach { message in
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                    }
                }
                self.messages.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
                hasNext = response.hasNext
                isLoading = false
                animateObjectWillChange()
            }
        default:
            break
        }
    }

    public func isCloseToLastThree(_ message: Message) -> Bool {
        let index = Array<Message>.Index(messages.count - 3)
        if messages.indices.contains(index), messages[index].id == message.id {
            return true
        } else {
            return false
        }
    }

    public func loadMore() {
        guard let conversationId = conversation.id, conversationId != LocalId.emptyThread.rawValue, !isLoading, hasNext else { return }
        let req: GetHistoryRequest = .init(threadId: conversationId, count: count, messageType: messageType.rawValue, offset: offset)
        RequestsManager.shared.append(prepend: DETAIL_HISTORY_KEY, value: req)
        offset += count
        isLoading = true
        animateObjectWillChange()
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.history(req)
        }
    }

    public func itemWidth(readerWidth: CGFloat) -> CGFloat {
        let modes: [WindowMode] = [.iPhone, .ipadOneThirdSplitView, .ipadSlideOver]
        let semiFullModes: [WindowMode] = [.ipadHalfSplitView, .ipadTwoThirdSplitView]
        let isInSemiFullMode = semiFullModes.contains(UIApplication.shared.windowMode())
        if modes.contains(UIApplication.shared.windowMode()) {
            itemCount = 3
            return readerWidth / 3
        } else if isInSemiFullMode {
            itemCount = 4
            return readerWidth / 4
        } else {
            itemCount = 5
            return readerWidth / 5
        }
    }

    public func downloadVM(message: Message) -> DownloadFileViewModel {
        if let localVM = downloadVMS.first(where: {$0.message?.id == message.id}) {
            return localVM
        } else {
            let newDownloadVM = DownloadFileViewModel(message: message)
            downloadVMS.append(newDownloadVM)
            return newDownloadVM
        }
    }
#if DEBUG
    deinit {
        print("deinit DetailTabDownloaderViewModel for\(tabName)")
    }
#endif
}
