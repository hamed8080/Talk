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
import UIKit
import TalkExtensions

@MainActor
public protocol UIForwardThreadsViewControllerDelegate: AnyObject {
    func apply(snapshot: NSDiffableDataSourceSnapshot<ThreadsListSection, CalculatedConversation>, animatingDifferences: Bool)
    func updateImage(image: UIImage?, id: Int)
}

@MainActor
public protocol UIForwardContactsViewControllerDelegate: AnyObject {
    func apply(snapshot: NSDiffableDataSourceSnapshot<ContactListSection, Contact>, animatingDifferences: Bool)
    func updateImage(image: UIImage?, id: Int)
}

@MainActor
public class ThreadOrContactPickerViewModel {
    private var searchText: String = ""
    public var conversations: ContiguousArray<CalculatedConversation> = .init()
    public var contacts:ContiguousArray<Contact> = .init()
    private var isIsSearchMode = false
    public var contactsLazyList = LazyListViewModel()
    public var conversationsLazyList = LazyListViewModel()
    private var selfConversation: Conversation? = UserDefaults.standard.codableValue(forKey: "SELF_THREAD")
    public weak var delegate: UIForwardThreadsViewControllerDelegate?
    public weak var contactsDelegate: UIForwardContactsViewControllerDelegate?
    public private(set) var contactsImages: [Int: ImageLoaderViewModel] = [:]
    private var searchTask: Task<Void, any Error>? = nil

    public init() {
        /// Clear out self thread and force it to fetch the new self thread.
        UserDefaults.standard.removeObject(forKey: "SELF_THREAD")
        UserDefaults.standard.synchronize()
    }
    
    public func updateUI(animation: Bool, reloadSections: Bool) {
        /// Create
        var snapshot = NSDiffableDataSourceSnapshot<ThreadsListSection, CalculatedConversation>()
        
        /// Configure
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(conversations), toSection: .main)
        if reloadSections {
            snapshot.reloadSections([.main])
        }
        
