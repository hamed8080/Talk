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

@MainActor
public class ThreadOrContactPickerViewModel: ObservableObject {
    private var cancellableSet: Set<AnyCancellable> = .init()
    @Published public var searchText: String = ""
    public var conversations: ContiguousArray<CalculatedConversation> = .init()
    public var contacts:ContiguousArray<Contact> = .init()
    private var isIsSearchMode = false
    public var contactsLazyList = LazyListViewModel()
    public var conversationsLazyList = LazyListViewModel()
    private var selfConversation: Conversation? = UserDefaults.standard.codableValue(forKey: "SELF_THREAD")
    public weak var delegate: UIThreadsViewControllerDelegate?
    public weak var contactsDelegate: UIContactsViewControllerDelegate?
    public private(set) var contactsImages: [Int: ImageLoaderViewModel] = [:]
    
    @AppBackgroundActor
    private var isCompleted = false

    public init() {
        setupObservers()
    }
    
    func updateUI(animation: Bool, reloadSections: Bool) {
        /// Create
        var snapshot = NSDiffableDataSourceSnapshot<ThreadsListSection, CalculatedConversation>()
        
        /// Configure
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(conversations), toSection: .main)
        if reloadSections {
            snapshot.reloadSections([.main])
        }
        
        /// Apply
        Task { @AppBackgroundActor in
            isCompleted = false
            await MainActor.run {
                delegate?.apply(snapshot: snapshot, animatingDifferences: animation)
            }
            self.isCompleted = true
        }
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
                getContacts()
            }
            
            /// Prevent request if search text on appear is not empty, so it might have some conversations.
            if searchText.isEmpty {
                let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
                getThreads(req)
            } else {
                updateUI(animation: false, reloadSections: false)
            }
        }
    }

    func setupObservers() {
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
            let filtered = contacts.filter({ newContact in !self.contacts.contains(where: { oldContact in newContact.id == oldContact.id }) })
            self.contacts.append(contentsOf: filtered)
            self.contacts = ContiguousArray(Set(contacts))
            contactsDelegate?.updateUI(animation: false, reloadSections: false)
            for contact in contacts {
                addImageLoader(contact)
            }
        } catch {
            log("Failed to search get contacts with error: \(error.localizedDescription)")
        }
    }
    
    public func loadMore(id: Int?) async {
        if !conversationsLazyList.canLoadMore(id: id) { return }
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
            let filtered = calThreads
                .filter({$0.closed == false })
                .filter({$0.type != .selfThread})
                .filter({ filtered in !self.conversations.contains(where: { filtered.id == $0.id }) })
            self.conversations.append(contentsOf: filtered)
            self.conversations = ContiguousArray(Set(conversations))
            if self.searchText.isEmpty, !self.conversations.contains(where: {$0.type == .selfThread}), let selfConversation = selfConversation {
                let calculated = await ThreadCalculators.calculate(selfConversation, myId ?? -1)
                self.conversations.append(calculated)
            }
            self.conversations.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
            self.conversations.sort(by: { $0.pin == true && $1.pin == false })
            self.conversations.sort(by: { $0.type == .selfThread && $1.type != .selfThread })
            let serverSortedPins = AppState.shared.objectsContainer.threadsVM.serverSortedPins
            
            self.conversations.sort(by: { (firstItem, secondItem) in
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
                let filtered = contacts.filter({ newContact in !self.contacts.contains(where: { oldContact in newContact.id == oldContact.id }) })
                self.contacts.append(contentsOf: filtered)
                contactsDelegate?.updateUI(animation: false, reloadSections: false)
                for contact in contacts {
                    addImageLoader(contact)
                }
            } catch {
                log("Failed to get contacts with error: \(error.localizedDescription)")
            }
        }
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
        contactsImages.removeAll()
        let req = ThreadsRequest(count: conversationsLazyList.count, offset: conversationsLazyList.offset)
        getThreads(req)
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

