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
import Logger

@MainActor
public final class ArchiveThreadsViewModel: ObservableObject {
    public private(set) var count = 15
    public private(set) var offset = 0
    public private(set) var cancelable: Set<AnyCancellable> = []
    private(set) var hasNext: Bool = true
    public var isLoading = false
    public private(set) var firstSuccessResponse = false
    private var canLoadMore: Bool { hasNext && !isLoading }
    public var archives: ContiguousArray<CalculatedConversation> = []
    private var threadsVM: ThreadsViewModel { AppState.shared.objectsContainer.threadsVM }
    private var objectId = UUID().uuidString
    private let GET_ARCHIVES_KEY: String
    private var wasDisconnected = false
    internal let incQueue = IncommingMessagesQueue()
    
    // MARK: Computed properties
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }
    private var myId: Int { AppState.shared.user?.id ?? -1 }
    
    public init() {
        GET_ARCHIVES_KEY = "GET-ARCHIVES-\(objectId)"
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onThreadEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onParticipantEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    self?.onCancelTimer(key: key)
                }
            }
            .store(in: &cancelable)
        AppState.shared.$connectionStatus
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onConnectionStatusChanged(event)
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
            await onArchives(response)
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
        case .unreadCount(let response):
            await onUnreadCounts(response)
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .new(let chatResponse):
            onNewMessage(chatResponse)
        case .forward(let chatResponse):
            incQueue.onMessageEvent(chatResponse)
        case .seen(let response):
            onSeen(response)
        case .deleted(let response):
            await onMessageDeleted(response)
        case .pin(let response):
            onPinMessage(response)
        case .unpin(let response):
            onUNPinMessage(response)
        default:
            break
        }
    }
    
    @MainActor
    func onParticipantEvent(_ event: ParticipantEventTypes) async {
        switch event {
        case .add(let chatResponse):
            await onAddPrticipant(chatResponse)
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
    
    public func getArchivedThreads(withQueue: Bool = false) {
        if !TokenManager.shared.isLoggedIn { return }
        isLoading = true
        let req = ThreadsRequest(count: count, offset: offset, archived: true)
        RequestsManager.shared.append(prepend: GET_ARCHIVES_KEY, value: req)
        Task { @ChatGlobalActor in
            if withQueue {
                await AppState.shared.objectsContainer.chatRequestQueue.enqueue(.getArchives(req: req))
            } else {
                ChatManager.activeInstance?.conversation.get(req)
            }
        }
        animateObjectWillChange()
    }

    public func getArchivedThread(threadId: Int) {
        if !TokenManager.shared.isLoggedIn { return }
        isLoading = true
        let req = ThreadsRequest(count: 1, offset: 0, archived: true, threadIds: [threadId])
        RequestsManager.shared.append(prepend: GET_ARCHIVES_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
        animateObjectWillChange()
    }

    @AppBackgroundActor
    public func onArchives(_ response: ChatResponse<[Conversation]>) async {
        if !response.cache, let archivesResp = response.result, response.pop(prepend: GET_ARCHIVES_KEY) != nil {
            let calculatedThreads = await ThreadCalculators.calculate(archivesResp, myId, navVM.selectedId, false)
            let newThreads = await appendThreads(newThreads: calculatedThreads, oldThreads: self.archives)
            let sorted = await sort(threads: newThreads)
            await MainActor.run {
                setHasNextOnResponse(response)
                self.archives = sorted
                isLoading = false
                firstSuccessResponse = true
                animateObjectWillChange()
            }
        }
    }

    public func onArchive(_ response: ChatResponse<Int>) async {
        if response.result != nil, response.error == nil, let index = threadsVM.threads.firstIndex(where: {$0.id == response.result}) {
            var conversation = threadsVM.threads[index]
            conversation.isArchive = true
            conversation.mute = true
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.reCalculate(conversation, myId, navVM.selectedId)
            archives.append(calThreads)
            threadsVM.threads.removeAll(where: {$0.id == response.result}) /// Do not remove this line and do not use remove(at:) it will cause 'Precondition failed Orderedset'
            await threadsVM.sortInPlace()
            threadsVM.animateObjectWillChange()
            animateObjectWillChange()
        } else if let conversationId = response.result {
            /// New conversation has been archived by another device so we have to fetch the conversation
            getArchivedThread(threadId: conversationId)
        }
    }

    public func onUNArchive(_ response: ChatResponse<Int>) async {
        if response.result != nil, response.error == nil, let index = archives.firstIndex(where: {$0.id == response.result}) {
            var conversation = archives[index]
            conversation.isArchive = false
            conversation.mute = nil
            archives.remove(at: index)
            let calThreads = await ThreadCalculators.reCalculate(conversation, myId, navVM.selectedId)
            threadsVM.threads.append(calThreads)
            await threadsVM.sortInPlace()
            threadsVM.animateObjectWillChange()
            animateObjectWillChange()
        }
    }
    
    @MainActor
    public func appendThreads(newThreads: [CalculatedConversation], oldThreads: ContiguousArray<CalculatedConversation>)
    async -> ContiguousArray<CalculatedConversation> {
        var arr = oldThreads
        for thread in newThreads {
            if var oldThread = oldThreads.first(where: { $0.id == thread.id }) {
                await oldThread.updateValues(thread)
            } else {
                arr.append(thread)
            }
        }
        return arr
    }

    @AppBackgroundActor
    public func sort(threads: ContiguousArray<CalculatedConversation>) async -> ContiguousArray<CalculatedConversation> {
        var threads = threads
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && ($1.pin == false || $1.pin == nil) })
        return threads
    }
    
    private func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if status == .connected {
            // After connecting again
            // We should call this method because if the token expire all the data inside InMemory Cache of the SDK is invalid
            wasDisconnected = true
            /// We sleep for 1 second to prevent getting banned by the server after reconnecting.
            try? await Task.sleep(for: .seconds(1))
            await refresh()
        } else if status == .disconnected && !firstSuccessResponse {
            // To get the cached version of the threads in SQLITE.
            await getArchivedThreads()
        }
    }

    private func setHasNextOnResponse(_ response: ChatResponse<[Conversation]>) {
        if !response.cache {
            hasNext = response.hasNext
        }
    }

    private func onCancelTimer(key: String) {
        if isLoading {
            isLoading = false
            animateObjectWillChange()
        }
    }
    
    public func refresh() async {
        archives.removeAll()
        offset = 0
        getArchivedThreads(withQueue: true)
    }

    private func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = archives.firstIndex(where: {$0.id == message.conversation?.id}) {
            let reference = archives[index]
            let old = reference.toStruct()
            let updated = reference.updateOnNewMessage(response.result ?? .init(), meId: myId)
            archives[index] = updated
            archives[index].animateObjectWillChange()
            recalculateAndAnimate(updated)
            updateActiveConversationOnNewMessage([message], updated.toStruct(), old)
            animateObjectWillChange()
        }
    }
    
    private func updateActiveConversationOnNewMessage(_ messages: [Message], _ updatedConversation: Conversation, _ oldConversation: Conversation?) {
        let activeVM = navVM.presentedThreadViewModel?.viewModel
        if updatedConversation.id == activeVM?.threadId {
            Task {
                await activeVM?.historyVM.onNewMessage(messages, oldConversation, updatedConversation)
            }
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
        if response.result?.id == myId {
            archives.removeAll(where: {$0.id == response.subjectId})
            animateObjectWillChange()
        }
    }
    
    private func onClosed(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = archives.firstIndex(where: { $0.id == id }) {
            archives[index].closed = true
            let activeThread = navVM.viewModel(for: id)
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

            let calculated = ThreadCalculators.calculate(arrItem.toStruct(), myId)
            
            archives[index] = calculated
            archives[index].animateObjectWillChange()

            // Update active thread if it is open
            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = calculated.toStruct()
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            activeThread?.delegate?.refetchImageOnUpdateInfo()

            // Update active thread detail view if it is open
            if let detailVM = navVM.detailViewModel(threadId: threadId) {
                detailVM.updateThreadInfo(calculated.toStruct())
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
    
    private func recalculateAndAnimate(_ thread: CalculatedConversation) {
        Task {
            await ThreadCalculators.reCalculate(thread, myId, navVM.selectedId)
            thread.animateObjectWillChange()
        }
    }
    
    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = firstIndex(thread.id) {
            archives[index].lastMessage = thread.lastMessage
            archives[index].lastMessageVO = thread.lastMessageVO
            archives[index].animateObjectWillChange()
            recalculateAndAnimate(archives[index])
            animateObjectWillChange()
        }
    }
    
    @MainActor
    func onUnreadCounts(_ response: ChatResponse<[String : Int]>) async {
        response.result?.forEach { key, value in
            if let index = firstIndex(Int(key)) {
                archives[index].unreadCount = value
                Task {
                    await ThreadCalculators.reCalculateUnreadCount(archives[index])
                    archives[index].animateObjectWillChange()
                }
            }
        }
        log("SERVER unreadCount: \(response.result)")
    }

    public func updateThreadInfo(_ thread: Conversation) {
        if let threadId = thread.id, let index = firstIndex(threadId) {
            let replacedEmoji = thread.titleRTLString.stringToScalarEmoji()
            /// In the update thread info, the image property is nil and the metadata link is been filled by the server.
            /// So to update the UI properly we have to set it to link.
            var arrItem = archives[index]
            if let metadata = thread.metaData {
                arrItem.image = metadata.file?.link
                arrItem.computedImageURL = ThreadCalculators.calculateImageURL( arrItem.image, metadata)
            }
            arrItem.metadata = thread.metadata
            arrItem.title = replacedEmoji
            arrItem.closed = thread.closed
            arrItem.time = thread.time ?? arrItem.time
            arrItem.userGroupHash = thread.userGroupHash ?? arrItem.userGroupHash
            arrItem.description = thread.description

            archives[index] = arrItem
            archives[index].animateObjectWillChange()

            // Update active thread if it is open
            let activeThread = navVM.viewModel(for: threadId)
            activeThread?.thread = arrItem.toStruct()
            activeThread?.delegate?.updateTitleTo(replacedEmoji)
            activeThread?.delegate?.refetchImageOnUpdateInfo()

            // Update active thread detail view if it is open
            if let detailVM = navVM.detailViewModel(threadId: threadId) {
                detailVM.updateThreadInfo(arrItem.toStruct())
            }
            animateObjectWillChange()
        }
    }
    
    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) async {
        if let index = firstIndex(response.subjectId) {
            var thread = archives[index]
            if response.result?.unreadCount == 0, thread.mentioned == true {
                thread.mentioned = false
            }
            if response.result?.lastSeenMessageTime ?? 0 > thread.lastSeenMessageTime ?? 0 {
                thread.lastSeenMessageTime = response.result?.lastSeenMessageTime
                thread.lastSeenMessageId = response.result?.lastSeenMessageId
                thread.lastSeenMessageNanos = response.result?.lastSeenMessageNanos
                let newCount = response.result?.unreadCount ?? response.contentCount ?? 0
                if newCount <= archives[index].unreadCount ?? 0 {
                    thread.unreadCount = newCount
                    await ThreadCalculators.reCalculateUnreadCount(archives[index])
                    
                    /// If the user open up the same thread on two devices at the same time,
                    /// and on of them is at the bottom of the thread and one is at top,
                    /// the one at bottom will send seen and respectively when we send seen unread count will be reduced,
                    /// so on another thread we should catch this new unread count and update the thread.
                    let activeVM = navVM.viewModel(for: response.subjectId ?? -1)
                    activeVM?.delegate?.onUnreadCountChanged()
                }
            }
            archives[index] = thread
            archives[index].animateObjectWillChange()
            animateObjectWillChange()
        }
    }
   
    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        /// Update the status bar in ThreadRow when a receiver seen a message, and in the sender side we have to update the UI.
        let isMe = myId == response.result?.participantId
        if !isMe, let index = archives.firstIndex(where: {$0.lastMessageVO?.id == response.result?.messageId}) {
            archives[index].lastMessageVO?.delivered = true
            archives[index].lastMessageVO?.seen = true
            archives[index].partnerLastSeenMessageId = response.result?.messageId
            recalculateAndAnimate(archives[index])
        }
        log("SERVER OnSeen: \(response.result)")
    }
    
    /// This method only reduce the unread count if the deleted message has sent after lastSeenMessageTime.
    public func onMessageDeleted(_ response: ChatResponse<Message>) async {
        guard let index = archives.firstIndex(where: { $0.id == response.subjectId }) else { return }
        var thread = archives[index]
        if response.result?.time ?? 0 > thread.lastSeenMessageTime ?? 0, thread.unreadCount ?? 0 >= 1 {
            thread.unreadCount = (thread.unreadCount ?? 0) - 1
            await ThreadCalculators.reCalculateUnreadCount(archives[index])
            archives[index] = thread
            archives[index].animateObjectWillChange()
            recalculateAndAnimate(thread)
        }
    }

    public func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            archives[threadIndex].pinMessage = response.result
            archives[threadIndex].animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    public func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.result != nil, let threadIndex = firstIndex(response.subjectId) {
            archives[threadIndex].pinMessage = nil
            archives[threadIndex].animateObjectWillChange()
            animateObjectWillChange()
        }
    }
    
    public func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        archives.firstIndex(where: { $0.id == threadId ?? -1 })
    }
    
    func onAddPrticipant(_ response: ChatResponse<Conversation>) async {
        if response.result?.participants?.first(where: {$0.id == myId}) != nil, let newConversation = response.result {
            /// It means an admin added a user to the conversation, and if the added user is in the app at the moment, should see this new conversation in its conversation list.
            var newConversation = newConversation
            newConversation.reactionStatus = newConversation.reactionStatus ?? .enable
            await calculateAppendSortAnimate(newConversation)
        }
    }
    
    public func calculateAppendSortAnimate(_ thread: Conversation) async {
        let calThreads = await ThreadCalculators.calculate([thread], myId, navVM.selectedId, false)
        let appendedThreads = await appendThreads(newThreads: calThreads, oldThreads: archives)
        let sorted = await sort(threads: appendedThreads)
        archives = sorted
        animateObjectWillChange()
    }
    
    func log(_ string: String) {
        Logger.log(title: "ArchiveThreadsViewModel", message: string)
    }
}
