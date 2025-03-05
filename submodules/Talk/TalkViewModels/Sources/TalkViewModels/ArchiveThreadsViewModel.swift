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
    public var archives: ContiguousArray<CalculatedConversation> = []
    private var threadsVM: ThreadsViewModel { AppState.shared.objectsContainer.threadsVM }
    private var objectId = UUID().uuidString
    private let GET_ARCHIVES_KEY: String
    public var hasShownToastGuide = false

    public init() {
        GET_ARCHIVES_KEY = "GET-ARCHIVES-\(objectId)"
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task {
                    await self?.onThreadEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
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
        getArchivedThreads()
    }

    private func onThreadEvent(_ event: ThreadEventTypes?) async {
        switch event {
        case .threads(let response):
            onArchives(response)
        case .archive(let response):
            await onArchive(response)
        case .unArchive(let response):
            await onUNArchive(response)
        case .lastMessageDeleted(let response):
            onLastMessageDeleted(response)
        case .lastMessageEdited(let response):
            onLastMessageEdited(response)
        case .left(let response):
            onLeave(response)
        case .closed(let response):
            onClosed(response)
        case .updatedInfo(let response):
            onUpdateThreadInfo(response)
        case .deleted(let response):
            onDeleteThread(response)
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .new(let chatResponse):
            onNewMessage(chatResponse)
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
            let filtered = archives.filter { archive in
                return !self.archives.contains(where: {$0.id == archive.id})
            }
            let myId = AppState.shared.user?.id ?? -1
            Task {
                let calThreads = await ThreadCalculators.calculate(filtered, myId, nil, false)
                self.archives.append(contentsOf: calThreads)
                isLoading = false
                animateObjectWillChange()
            }
        }
    }

    public func onArchive(_ response: ChatResponse<Int>) async {
        if response.result != nil, response.error == nil, let index = threadsVM.threads.firstIndex(where: {$0.id == response.result}) {
            var conversation = threadsVM.threads[index]
            conversation.isArchive = true
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.reCalculate(conversation, myId, AppState.shared.objectsContainer.navVM.selectedId)
            archives.append(calThreads)
            threadsVM.threads.removeAll(where: {$0.id == response.result}) /// Do not remove this line and do not use remove(at:) it will cause 'Precondition failed Orderedset'
            await threadsVM.sortInPlace()
            threadsVM.animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    public func onUNArchive(_ response: ChatResponse<Int>) async {
        if response.result != nil, response.error == nil, let index = archives.firstIndex(where: {$0.id == response.result}) {
            var conversation = archives[index]
            conversation.isArchive = false
            archives.remove(at: index)
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.reCalculate(conversation, myId, AppState.shared.objectsContainer.navVM.selectedId)
            threadsVM.threads.append(calThreads)
            await threadsVM.sortInPlace()
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

    private func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = archives.firstIndex(where: {$0.id == message.conversation?.id}) {
            let old = archives[index]
            let updated = old.updateOnNewMessage(response.result ?? .init(), meId: AppState.shared.user?.id)
            archives[index] = updated
            animateObjectWillChange()
        }
    }

    private func onLastMessageDeleted(_ response: ChatResponse<Conversation>) {
        if let conversation = response.result, let index = archives.firstIndex(where: {$0.id == conversation.id}) {
            var current = archives[index]
            current.lastMessageVO = conversation.lastMessageVO
            current.lastMessage = conversation.lastMessage
            archives[index] = current
            animateObjectWillChange()
        }
    }

    private func onLastMessageEdited(_ response: ChatResponse<Conversation>) {
        if let conversation = response.result, let index = archives.firstIndex(where: {$0.id == conversation.id}) {
            var current = archives[index]
            current.lastMessageVO = conversation.lastMessageVO
            current.lastMessage = conversation.lastMessage
            archives[index] = current
            animateObjectWillChange()
        }
    }
    
    private func onLeave(_ response: ChatResponse<User>) {
        if response.result?.id == AppState.shared.user?.id ?? -1 {
            archives.removeAll(where: {$0.id == response.subjectId})
            animateObjectWillChange()
        }
    }
    
    private func onClosed(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = archives.firstIndex(where: { $0.id == id }) {
            archives[index].closed = true
            let activeThread = AppState.shared.objectsContainer.navVM.viewModel(for: id)
            activeThread?.thread = archives[index].toStruct()
            activeThread?.delegate?.onConversationClosed()
            animateObjectWillChange()
        }
    }
    
    private func onUpdateThreadInfo(_ response: ChatResponse<Conversation>) {
        if let thread = response.result,
           let threadId = thread.id,
           let index = archives.firstIndex(where: {$0.id == threadId}) {
            
            let replacedEmoji = thread.titleRTLString.stringToScalarEmoji()
            /// In the update thread info, the image property is nil and the metadata link is been filled by the server.
            /// So to update the UI properly we have to set it to link.
            var arrItem = archives[index]
            if let metadatImagelink = thread.metaData?.file?.link {
                arrItem.image = metadatImagelink
            }
            arrItem.title = replacedEmoji
            arrItem.closed = thread.closed
            arrItem.time = thread.time ?? arrItem.time
            arrItem.userGroupHash = thread.userGroupHash ?? arrItem.userGroupHash
            arrItem.description = thread.description

            let calculated = ThreadCalculators.calculate(arrItem.toStruct(),AppState.shared.user?.id ?? -1)
            
            archives[index] = calculated
            archives[index].animateObjectWillChange()

            // Update active thread if it is open
            let activeThread = AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
            activeThread?.thread = calculated.toStruct()
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            activeThread?.delegate?.refetchImageOnUpdateInfo()

            // Update active thread detail view if it is open
            if AppState.shared.objectsContainer.threadDetailVM.thread?.id == threadId {
                AppState.shared.objectsContainer.threadDetailVM.updateThreadInfo(calculated.toStruct())
            }
            animateObjectWillChange()
        }
    }
    
    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if let threadId = response.subjectId, let index = archives.firstIndex(where: {$0.id == threadId }) {
            archives.remove(at: index)
            animateObjectWillChange()
        }
    }
}
