//
//  ThreadOrContactPickerViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatModels
import Combine
import ChatDTO
import ChatCore
import Chat

public class ThreadOrContactPickerViewModel: ObservableObject {
    private var cancellableSet: Set<AnyCancellable> = .init()
    @Published public var searchText: String = ""
    public var conversations: ContiguousArray<Conversation> = .init()
    public var contacts:ContiguousArray<Contact> = .init()
    private var isIsSearchMode = false
    @MainActor public var contactsLazyList = LazyListViewModel()
    @MainActor public var conversationsLazyList = LazyListViewModel()

    public init() {
        Task {
            await getContacts()
            await getThreads()
            await setupObservers()
        }
    }

    @MainActor
    func setupObservers() async {
        contactsLazyList.objectWillChange.sink { [weak self] _ in
            self?.animateObjectWillChange()
        }
        .store(in: &cancellableSet)
        conversationsLazyList.objectWillChange.sink { [weak self] _ in
            self?.animateObjectWillChange()
        }
        .store(in: &cancellableSet)
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { newValue in
                Task { [weak self] in
                    self?.isIsSearchMode = true
                    await self?.search(newValue)
                }
            }
            .store(in: &cancellableSet)

        $searchText
            .filter { $0.count == 0 }
            .sink { _ in
                Task { [weak self] in
                    if self?.isIsSearchMode == true {
                        self?.isIsSearchMode = false
                        await self?.reset()
                    }
                }
            }
            .store(in: &cancellableSet)

        NotificationCenter.thread.publisher(for: .thread)
            .map({$0.object as? ThreadEventTypes})
            .sink { event in
                Task { [weak self] in
                    if case let .threads(response) = event {
                        await self?.onConversations(response)
                    }
                }
            }
            .store(in: &cancellableSet)

        NotificationCenter.contact.publisher(for: .contact)
            .map({$0.object as? ContactEventTypes})
            .sink { event in
                Task { [weak self] in
                    if case let .contacts(response) = event {
                        await self?.onContacts(response)
                    }
                }
            }
            .store(in: &cancellableSet)
    }

    @MainActor
    func search(_ text: String) async {
        conversations.removeAll()
        contacts.removeAll()
        contactsLazyList.setLoading(true)
        conversationsLazyList.setLoading(true)
        let req = ThreadsRequest(searchText: text)
        RequestsManager.shared.append(prepend: "GET_THREADS_IN_SELECT_THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)

        let contactsReq = ContactsRequest(query: text)
        RequestsManager.shared.append(prepend: "GET_CONTCATS_IN_SELECT_CONTACT", value: contactsReq)
        ChatManager.activeInstance?.contact.get(contactsReq)
    }

    @MainActor
    public func loadMore() async {
        if await !conversationsLazyList.canLoadMore() { return }
        conversationsLazyList.prepareForLoadMore()
        await getThreads()
    }

    @MainActor
    public func getThreads() async {
        conversationsLazyList.setLoading(true)
        let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
        RequestsManager.shared.append(prepend: "GET_THREADS_IN_SELECT_THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    @MainActor
    private func onConversations(_ response: ChatResponse<[Conversation]>) async {
        if !response.cache, response.pop(prepend: "GET_THREADS_IN_SELECT_THREAD") != nil {
            await hideConversationsLoadingWithDelay()
            conversationsLazyList.setHasNext(response.hasNext)
            conversations.append(contentsOf: response.result ?? [])
            animateObjectWillChange()
        }
    }

    @MainActor
    public func loadMoreContacts() async {
        if await !contactsLazyList.canLoadMore() { return }
        contactsLazyList.prepareForLoadMore()
        await getContacts()
    }

    @MainActor
    public func getContacts() async {
        contactsLazyList.setLoading(true)
        let req = ContactsRequest(count: contactsLazyList.count, offset: contactsLazyList.offset)
        RequestsManager.shared.append(prepend: "GET_CONTCATS_IN_SELECT_CONTACT", value: req)
        ChatManager.activeInstance?.contact.get(req)
    }

    @MainActor
    private func onContacts(_ response: ChatResponse<[Contact]>) async {
        if !response.cache, response.pop(prepend: "GET_CONTCATS_IN_SELECT_CONTACT") != nil {
            await hideContactsLoadingWithDelay()
            contactsLazyList.setHasNext(response.hasNext)
            contacts.append(contentsOf: response.result ?? [])
            animateObjectWillChange()
        }
    }

    public func cancelObservers() {
        cancellableSet.forEach { cancelable in
            cancelable.cancel()
        }
    }

    private func hideConversationsLoadingWithDelay() async {
        try? await Task.sleep(for: .seconds(0.3))
        await conversationsLazyList.setLoading(false)
    }

    private func hideContactsLoadingWithDelay() async {
        try? await Task.sleep(for: .seconds(0.3))
        await contactsLazyList.setLoading(false)
    }

    @MainActor
    public func reset() async {
        conversationsLazyList.reset()
        contactsLazyList.reset()
        conversations.removeAll()
        contacts.removeAll()
        await getContacts()
        await getThreads()
    }
}
