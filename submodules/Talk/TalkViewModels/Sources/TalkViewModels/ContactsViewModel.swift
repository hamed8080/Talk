//
//  ContactsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import TalkModels
import SwiftUI
import Photos
import TalkExtensions

@MainActor
public class ContactsViewModel: ObservableObject {
    public var selectedContacts: ContiguousArray<Contact> = []
    public var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    @Published public private(set) var maxContactsCountInServer = 0
    public var contacts: ContiguousArray<Contact> = []
    @Published public var searchType: SearchParticipantType = .name
    @Published public var searchedContacts: ContiguousArray<Contact> = []
    @Published public var searchContactString: String = ""
    public var blockedContacts: ContiguousArray<BlockedContactResponse> = []
    public var addContact: Contact?
    public var editContact: Contact?
    @Published public var showAddOrEditContactSheet = false
    public var isBuilder: Bool = false
    public var isInSelectionMode = false
    public var successAdded: Bool = false
    public var userNotFound: Bool = false
    public var lazyList = LazyListViewModel()
    private var objectId = UUID().uuidString
    private let GET_CONTACTS_KEY: String
    private let SEARCH_CONTACTS_KEY: String
    public var builderScrollProxy: ScrollViewProxy?

    public init(isBuilder: Bool = false) {
        self.isBuilder = isBuilder
        GET_CONTACTS_KEY = "GET-CONTACTS\(isBuilder ? "-BUILDER" : "")-\(objectId)"
        SEARCH_CONTACTS_KEY = "SEARCH-CONTACTS\(isBuilder ? "-BUILDER" : "")-\(objectId)"
        setupPublishers()
    }