        /// Apply
        delegate?.apply(snapshot: snapshot, animatingDifferences: animation)
    }
    
    public func updateContactUI(animation: Bool) {
        /// Create
        var snapshot = NSDiffableDataSourceSnapshot<ContactListSection, Contact>()
        let sections: [ContactListSection] = [.main]
        
        /// Configure
        snapshot.appendSections(sections)
        snapshot.appendItems(Array(contacts), toSection: .main)
        
        /// Apply
        contactsDelegate?.apply(snapshot: snapshot, animatingDifferences: animation)
    }
    
    public func start() {
        Task { [weak self] in
            guard let self = self else { return }
            if selfConversation == nil {
                await getSelfConversation()
                try? await Task.sleep(for: .seconds(0.3))
            }
            
            /// Prevent request if search text on appear if is not empty, so it might have some contacts.
            if searchText.isEmpty {
                try await getContacts()
            }
            
            /// Prevent request if search text on appear is not empty, so it might have some conversations.
            if searchText.isEmpty {
                let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
                try await getThreads(req)
            } else {
                updateUI(animation: false, reloadSections: false)
            }
        }
    }
    
    public func onTextChanged(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        searchText = trimmedText
        
        // Cancel the previous pending task if user is still typing
        searchTask?.cancel()
        
        searchTask = Task {
            // Wait for a short delay (user typing pause)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // If this task was cancelled (user typed again), exit
            guard !Task.isCancelled else { return }
            
            if trimmedText.count == 0, isIsSearchMode == true {
                isIsSearchMode = false
                try await reset()
            } else if trimmedText.count > 1 {
                isIsSearchMode = true
                try await search(trimmedText)
            }
        }
    }

    private func search(_ text: String) async throws {
        conversations.removeAll()
        contacts.removeAll()
        contactsLazyList.setLoading(true)
        conversationsLazyList.setLoading(true)
        
        let req = ThreadsRequest(searchText: text)
        try await getThreads(req)
        try await getContacts(text: text)
    }
    
    public func loadMore(id: Int?) async throws {
        if !conversationsLazyList.canLoadMore(id: id) { return }
        conversationsLazyList.prepareForLoadMore()
        let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
        try await getThreads(req)
    }

    private func getThreads(_ req: ThreadsRequest) async throws {
        if selfConversation == nil { return }
        conversationsLazyList.setLoading(true)
        let myId = AppState.shared.user?.id ?? -1
        let calThreads = try await GetThreadsReuqester().getCalculated(
            req: req,
            withCache: false,
            myId: myId,
            navSelectedId: nil
        )
        
        conversationsLazyList.setHasNext(calThreads.count >= conversationsLazyList.count)
        let filtered = calThreads
            .filter({$0.closed == false })
            .filter({$0.type != .selfThread})
            .filter({ filtered in !self.conversations.contains(where: { filtered.id == $0.id }) })
        conversations.append(contentsOf: filtered)
        if self.searchText.isEmpty, !self.conversations.contains(where: {$0.type == .selfThread}), let selfConversation = selfConversation {
            let calculated = await ThreadCalculators.calculate(selfConversation, myId ?? -1)
            self.conversations.append(calculated)
        }
        conversations.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        conversations.sort(by: { $0.pin == true && $1.pin == false })
        conversations.sort(by: { $0.type == .selfThread && $1.type != .selfThread })
        let serverSortedPins = AppState.shared.objectsContainer.threadsVM.serverSortedPins
        
        conversations.sort(by: { (firstItem, secondItem) in
            guard let firstIndex = serverSortedPins.firstIndex(where: {$0 == firstItem.id}),
                  let secondIndex = serverSortedPins.firstIndex(where: {$0 == secondItem.id}) else {
                return false // Handle the case when an element is not found in the server-sorted array
            }
            return firstIndex < secondIndex
        })
        
        updateUI(animation: false, reloadSections: false)
        
        for cal in calThreads {
            addImageLoader(cal)
        }
        conversationsLazyList.setThreasholdIds(ids: conversations.suffix(8).compactMap {$0.id} )
        conversationsLazyList.setLoading(false)
    }

    public func loadMoreContacts() async throws {
        if !contactsLazyList.canLoadMore() { return }
        contactsLazyList.prepareForLoadMore()
        try await getContacts()
    }
        
    public func getContacts(text: String? = nil) async throws {
        contactsLazyList.setLoading(true)
        let req: ContactsRequest
        if let text = text {
            req = ContactsRequest(query: text)
        } else {
            req = ContactsRequest(count: contactsLazyList.count, offset: contactsLazyList.offset)
        }
        
        let contacts = try await GetContactsRequester().get(req, withCache: false)
        contactsLazyList.setHasNext(contacts.count >= contactsLazyList.count)
        let filtered = contacts.filter({ newContact in !self.contacts.contains(where: { oldContact in newContact.id == oldContact.id }) })
        self.contacts.append(contentsOf: filtered)
        
        updateContactUI(animation: false)
        
        for contact in contacts {
            addImageLoader(contact)
        }
        contactsLazyList.setLoading(false)
    }
    
    private func getSelfConversation() async {
        do {
            let selfReq = ThreadsRequest(count: 1, offset: 0, type: .selfThread)
            let myId = AppState.shared.user?.id ?? -1
            guard let calculated = try await GetThreadsReuqester().getCalculated(
                req: selfReq,
                withCache: false,
                myId: myId,
                navSelectedId: nil
            ).first else { return }
            
            selfConversation = calculated.toStruct()
            UserDefaults.standard.setValue(codable: calculated.toStruct(), forKey: "SELF_THREAD")
            UserDefaults.standard.synchronize()
        } catch {
            log("Failed to get self conversation with error: \(error.localizedDescription)")
        }
    }

    private func reset() async throws {
        conversationsLazyList.reset()
        contactsLazyList.reset()
        conversations.removeAll()
        contacts.removeAll()
        try await getContacts()
        contactsImages.removeAll()
        let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
        try await getThreads(req)
    }
    
    private func addImageLoader(_ conversation: CalculatedConversation) {
        if let id = conversation.id, conversation.imageLoader == nil, let image = conversation.image {
            let viewModel = ImageLoaderViewModel(conversation: conversation)
            conversation.imageLoader = viewModel
            viewModel.onImage = { [weak self] image in
                Task { @MainActor [weak self] in
                    self?.delegate?.updateImage(image: image, id: id)
                }
            }
            viewModel.fetch()
        }
    }
    
    public func addImageLoader(_ contact: Contact) {
        guard let id = contact.id else { return }
        if contactsImages[id] == nil {
            let viewModel = ImageLoaderViewModel(contact: contact)
            contactsImages[id] = viewModel
            viewModel.onImage = { [weak self] image in
                Task { @MainActor [weak self] in
                    self?.contactsDelegate?.updateImage(image: image, id: id)
                }
            }
            viewModel.fetch()
        } else if let vm = contactsImages[id], vm.isImageReady {
            contactsDelegate?.updateImage(image: vm.image, id: id)
        }
    }
    
    deinit {
#if DEBUG
        print("deinit called for ThreadOrContactPickerViewModel")
#endif
    }
}

private extension ThreadOrContactPickerViewModel {
    func log(_ string: String) {
        Logger.log(title: "ThreadOrContactPickerViewModel", message: string)
    }
}
