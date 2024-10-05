//
//  DetailViewModel.swift
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

public final class ParticipantDetailViewModel: ObservableObject, Hashable {
    public static func == (lhs: ParticipantDetailViewModel, rhs: ParticipantDetailViewModel) -> Bool {
        lhs.participant.id == rhs.participant.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(participant.id)
    }

    private(set) var cancelable: Set<AnyCancellable> = []
    public var participant: Participant
    public var title: String { participant.name ?? "" }
    public var notSeenString: String? { participant.notSeenDuration?.localFormattedTime }
    public var cellPhoneNumber: String? { participant.cellphoneNumber }
    public var isBlock: Bool { participant.blocked == true }
    public var bio: String? { participant.chatProfileVO?.bio }
    public var showInfoGroupBox: Bool { bio != nil || cellPhoneNumber != nil }
    public var url: String? { participant.image }

    public var partnerContact: Contact?
    public var searchText: String = ""
    @Published public var dismiss = false
    @Published public var isLoading = false
    @Published public var successEdited: Bool = false
    private var objectId = UUID().uuidString
    private let P2P_PARTNER_CONTACT_KEY: String
    private let PARTICIPANT_EDIT_CONTACT_KEY: String

    public var canShowEditButton: Bool {
        participant.contactId != nil
    }

    public init(participant: Participant) {
        P2P_PARTNER_CONTACT_KEY = "P2P-PARTNER-CONTACT-KEY-\(objectId)"
        PARTICIPANT_EDIT_CONTACT_KEY = "PARTICIPANT-EDIT-CONTACT-KEY-\(objectId)"
        self.participant = participant
        setup()
    }

    public func setup() {
        setPartnerContact()        
        NotificationCenter.contact.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] value in
                self?.onContactEvent(value)
            }
            .store(in: &cancelable)
    }

    private func onContactEvent(_ event: ContactEventTypes) {
        switch event {
        case .blocked(let chatResponse):
            onBlock(chatResponse)
        case .unblocked(let chatResponse):
            onUNBlock(chatResponse)
        case .add(let chatResponse):
            onAddContact(chatResponse)
        case .delete(let response, let deleted):
            onDeletedContact(response, deleted)
        case .contacts(let response):
            onP2PConatct(response)
        default:
            break
        }
    }

    public func createThread() {
        if let contactId = participant.contactId {
            AppState.shared.openThread(contact: .init(id: contactId, user: .init(User(coreUserId: participant.coreUserId))))
        } else {
            AppState.shared.openThread(participant: participant)
        }
    }

    public func copyPhone() {
        guard let phone = cellPhoneNumber else { return }
        UIPasteboard.general.string = phone
    }

    public func blockUnBlock() {
        let unblcokReq = UnBlockRequest(contactId: participant.contactId, userId: participant.coreUserId)
        let blockReq = BlockRequest(contactId: participant.contactId, userId: participant.coreUserId)
        if participant.blocked == true {
            RequestsManager.shared.append(value: unblcokReq)
            ChatManager.activeInstance?.contact.unBlock(unblcokReq)
        } else {
            RequestsManager.shared.append(value: blockReq)
            ChatManager.activeInstance?.contact.block(blockReq)
        }
    }

    private func onBlock(_ response: ChatResponse<BlockedContactResponse>) {
        if response.result != nil {
            participant.blocked = true
            animateObjectWillChange()
        }
    }

    private func onUNBlock(_ response: ChatResponse<BlockedContactResponse>) {
        if response.result != nil {
            participant.blocked = false
            animateObjectWillChange()
        }
    }

    /// In this method we have to listen to addContact globally
    /// even if it has been called by other methods such as the user clicks on add contact in thread detail
    /// because it uses global ContactsViewModel, so after adding for the first time we should show the edit button.
    private func onAddContact(_ response: ChatResponse<[Contact]>) {
        response.result?.forEach{ contact in
            if contact.user?.username == participant.username {
                participant.contactId = contact.id
                if let firstName = contact.firstName, let lastName = contact.lastName {
                    participant.contactName = "\(firstName) \(lastName)"
                }
            }
            partnerContact = response.result?.first
            if let index = AppState.shared.objectsContainer.contactsVM.contacts.firstIndex(where: {$0.id == contact.id}) {
                AppState.shared.objectsContainer.contactsVM.contacts[index] = contact
            }
        }
        if response.pop(prepend: PARTICIPANT_EDIT_CONTACT_KEY) != nil {
            successEdited = true
        }
        animateObjectWillChange()
    }

    private func onDeletedContact(_ response: ChatResponse<[Contact]>, _ deleted: Bool) {
        if deleted {
            if response.result?.first?.id == participant.contactId {
                participant.contactId = nil
                partnerContact = nil
                animateObjectWillChange()
            }
        }
    }

    private var partnerContactId: Int? {
        participant.contactId
    }

    private func setPartnerContact() {
        if let localContact = AppState.shared.objectsContainer.contactsVM.contacts.first(where:({$0.id == partnerContactId})) {
            partnerContact = localContact
            animateObjectWillChange()
        } else {
            fetchPartnerContact()
        }
    }

    private func fetchPartnerContact() {
        var req: ContactsRequest?
        if let contactId = partnerContactId {
            req = ContactsRequest(id: contactId)
        } else if let coreUserId = participant.coreUserId {
            req = ContactsRequest(coreUserId: coreUserId)
        } else if let userName = participant.username {
            req = ContactsRequest(userName: userName)
        }
        guard let req = req else { return }
        RequestsManager.shared.append(prepend: P2P_PARTNER_CONTACT_KEY, value: req)
        ChatManager.activeInstance?.contact.get(req)
    }

    private func onP2PConatct(_ response: ChatResponse<[Contact]>) {
        if !response.cache, response.pop(prepend: P2P_PARTNER_CONTACT_KEY) != nil, let contact = response.result?.first {
            self.partnerContact = contact
            participant.contactId = contact.id
            participant.cellphoneNumber = participant.cellphoneNumber ?? contact.cellphoneNumber
            animateObjectWillChange()
        }
    }

    public func editContact(contactValue: String, firstName: String, lastName: String) {
        let isNumber = ContactsViewModel.isNumber(value: contactValue)
        let req: AddContactRequest = isNumber ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue)
        RequestsManager.shared.append(prepend: PARTICIPANT_EDIT_CONTACT_KEY, value: req)
        ChatManager.activeInstance?.contact.add(req)
    }

    public func cancelObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }

    deinit {
        print("deinit ParticipantDetailViewModel")
    }
}

