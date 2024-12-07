//
//  ArchiveThreadsViewModel.swift
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
public final class ArchiveThreadsViewModel: ObservableObject {
    public private(set) var count = 15
    public private(set) var offset = 0
    public private(set) var cancelable: Set<AnyCancellable> = []
    private(set) var hasNext: Bool = true
    public var isLoading = false
    private var canLoadMore: Bool { hasNext && !isLoading }
    public var archives: ContiguousArray<Conversation> = []
    private var threadsVM: ThreadsViewModel { AppState.shared.objectsContainer.threadsVM }
    private var objectId = UUID().uuidString
    private let GET_ARCHIVES_KEY: String

    public init() {
        GET_ARCHIVES_KEY = "GET-ARCHIVES-\(objectId)"
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

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .threads(let response):
            onArchives(response)
        case .archive(let response):
            onArchive(response)
        case .unArchive(let response):
            onUNArchive(response)
        default:
            break
        }
    }

    public func toggleArchive(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.isArchive == false {
            archive(threadId)
        } else {
            unarchive(threadId)
        }
    }

    public func archive(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.archive(.init(subjectId: threadId))
        }
    }

    public func unarchive(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.unarchive(.init(subjectId: threadId))
        }
    }

    public func getArchivedThreads() {
        isLoading = true
        let req = ThreadsRequest(count: count, offset: offset, archived: true)
        RequestsManager.shared.append(prepend: GET_ARCHIVES_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
        animateObjectWillChange()
    }

    public func onArchives(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, let archives = response.result, response.pop(prepend: GET_ARCHIVES_KEY) != nil {
            self.archives.append(contentsOf: archives.filter({$0.isArchive == true}))
        }
        isLoading = false
        animateObjectWillChange()
    }

    public func onArchive(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil, let index = threadsVM.threads.firstIndex(where: {$0.id == response.result}) {
            var conversation = threadsVM.threads[index]
            conversation.isArchive = true
            archives.append(conversation)
            threadsVM.threads.removeAll(where: {$0.id == response.result}) /// Do not remove this line and do not use remove(at:) it will cause 'Precondition failed Orderedset'
            threadsVM.sort()
            threadsVM.animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    public func onUNArchive(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil, let index = archives.firstIndex(where: {$0.id == response.result}) {
            var conversation = archives[index]
            conversation.isArchive = false
            archives.remove(at: index)
            threadsVM.threads.append(conversation)
            threadsVM.sort()
            threadsVM.animateObjectWillChange()
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