    public func setupPublishers() {
        Task { @MainActor in
            lazyList.objectWillChange.sink { [weak self] _ in
                self?.animateObjectWillChange()
            }
            .store(in: &canceableSet)
        }
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if self.firstSuccessResponse == false, status == .connected {
                        await self.getContacts()
                        Task { @ChatGlobalActor in
                            ChatManager.activeInstance?.contact.getBlockedList()
                        }
                        self.sync()
                    }
                }
        }
        .store(in: &canceableSet)
        $searchContactString
            .filter { $0.count == 0 }
            .sink { [weak self] newValue in
                if newValue.count == 0 {
                    self?.searchedContacts = []
                }
            }
            .store(in: &canceableSet)
        $searchContactString
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .filter { $0.count > 1 }
            .sink { [weak self] searchText in
                Task { [weak self] in
                    await self?.searchContacts(searchText)
                }
            }
            .store(in: &canceableSet)
        NotificationCenter.contact.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink{ event in
                Task { [weak self] in
                    await self?.onContactEvent(event)
                }
            }
            .store(in: &canceableSet)

        NotificationCenter.thread.publisher(for: .thread)
            .map{$0.object as? ThreadEventTypes}
            .sink { [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &canceableSet)

        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] notif in
                self?.onCancelTimer(notif.object as? String ?? "")
            }
            .store(in: &canceableSet)
    }

    private func onContactEvent(_ event: ContactEventTypes?) async {
        switch event {
        case let .contacts(response):
            await onSearchContacts(response)
            await onContacts(response)
        case let .add(response):
            await onAddContacts(response)
        case let .delete(response, deleted):
            await onDeleteContacts(response, deleted)
        case let .blocked(response):
            await onBlockResponse(response)
        case let .unblocked(response):
            await onUNBlockResponse(response)
        case let .blockedList(response):
            await onBlockedList(response)
        default:
            break
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .updatedInfo(let response):
            onUpdatePartnerContact(response)
        default:
            break
        }
    }

    @MainActor
    public func onContacts(_ response: ChatResponse<[Contact]>) async {
        if !response.cache, response.pop(prepend: GET_CONTACTS_KEY) != nil {
            if let contacts = response.result {
                firstSuccessResponse = !response.cache
                appendOrUpdateContact(contacts)
                setMaxContactsCountInServer(count: response.contentCount ?? 0)
            }
            lazyList.setHasNext(response.hasNext)
            lazyList.setLoading(false)
            lazyList.setThreasholdIds(ids: self.contacts.suffix(5).compactMap{$0.id})
        }
    }

    @MainActor
    func onBlockedList(_ response: ChatResponse<[BlockedContactResponse]>) async {
        blockedContacts = .init(response.result ?? [])
    }

    @MainActor
    public func getContacts() async {
        lazyList.setLoading(true)
        let req = ContactsRequest(count: lazyList.count, offset: lazyList.offset)
        RequestsManager.shared.append(prepend: GET_CONTACTS_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.get(req)
        }
    }

    @MainActor
    public func searchContacts(_ searchText: String) async {
        lazyList.setLoading(true)
        let req: ContactsRequest
        if searchType == .username {
            req = ContactsRequest(userName: searchText)
        } else if searchType == .cellphoneNumber {
            req = ContactsRequest(cellphoneNumber: searchText)
        } else {
            req = ContactsRequest(query: searchText)
        }
        RequestsManager.shared.append(prepend: SEARCH_CONTACTS_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.search(req)
        }
    }

    @MainActor
    public func onDeleteContacts(_ response: ChatResponse<[Contact]>, _ deleted: Bool) async {
        if deleted {
            response.result?.forEach{ contact in
                searchedContacts.removeAll(where: {$0.id == contact.id})
                contacts.removeAll(where: {$0.id == contact.id})
            }
            animateObjectWillChange()
        }
    }

    @MainActor
    public func loadMore() async {
        if await !lazyList.canLoadMore() { return }
        lazyList.prepareForLoadMore()
        await getContacts()
    }

    @MainActor
    public func loadMore(id: Int?) async {
        if await !lazyList.canLoadMore(id: id) { return }
        await loadMore()
    }

    public func refresh() async {
        await clear()
        await getContacts()
    }

    @MainActor
    public func clear() async {
        searchContactString = ""
        firstSuccessResponse = false
        lazyList.reset()
        showAddOrEditContactSheet = false
        isInSelectionMode = false
        addContact = nil
        editContact = nil
        successAdded = false
        userNotFound = false
        contacts = []
        blockedContacts = []
        selectedContacts = []
        searchedContacts = []
        maxContactsCountInServer = 0
        animateObjectWillChange()
    }

    public func deselectContacts() {
        selectedContacts = []
        searchContactString = ""
    }

    public func delete(indexSet: IndexSet) {
        let contacts = contacts.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        contacts.forEach { contact in
            delete(contact)
            reomve(contact)
        }
        animateObjectWillChange()
    }

    public func delete(_ contact: Contact) {
        if let contactId = contact.id {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.contact.remove(.init(contactId: contactId))
            }
        }
    }

    public func deleteSelectedItems() {
        selectedContacts.forEach { contact in
            reomve(contact)
            delete(contact)
        }
    }

    public func appendOrUpdateContact(_ contacts: [Contact]) {
        // Remove all contacts that were cached, to prevent duplication.
        contacts.forEach { contact in
            if var oldContact = self.contacts.first(where: { $0.id == contact.id }) {
                oldContact.update(contact)
            } else {
                self.contacts.append(contact)
            }
        }
        animateObjectWillChange()
    }

    @MainActor
    public func onAddContacts(_ response: ChatResponse<[Contact]>) async {
        if response.cache { return }
        if response.error == nil, let contacts = response.result {
            contacts.forEach { newContact in
                if let index = self.contacts.firstIndex(where: {$0.id == newContact.id }) {
                    self.contacts[index].update(newContact)
                } else {
                    self.contacts.insert(newContact, at: 0)
                }
                updateActiveThreadsContactName(contact: newContact)
            }
            editContact = nil
            showAddOrEditContactSheet = false
            successAdded = true
            userNotFound = false
        } else if let error = response.error, error.code == 78 {
            userNotFound = true
        }
        lazyList.setLoading(false)
        animateObjectWillChange()
    }

    public func setMaxContactsCountInServer(count: Int) {
        maxContactsCountInServer = count
    }

    public func reomve(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0 == contact }) else { return }
        contacts.remove(at: index)
        animateObjectWillChange()
    }

    public func addToSelctedContacts(_ contact: Contact) {
        selectedContacts.append(contact)
    }

    public func removeToSelctedContacts(_ contact: Contact) {
        guard let index = selectedContacts.firstIndex(of: contact) else { return }
        selectedContacts.remove(at: index)
    }

    @MainActor
    public func onSearchContacts(_ response: ChatResponse<[Contact]>) async {
        if !response.cache, response.pop(prepend: SEARCH_CONTACTS_KEY) != nil {
            lazyList.setLoading(false)
            searchedContacts = .init(response.result ?? [])
            try? await Task.sleep(for: .milliseconds(200)) /// To scroll properly
            withAnimation {
                builderScrollProxy?.scrollTo("SearchRow-\(searchedContacts.first?.id ?? 0)", anchor: .top)
            }
        }
    }

    @MainActor
    public func addContact(contactValue: String, firstName: String?, lastName: String?) async {
        lazyList.setLoading(true)
        let isNumber = ContactsViewModel.isNumber(value: contactValue)
        if isNumber && contactValue.count < 10 {
            userNotFound = true
            lazyList.setLoading(false)
            return
        }
        let req: AddContactRequest = isNumber ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.add(req)
        }
    }

    public func firstContact(_ contact: Contact) -> Contact? {
        contacts.first { $0.id == contact.id }
    }

    public static func isNumber(value: String) -> Bool {
        let phoneRegex = "^[0-9]*$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let result = phoneTest.evaluate(with: value)
        return result
    }

    public func block(_ contact: Contact) {
        let req = BlockRequest(contactId: contact.id)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.block(req)
        }
    }

    public func unblock(_ blockedId: Int) {
        let req = UnBlockRequest(blockId: blockedId)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.unBlock(req)
        }
    }

    public func unblockWith(_ contactId: Int) {
        let req = UnBlockRequest(contactId: contactId)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.unBlock(req)
        }
    }

    @MainActor
    public func onBlockResponse(_ response: ChatResponse<BlockedContactResponse>) async {
        if let result = response.result, let index = contacts.firstIndex(where: { $0.id == result.contact?.id }) {
            contacts[index].blocked = true
            blockedContacts.append(result)
            animateObjectWillChange()
        }
    }

    @MainActor
    public func onUNBlockResponse(_ response: ChatResponse<BlockedContactResponse>) async {
        if let result = response.result, let index = contacts.firstIndex(where: { $0.id == result.contact?.id }) {
            contacts[index].blocked = false
            blockedContacts.removeAll(where: {$0.coreUserId == response.result?.coreUserId})
            animateObjectWillChange()
        }
    }

    public func isSelected(contact: Contact) -> Bool {
        selectedContacts.contains(contact)
    }

    public func toggleSelectedContact(contact: Contact) {
        withAnimation(.easeInOut) {
            if isSelected(contact: contact) {
                removeToSelctedContacts(contact)
            } else {
                addToSelctedContacts(contact)
            }
            animateObjectWillChange()
        }
    }

    public func sync() {
        if UserDefaults.standard.bool(forKey: "sync_contacts") == true {
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.contact.sync()
            }
        }
    }

    public func updateActiveThreadsContactName(contact: Contact) {
        let historyVMS = AppState.shared.objectsContainer.navVM.pathsTracking
            .compactMap{$0 as? ConversationNavigationValue}
            .compactMap{$0.viewModel}
            .compactMap{$0.historyVM}

        Task { @MainActor in
            for vm in historyVMS {
                await vm.getSections()
                    .compactMap{$0.vms}
                    .flatMap({$0})
                    .filter{$0.message.participant?.id == contact.id}
                    .forEach { viewModel in
                        viewModel.message.participant?.contactName = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
                        viewModel.message.participant?.name = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
                    }
            }
        }
    }

    private func onUpdatePartnerContact(_ response: ChatResponse<Conversation>) {
        if let index = contacts.firstIndex(where: {$0.userId == response.result?.partner }) {
            let split = response.result?.title?.split(separator: " ")
            if let firstName = split?.first {
                contacts[index].firstName = String(firstName)
            }
            if let lastName = split?.dropFirst().joined(separator: " ") {
                contacts[index].lastName = String(lastName)
            }
            animateObjectWillChange()
        }
    }

    private func onCancelTimer(_ key: String) {
        Task { @MainActor in
            if key.contains("Add-Contact-ContactsViewModel") {
                lazyList.setLoading(false)
            }
        }
    }
}
