//
//  ThreadOrContactPickerViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import Chat
import TalkModels
import Logger

@MainActor
public class ThreadOrContactPickerViewModel: ObservableObject {
    private var cancellableSet: Set<AnyCancellable> = .init()
    @Published public var searchText: String = ""
    public var conversations: ContiguousArray<CalculatedConversation> = .init()
    public var contacts:ContiguousArray<Contact> = .init()
    private var isIsSearchMode = false
    public var contactsLazyList = LazyListViewModel()
    public var conversationsLazyList = LazyListViewModel()
    private var selfConversation: Conversation? = AppState.shared.objectsContainer.selfConversationBuilder.cachedSlefConversation

    public init() {
        getContacts()
        let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
        getThreads(req)
        setupObservers()
    }

    func setupObservers() {
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
            .sink { [weak self] newValue in
                Task { [weak self] in
                    self?.isIsSearchMode = true
                    await self?.search(newValue)
                }
            }
            .store(in: &cancellableSet)

        $searchText
            .filter { $0.count == 0 }
            .sink { [weak self] _ in
                Task { [weak self] in
                    if self?.isIsSearchMode == true {
                        self?.isIsSearchMode = false
                        self?.reset()
                    }
                }
            }
            .store(in: &cancellableSet)
    }

    func search(_ text: String) {
        conversations.removeAll()
        contacts.removeAll()
        contactsLazyList.setLoading(true)
        conversationsLazyList.setLoading(true)
        
        let req = ThreadsRequest(searchText: text)
        getThreads(req)
        
        Task { [weak self] in
            guard let self = self else { return }
            await searchContacts(text)
        }
    }
    
    private func searchContacts(_ text: String) async {
        do {
            let contactsReq = ContactsRequest(query: text)
            let contacts = try await GetContactsRequester().get(contactsReq, withCache: false)
            await hideContactsLoadingWithDelay()
            contactsLazyList.setHasNext(contacts.count >= contactsLazyList.count)
            self.contacts.append(contentsOf: contacts)
            animateObjectWillChange()
        } catch {
            log("Failed to search get contacts with error: \(error.localizedDescription)")
        }
    }

    public func loadMore() {
        if !conversationsLazyList.canLoadMore() { return }
        conversationsLazyList.prepareForLoadMore()
        let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
        getThreads(req)
    }

    public func getThreads(_ req: ThreadsRequest) {
        if selfConversation == nil { return }
        conversationsLazyList.setLoading(true)
        Task { [weak self] in
            guard let self = self else { return }
            let myId = AppState.shared.user?.id ?? -1
            let calThreads = try await GetThreadsReuqester().getCalculated(
                req: req,
                withCache: false,
                myId: myId,
                navSelectedId: nil
            )
            await hideConversationsLoadingWithDelay()
            conversationsLazyList.setHasNext(calThreads.count >= conversationsLazyList.count)
            let filtered = calThreads.filter({$0.closed == false }).filter({$0.type != .selfThread})
            self.conversations.append(contentsOf: calThreads)
            if self.searchText.isEmpty, !self.conversations.contains(where: {$0.type == .selfThread}), let selfConversation = selfConversation {
                let calculated = await ThreadCalculators.calculate(selfConversation, myId ?? -1)
                self.conversations.append(calculated)
            }
            animateObjectWillChange()
        }
    }

    public func loadMoreContacts() {
        if !contactsLazyList.canLoadMore() { return }
        contactsLazyList.prepareForLoadMore()
        getContacts()
    }

    public func getContacts() {
        contactsLazyList.setLoading(true)
        let req = ContactsRequest(count: contactsLazyList.count, offset: contactsLazyList.offset)
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let contacts = try await GetContactsRequester().get(req, withCache: false)
                await hideContactsLoadingWithDelay()
                contactsLazyList.setHasNext(contacts.count >= contactsLazyList.count)
                self.contacts.append(contentsOf: contacts)
                animateObjectWillChange()
            } catch {
                log("Failed to get contacts with error: \(error.localizedDescription)")
            }
        }
    }

    public func cancelObservers() {
        cancellableSet.forEach { cancelable in
            cancelable.cancel()
        }
    }

    private func hideConversationsLoadingWithDelay() async {
        try? await Task.sleep(for: .seconds(0.3))
        conversationsLazyList.setLoading(false)
    }

    private func hideContactsLoadingWithDelay() async {
        try? await Task.sleep(for: .seconds(0.3))
        contactsLazyList.setLoading(false)
    }

    public func reset() {
        conversationsLazyList.reset()
        contactsLazyList.reset()
        conversations.removeAll()
        contacts.removeAll()
        getContacts()
        
        let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
        getThreads(req)
    }
}

private extension ThreadOrContactPickerViewModel {
    func log(_ string: String) {
        Logger.log(title: "ThreadOrContactPickerViewModel", message: string)
    }
}

