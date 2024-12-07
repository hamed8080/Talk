//
//  FoldersViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import TalkModels
import TalkExtensions
import OSLog

@MainActor
public final class FoldersViewModel: ObservableObject {
    public private(set) var count = 15
    public private(set) var offset = 0
    public private(set) var cancelable: Set<AnyCancellable> = []
    private(set) var hasNext: Bool = true
    public var isLoading = false
    private var canLoadMore: Bool { hasNext && !isLoading }
    private var threadsVM: ThreadsViewModel { AppState.shared.objectsContainer.threadsVM }
    public var selectedFolder: Tag?
    public var threads: ContiguousArray<Conversation> = []
    private var objectId = UUID().uuidString
    private let CONVERSATION_INSIDE_FOLDER_KEY: String

    public init() {
        CONVERSATION_INSIDE_FOLDER_KEY = "CONVERSATION-INSIDE-FOLDER-\(objectId)"
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink{ [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    self?.onCancelTimer(key: key)
                }
            }
            .store(in: &cancelable)
    }

    public func loadMore() {
        if !canLoadMore { return }
        offset = count + offset
    }

    public func getThreadsInsideFolder(_ folder: Tag) {
        self.selectedFolder = folder
        let threadIds = folder.tagParticipants?.compactMap(\.conversation?.id) ?? []
        getThreadsWith(threadIds)
    }

    public func getThreadsWith(_ threadIds: [Int]) {
        if threadIds.count == 0 { return }
        isLoading = true
        let req = ThreadsRequest(threadIds: threadIds)
        RequestsManager.shared.append(prepend: CONVERSATION_INSIDE_FOLDER_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
        animateObjectWillChange()
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .threads(let response):
            onConversationInsideFolder(response)
        default:
            break
        }
    }

    private func onConversationInsideFolder(_ response: ChatResponse<[Conversation]>) {
        if response.pop(prepend: CONVERSATION_INSIDE_FOLDER_KEY) != nil {
            threads.append(contentsOf: response.result ?? [])
            animateObjectWillChange()
        }
    }

    private func setHasNextOnResponse(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, response.result?.count ?? 0 > 0 {
            hasNext = response.hasNext
        }
    }

    private func onCancelTimer(key: String) {
        if isLoading {
            isLoading = false
            animateObjectWillChange()
        }
    }
}
