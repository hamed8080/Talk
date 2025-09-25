//
//  ThreadsSearchViewModel.swift
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
public final class ThreadsSearchViewModel: ObservableObject {
    @Published public var searchedConversations: ContiguousArray<CalculatedConversation> = []
    @Published public var searchedContacts: ContiguousArray<Contact> = []
    @Published public var searchText: String = ""
    private var cancelable: Set<AnyCancellable> = []
    @Published public var selectedFilterThreadType: ThreadTypes?
    @Published public var showUnreadConversations: Bool? = nil
    private var cachedAttribute: [String: AttributedString] = [:]
    public var isInSearchMode: Bool { searchText.count > 0 || (!searchedConversations.isEmpty || !searchedContacts.isEmpty) }
    public private(set) var lazyList = LazyListViewModel()

    public init() {
        setupObservers()
    }

    private func setupObservers() {
        lazyList.objectWillChange.sink { [weak self] _ in
            self?.animateObjectWillChange()
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
        $searchText
            .dropFirst() // Drop first to prevent send request for the first time app launches
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] newValue in
                Task { [weak self] in
                    await self?.onSearchTextChanged(newValue)
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

        $showUnreadConversations.sink { [weak self] newValue in
            Task { [weak self] in
                await self?.onUnreadConversationToggled(newValue)
            }
        }
        .store(in: &cancelable)
    }

    private func onSearchTextChanged(_ newValue: String) async {
        if newValue.first == "@", newValue.count > 2 {
            reset()
            let startIndex = newValue.index(newValue.startIndex, offsetBy: 1)
            let newString = newValue[startIndex..<newValue.endIndex]
            await searchPublicThreads(String(newString))
        } else if newValue.first != "@" && !newValue.isEmpty {
            reset()
            await searchThreads(newValue, new: showUnreadConversations)
            await searchContacts(newValue)
        } else if newValue.count == 0, await !lazyList.isLoading {
            reset()
        }
    }

    private func onUnreadConversationToggled(_ newValue: Bool?) async {
        if newValue == true {
            await getUnreadConversations()
        } else if newValue == false, isInSearchMode {
            await resetUnreadConversations()
        }
    }

    public func loadMore() async {
        if await !lazyList.canLoadMore() { return }
        lazyList.prepareForLoadMore()
        await searchThreads(searchText, new: showUnreadConversations, loadMore: true)
    }

    private func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .new(let response):
            onNewMessage(response)
        default:
            break
        }
    }

    private func searchThreads(_ text: String, new: Bool? = nil, loadMore: Bool = false) async {
        if !lazyList.canLoadMore() { return }
        lazyList.setLoading(true)
        do {
            let calThreads = try await search(text: text, new: new, loadMore: loadMore)
            lazyList.setLoading(false)
            lazyList.setHasNext(calThreads.count >= lazyList.count)
            searchedConversations.append(contentsOf: calThreads)
        } catch {
            log("Failed to get serach threads with error: \(error.localizedDescription)")
        }
    }

    private func searchPublicThreads(_ text: String) async {
        if !lazyList.canLoadMore() { return }
        lazyList.setLoading(true)
        do {
            let calThreads = try await publicConversations(text: text)
            lazyList.setLoading(false)
            lazyList.setHasNext(calThreads.count >= lazyList.count)
            searchedConversations.append(contentsOf: calThreads)
        } catch {
            log("Failed to get search public threads with error: \(error.localizedDescription)")
        }
    }
    
    private func searchContacts(_ searchText: String) async {
        if searchText.isEmpty { return }
        do {
            let req = getContactRequest(searchText: searchText)
            let contacts = try await GetSearchContactsRequester().get(req, withCache: false)
            searchedContacts.removeAll()
            searchedContacts.append(contentsOf: contacts)
        } catch {
            log("Failed to get search contacts with error: \(error.localizedDescription)")
        }
    }

    public func closedSearchUI() {
        reset()
        searchText = ""
        showUnreadConversations = false
    }

    public func reset() {
        lazyList.reset()
        searchedConversations.removeAll()
        searchedContacts.removeAll()
        cachedAttribute.removeAll()
    }

    private func getUnreadConversations() async {
        reset()
        await searchThreads(searchText, new: true)
        await searchContacts(searchText)
    }

    private func resetUnreadConversations() async {
        reset()
        await searchThreads(searchText, new: nil)
        await searchContacts(searchText)
    }

    public func attributdTitle(for title: String) -> AttributedString {
        if let cached = cachedAttribute.first(where: {$0.key == title})?.value {
            return cached
        }
        let attr = NSMutableAttributedString(string: title)
        attr.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor(named: "accent")!
        ], range: findRangeOfTitleToHighlight(title))
        cachedAttribute[title] = AttributedString(attr)
        return AttributedString(attr)
    }

    private func findRangeOfTitleToHighlight(_ title: String) -> NSRange {
        return NSString(string: title).range(of: searchText)
    }

    private func onCancelTimer(key: String) {
        if lazyList.isLoading {
            lazyList.setLoading(false)
            animateObjectWillChange()
        }
    }
    
    private func onNewMessage(_ response: ChatResponse<Message>) {
        if let index = searchedConversations.firstIndex(where: {$0.id == response.subjectId}) {
            let calculatedConversation = searchedConversations[index]
            let message = response.result
            let conversation = calculatedConversation.toStruct()
            calculatedConversation.lastMessageVO = message?.toLastMessageVO
            calculatedConversation.lastMessage = message?.message
            let myId = AppState.shared.user?.id ?? -1
            let string = String((message?.message ?? "").replacingOccurrences(of: "\n", with: " ").prefix(50))
            
            calculatedConversation.subtitleAttributedString = ThreadCalculators.caculateSubtitle(conversation: conversation, myId: myId, isFileType: message?.isFileType == true)
            calculatedConversation.timeString = message?.time?.date.localTimeOrDate ?? ""
            calculatedConversation.animateObjectWillChange()
        }
    }
}

