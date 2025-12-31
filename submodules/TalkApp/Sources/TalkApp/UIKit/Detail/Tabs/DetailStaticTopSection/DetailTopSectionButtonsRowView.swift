//
//  DetailTopSectionButtonsRowView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/29/25.
//

import UIKit
import TalkViewModels
import Combine
import Chat
import SwiftUI
import TalkUI

public class DetailTopSectionButtonsRowView: UIStackView {
    /// Views
    private let btnExit = DetailViewButtonItem(asssetImageName: "ic_exit")
    private let btnDeleteContact = DetailViewButtonItem(systemName: "trash")
    private let btnAddContact = DetailViewButtonItem(systemName: "person.badge.plus")
    private let btnMute = DetailViewButtonItem(systemName: "bell.slash.fill")
    private let btnPerson = DetailViewButtonItem(systemName: "person")
    private let btnExportMessages = DetailViewButtonItem(asssetImageName: "ic_export")
    private let btnShowMore = DetailViewButtonItem(systemName: "ellipsis")
    
    /// Models
    public weak var viewModel: ThreadDetailViewModel?
    private var cancellableSet: Set<AnyCancellable> = Set()
    
    init(viewModel: ThreadDetailViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        updateUI()
        register()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {        
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        alignment = .center
        spacing = 8
        distribution = .equalSpacing
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        btnExit.onTap = { [weak self] in
            self?.onLeaveConversationTapped()
        }
        
        btnDeleteContact.onTap = { [weak self] in
            self?.onDeleteContactTapped()
        }
        
        btnAddContact.onTap = { [weak self] in
            self?.onAddContactTapped()
        }
        
        btnMute.onTap = { [weak self] in
            self?.viewModel?.toggleMute()
        }
        
        btnExportMessages.onTap = { [weak self] in
            
        }
        
        btnShowMore.onTap = { [weak self] in
            self?.onShowMoreTapped()
        }
        
        addArrangedSubviews([btnExit,
                             btnDeleteContact,
                             btnAddContact,
                             btnMute,
                             btnExportMessages,
                             btnPerson,
                             btnShowMore])
    }
    
    private func register() {
        viewModel?.objectWillChange
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellableSet)
        
        viewModel?.participantDetailViewModel?.objectWillChange
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellableSet)
    }
    
    private func updateUI() {
        let isSelfThread = viewModel?.thread?.type == .selfThread
        let isArchive = viewModel?.thread?.isArchive == true
        let isGroup = viewModel?.thread?.group == true
        let isP2PContact = !isGroup
        
        let muteImageName = viewModel?.thread?.mute ?? false ? "bell.slash.fill" : "bell.fill"
        btnMute.setImage(image: UIImage(systemName: muteImageName) ?? .init())
        
        let showDeleteButton = isP2PContact && deletableParticipantContact != nil
        let showAddButton = !showDeleteButton && isP2PContact
        btnAddContact.isHidden = !showAddButton
        btnAddContact.isUserInteractionEnabled = showAddButton
        btnDeleteContact.isHidden = !showDeleteButton
        btnDeleteContact.isUserInteractionEnabled = showDeleteButton
        
        btnPerson.alpha = 0.4
        btnPerson.isUserInteractionEnabled = false
        
        btnExportMessages.alpha = 0.4
        btnExportMessages.isUserInteractionEnabled = false
        
        btnExit.isHidden = !isGroup
        btnExit.isUserInteractionEnabled = isGroup
        
        if isSelfThread {
            btnExit.isHidden = true
            btnExit.isUserInteractionEnabled = false
            
            btnAddContact.isHidden = true
            btnAddContact.isUserInteractionEnabled = false
            
            btnMute.isHidden = true
            btnMute.isUserInteractionEnabled = false
        }
    }
}

/// Actions
extension DetailTopSectionButtonsRowView {
    private func onAddContactTapped() {
        guard let participant = emptyThreadParticipant() else { return }
        let contactViewModel = AppState.shared.objectsContainer.contactsVM
        let contact = Contact(cellphoneNumber: participant.cellphoneNumber,
                              email: participant.email,
                              firstName: participant.firstName,
                              lastName: participant.lastName,
                              user: .init(username: participant.username))
        contactViewModel.addContact = contact
        contactViewModel.showAddOrEditContactSheet = true
        contactViewModel.animateObjectWillChange()
    }
    
    private func onLeaveConversationTapped() {
        guard let thread = viewModel?.thread else { return }
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(LeaveThreadDialog(conversation: thread))
    }

    private func onDeleteContactTapped() {
        guard let participant = deletableParticipantContact else { return }
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
            ConversationDetailDeleteContactDialog(participant: participant)
        )
    }
    
    private func onShowMoreTapped() {
        guard let thread = viewModel?.thread else { return }
        let participant = viewModel?.participantDetailViewModel?.participant
        let view = VStack(alignment: .leading, spacing: 0) {
            UserActionMenu(participant: participant, thread: thread.toClass()) {
                /// On Tapped an option
                PopupViewController.dismissAndRemovePopup()
            }
            .environmentObject(AppState.shared.objectsContainer.threadsVM)
        }
            .environment(\.locale, Locale.current)
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
            .font(Font.normal(.body))
            .foregroundColor(.primary)
            .frame(width: 246)
            .background(MixMaterialBackground())
            .clipShape(RoundedRectangle(cornerRadius: 12))
        PopupViewController.showPopup(view: view, anchorView: btnShowMore, parentVCView: superview?.superview)
    }
}

/// Extra functions
extension DetailTopSectionButtonsRowView  {
    private var deletableParticipantContact: Participant? {
        let participant = viewModel?.participantDetailViewModel?.participant
        if participant != nil && participant?.contactId == nil {
            return nil
        }
        return participant ?? emptyThreadContantParticipant()
    }
    
    private func emptyThreadContantParticipant() -> Participant? {
        let firstParticipant = emptyThreadParticipant()
        let hasContactId = firstParticipant?.contactId != nil
        let emptyThreadParticipnat = hasContactId ? firstParticipant : nil
        return emptyThreadParticipnat
    }
    
    private func isFakeConversation() -> Bool {
        viewModel?.thread?.id == LocalId.emptyThread.rawValue
    }
    
    private func firstThreadPartnerParticipant() -> Participant? {
        viewModel?.thread?.participants?.first
    }
    
    private func emptyThreadParticipant() -> Participant? {
        return isFakeConversation() ? firstThreadPartnerParticipant() : nil
    }
}

