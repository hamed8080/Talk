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

public enum LinkItem: Hashable, Sendable {
    case item(TabRowModel)
    case noResult
}

public enum LinksListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UILinksViewControllerDelegate: AnyObject {
    func apply(snapshot: NSDiffableDataSourceSnapshot<LinksListSection, LinkItem>, animatingDifferences: Bool)
}

@MainActor
public class DetailTabDownloaderViewModel: ObservableObject {
    public private(set) var messagesModels: ContiguousArray<TabRowModel> = []
    private var conversation: Conversation
    private var offset = 0
    private var cancelable = Set<AnyCancellable>()
    public private(set) var isLoading = false
    public private(set) var hasNext = true
    private let messageType: ChatModels.MessageType
    private let count = 25
    public var itemCount = 3
    private let tabName: String
    private var objectId = UUID().uuidString
    private let DETAIL_HISTORY_KEY: String
    public weak var linksDelegate: UILinksViewControllerDelegate?

    public init(conversation: Conversation, messageType: ChatModels.MessageType, tabName: String) {
        DETAIL_HISTORY_KEY = "DETAIL-HISTORY-\(tabName)-KEY-\(objectId)"
        self.tabName = tabName
        self.conversation = conversation
        self.messageType = messageType
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    await self.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    private func onMessageEvent(_ event: MessageEventTypes) async {
        switch event {
        case let .history(response):
            if !response.cache,
               response.subjectId == conversation.id,
               response.pop(prepend: DETAIL_HISTORY_KEY) != nil,
               let messages = response.result {

                for message in messages {
                    if !self.messagesModels.contains(where: { $0.id == message.id }) {
                        let model = await TabRowModel(message: message)
                        
                        /// Attach the avplayer to show progress form the postion the item is playing,
                        /// then append and attaching it to the list.
                        let activePlayingId = AppState.shared.objectsContainer.audioPlayerVM.message?.id
                        if activePlayingId == message.id {
                            model.itemPlayer = AppState.shared.objectsContainer.audioPlayerVM.item
                        }
                        
                        messagesModels.append(model)
                        
                        if model.links.isEmpty && model.message.type == .link {
                            messagesModels.removeLast()
                        }
                    }
                }
                self.messagesModels.sort(by: { $0.message.time ?? 0 > $1.message.time ?? 0 })
                
                hasNext = response.hasNext
                isLoading = false
                animateObjectWillChange()
            }
        default:
            break
        }
    }

    public func isCloseToLastThree(_ message: Message) -> Bool {
        let index = Array<TabRowModel>.Index(messagesModels.count - 3)
        if messagesModels.indices.contains(index), messagesModels[index].id == message.id {
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

    deinit {
#if DEBUG
        print("deinit DetailTabDownloaderViewModel for\(tabName)")
#endif
    }
}