private extension ThreadsSearchViewModel {
    
    private func search(text: String, new: Bool?, loadMore: Bool) async throws -> [CalculatedConversation] {
        let req = ThreadsRequest(searchText: text, count: lazyList.count, offset: lazyList.offset, new: new)
        return try await doSearchAndCalculte(req: req)
    }
    
    private func publicConversations(text: String) async throws -> [CalculatedConversation] {
        let req = ThreadsRequest(count: lazyList.count, offset: lazyList.offset, name: text, type: .publicGroup)
        return try await doSearchAndCalculte(req: req)
    }
    
    private func doSearchAndCalculte(req: ThreadsRequest)  async throws -> [CalculatedConversation] {
        let myId = AppState.shared.user?.id ?? -1
        let selectedId = AppState.shared.objectsContainer.navVM.selectedId
        let calThreads = try await GetThreadsReuqester().getCalculated(req: req, withCache: false, queueable: true, myId: myId, navSelectedId: selectedId)
        return calThreads.filter({ $0.isArchive == false || $0.isArchive == nil })
    }
    
    private func getContactRequest(searchText: String) -> ContactsRequest {
        let req: ContactsRequest
        if searchText.lowercased().contains("uname:") {
            let startIndex = searchText.index(searchText.startIndex, offsetBy: 6)
            let searchResultValue = String(searchText[startIndex..<searchText.endIndex])
            req = ContactsRequest(userName: searchResultValue)
        } else if searchText.lowercased().contains("tel:") {
            let startIndex = searchText.index(searchText.startIndex, offsetBy: 4)
            let searchResultValue = String(searchText[startIndex..<searchText.endIndex])
            req = ContactsRequest(cellphoneNumber: searchResultValue)
        } else {
            req = ContactsRequest(query: searchText)
        }
        return req
    }
}

private extension ThreadsSearchViewModel {
    func log(_ string: String) {
        Logger.log(title: "ThreadsSearchViewModel", message: string)
    }
}
