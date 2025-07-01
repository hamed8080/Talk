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
    private var objectId = UUID().uuidString
    private let SEARCH_KEY: String
    private let SEARCH_LOAD_MORE_KEY: String
    private let SEARCH_PUBLIC_THREAD_KEY: String
    private let SEARCH_CONTACTS_IN_THREADS_LIST_KEY: String

    public init() {
        SEARCH_KEY = "SEARCH-\(objectId)"
        SEARCH_LOAD_MORE_KEY = "SEARCH-LOAD-MORE-\(objectId)"
        SEARCH_PUBLIC_THREAD_KEY = "SEARCH-PUBLIC-THREAD-\(objectId)"
        SEARCH_CONTACTS_IN_THREADS_LIST_KEY = "SEARCH-CONTACTS-IN-THREADS-LIST-\(objectId)"

        Task {
            await setupObservers()
        }
    }

    private func setupObservers() async {
        lazyList.objectWillChange.sink { [weak self] _ in
            self?.animateObjectWillChange()
        }
        .store(in: &cancelable)

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
        NotificationCenter.contact.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] event in
                self?.onContactEvent(event)
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
            await reset()
            let startIndex = newValue.index(newValue.startIndex, offsetBy: 1)
            let newString = newValue[startIndex..<newValue.endIndex]
            searchPublicThreads(String(newString))
        } else if newValue.first != "@" && !newValue.isEmpty {
            await reset()
            await searchThreads(newValue, new: showUnreadConversations)
            searchContacts(newValue)
        } else if newValue.count == 0, await !lazyList.isLoading {
            await reset()
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

    private func onThreadEvent(_ event: ThreadEventTypes?) async {
        switch event {
        case .threads(let response):
            await setHasNextOnResponse(response)
            await onPublicThreadSearch(response)
            await onSearch(response)
            await onSearchLoadMore(response)
        default:
            break
        }
    }
    
    private func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .new(let response):
            onNewMessage(response)
        default:
            break
        }
    }

    private func onContactEvent(_ event: ContactEventTypes?) {
        switch event {
        case let .contacts(response):
            onSearchContacts(response)
        default:
            break
        }
    }

    private func searchThreads(_ text: String, new: Bool? = nil, loadMore: Bool = false) {
        if !lazyList.canLoadMore() { return }
        lazyList.setLoading(true)
        let req = ThreadsRequest(searchText: text, count: lazyList.count, offset: lazyList.offset, new: new)
        RequestsManager.shared.append(prepend: loadMore ? SEARCH_LOAD_MORE_KEY : SEARCH_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
    }

    private func searchPublicThreads(_ text: String) {
        if !lazyList.canLoadMore() { return }
        lazyList.setLoading(true)
        let req = ThreadsRequest(count: lazyList.count, offset: lazyList.offset, name: text, type: .publicGroup)
        RequestsManager.shared.append(prepend: SEARCH_PUBLIC_THREAD_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.get(req)
        }
    }

    private func onSearch(_ response: ChatResponse<[Conversation]>) async {
        lazyList.setLoading(false)
        if !response.cache, let threads = response.result, response.pop(prepend: SEARCH_KEY) != nil {
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.calculate(threads, myId)
            searchedConversations.append(contentsOf: calThreads)
        }
    }

    private func onSearchLoadMore(_ response: ChatResponse<[Conversation]>) async {
        lazyList.setLoading(false)
        if !response.cache, let threads = response.result, response.pop(prepend: SEARCH_LOAD_MORE_KEY) != nil {
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.calculate(threads, myId)
            searchedConversations.append(contentsOf: calThreads)
        }
    }

    private func onPublicThreadSearch(_ response: ChatResponse<[Conversation]>) async {
        lazyList.setLoading(false)
        if !response.cache, let threads = response.result, response.pop(prepend: SEARCH_PUBLIC_THREAD_KEY) != nil {
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = await ThreadCalculators.calculate(threads, myId)
            searchedConversations.append(contentsOf: calThreads)
        }
    }

    private func setHasNextOnResponse(_ response: ChatResponse<[Conversation]>) async {
        if !response.cache, response.result?.count ?? 0 > 0 {
            lazyList.setHasNext(response.hasNext)
        }
    }

    private func searchContacts(_ searchText: String) {
        if searchText.isEmpty { return }
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
        RequestsManager.shared.append(prepend: SEARCH_CONTACTS_IN_THREADS_LIST_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.search(req)
        }
    }

    private func onSearchContacts(_ response: ChatResponse<[Contact]>) {
        if !response.cache, response.pop(prepend: SEARCH_CONTACTS_IN_THREADS_LIST_KEY) != nil {
            if let contacts = response.result {
                self.searchedContacts.removeAll()
                self.searchedContacts.append(contentsOf: contacts)
            }
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

    private func getUnreadConversations() {
        reset()
        searchThreads(searchText, new: true)
        searchContacts(searchText)
    }

    private func resetUnreadConversations() {
        reset()
        searchThreads(searchText, new: nil)
        searchContacts(searchText)
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
            calculatedConversation.fiftyFirstCharacter = String((message?.message ?? "").replacingOccurrences(of: "\n", with: " ").prefix(50))
            calculatedConversation.timeString = message?.time?.date.localTimeOrDate ?? ""
            calculatedConversation.animateObjectWillChange()
        }
    }
}
