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
import Logger

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
    public var builderScrollProxy: ScrollViewProxy?
    @Published public var isTypinginSearchString: Bool = false

    public init(isBuilder: Bool = false) {
        self.isBuilder = isBuilder
        setupPublishers()
    }

    public func setupPublishers() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            lazyList.objectWillChange.sink { [weak self] _ in
                self?.animateObjectWillChange()
            }
            .store(in: &canceableSet)
        }
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if !self.isBuilder, self.firstSuccessResponse == false, status == .connected {
                        await self.onConnectedGetContacts()
                    }
                }
        }
        .store(in: &canceableSet)
        
        $searchContactString
            .sink { [weak self] _ in
                self?.isTypinginSearchString = true
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
                    self?.isTypinginSearchString = false
                    await self?.searchContacts(searchText)
                }
            }
            .store(in: &canceableSet)
        NotificationCenter.contact.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] event in
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

    func onBlockedList(_ response: ChatResponse<[BlockedContactResponse]>) {
        blockedContacts = .init(response.result ?? [])
        animateObjectWillChange()
    }
    
    public func getContacts() {
        lazyList.setLoading(true)
        let req = ContactsRequest(count: lazyList.count, offset: lazyList.offset)
        Task {
            do {
                let contacts = try await GetContactsRequester().get(req, withCache: false, queueable: true)
                firstSuccessResponse = true
                appendOrUpdateContact(contacts)
                lazyList.setHasNext(contacts.count >= lazyList.count)
                lazyList.setLoading(false)
                lazyList.setThreasholdIds(ids: self.contacts.suffix(5).compactMap{$0.id})
            } catch {
                log("Failed to get contacts with error: \(error.localizedDescription)")
            }
        }
    }
    
    public func onConnectedGetContacts() async {
        await try? Task.sleep(200)
        getContacts()
    }
    
    public func searchContacts(_ searchText: String) async {
        lazyList.setLoading(true)
        let req = getSearchRequest(searchText)
        do {
            let contacts = try await GetSearchContactsRequester().get(req, withCache: false)
            lazyList.setLoading(false)
            searchedContacts = .init(contacts)
            try? await Task.sleep(for: .milliseconds(200)) /// To scroll properly
            withAnimation {
                let scrollTo = contacts.isEmpty ? "General.noResult" : "SearchRow-\(searchedContacts.first?.id ?? 0)"
                builderScrollProxy?.scrollTo(scrollTo, anchor: .top)
            }
        } catch {
            log("Failed to get search contacts with error: \(error.localizedDescription)")
        }
    }

    public func onDeleteContacts(_ response: ChatResponse<[Contact]>, _ deleted: Bool) async {
        if deleted {
            response.result?.forEach{ contact in
                searchedContacts.removeAll(where: {$0.id == contact.id})
                contacts.removeAll(where: {$0.id == contact.id})
            }
            animateObjectWillChange()
        }
    }

    public func loadMore() {
        if !lazyList.canLoadMore() { return }
        lazyList.prepareForLoadMore()
        getContacts()
    }

    public func loadMore(id: Int?) {
        if !lazyList.canLoadMore(id: id) { return }
        loadMore()
    }

    public func refresh() {
        clear()
        getContacts()
    }

    public func clear() {
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

    public func onBlockResponse(_ response: ChatResponse<BlockedContactResponse>) async {
        if let result = response.result, let index = contacts.firstIndex(where: { $0.id == result.contact?.id }) {
            contacts[index].blocked = true
            blockedContacts.append(result)
            animateObjectWillChange()
        }
    }

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
        
        for vm in historyVMS {
            vm.sections
                .compactMap{$0.vms}
                .flatMap({$0})
                .filter{$0.message.participant?.id == contact.id}
                .forEach { viewModel in
                    viewModel.message.participant?.contactName = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
                    viewModel.message.participant?.name = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
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
        if key.contains("Add-Contact-ContactsViewModel") {
            lazyList.setLoading(false)
        }
    }
    
    public func getBlockedList() {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.contact.getBlockedList()
        }
    }
}

private extension ContactsViewModel {
    func getSearchRequest(_ searchText: String) -> ContactsRequest {
        let req: ContactsRequest
        if searchType == .username {
            req = ContactsRequest(userName: searchText)
        } else if searchType == .cellphoneNumber {
            req = ContactsRequest(cellphoneNumber: searchText)
        } else {
            req = ContactsRequest(query: searchText)
        }
        return req
    }
}

private extension ContactsViewModel {
    func log(_ string: String) {
        Logger.log(title: "ContactsViewModel", message: string)
    }
}
