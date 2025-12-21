//
//  MemberAddParticipantButtonCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import UIKit
import Chat
import SwiftUI

final class MemberAddParticipantButtonCell: UITableViewCell {

    // MARK: - UI Components
    private let container = UIView()
    private let addParticipantImageView = UIImageView(image: UIImage(systemName: "person.badge.plus"))
    private let addParticipantLabel = UILabel()
    
    // MARK: - State
    var conversation: Conversation?
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onAddParticipantTapped))
        container.addGestureRecognizer(tapGesture)
        contentView.addSubview(container)
        
        addParticipantLabel.translatesAutoresizingMaskIntoConstraints = false
        addParticipantLabel.text = "Thread.invite".bundleLocalized()
        addParticipantLabel.font = UIFont.normal(.body)
        addParticipantLabel.textAlignment = Language.isRTL ? .right : .left
        addParticipantLabel.textColor = Color.App.accentUIColor
        container.addSubview(addParticipantLabel)
       
        addParticipantImageView.translatesAutoresizingMaskIntoConstraints = false
        addParticipantImageView.tintColor = Color.App.accentUIColor
        addParticipantImageView.contentMode = .scaleAspectFit
        container.addSubview(addParticipantImageView)
        
        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            addParticipantImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            addParticipantImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 0),
            addParticipantImageView.widthAnchor.constraint(equalToConstant: 26),
            addParticipantImageView.heightAnchor.constraint(equalToConstant: 22),
            
            addParticipantLabel.leadingAnchor.constraint(equalTo: addParticipantImageView.trailingAnchor, constant: 0),
            addParticipantLabel.centerYAnchor.constraint(equalTo: addParticipantImageView.centerYAnchor, constant: 2),
            addParticipantLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            addParticipantLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
    
    @objc private func onAddParticipantTapped() {
        let rootView = AddParticipantsToThreadView() { [weak self] contacts in
            self?.onSelectedContacts(Array(contacts))
        }
        .injectAllObjects()
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        
        let vc = UIHostingController(rootView: rootView)
        vc.modalPresentationStyle = .formSheet
        guard let parentVC = parentViewController else { return }
        parentVC.present(vc, animated: true)
    }
    
    private func onSelectedContacts(_ contacts: [Contact]) {
        if conversation?.type?.isPrivate == true, conversation?.group == true {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                AdminLimitHistoryTimeDialog(threadId: conversation?.id ?? -1) { [weak self] historyTime in
                    guard let self = self else { return }
                    if let historyTime = historyTime {
                        add(contacts, historyTime)
                    } else {
                        add(contacts)
                    }
                }
                    .injectAllObjects()
                    .environmentObject(AppState.shared.objectsContainer)
            )
        } else {
            add(contacts)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: true)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: false)
        }
    }
    
    private func setDimColor(dim: Bool) {
        container.alpha = dim ? 0.5 : 1.0
    }
    
    private func add(_ contacts: [Contact], _ historyTime: UInt? = nil) {
        guard let threadId = conversation?.id else { return }
        let invitees: [Invitee] = contacts.compactMap{ .init(id: $0.user?.username, idType: .username, historyTime: historyTime) }
        let req = AddParticipantRequest(invitees: invitees, threadId: threadId)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.participant.add(req)
        }
    }
}

// MARK: - UIView helper
private extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let next = parentResponder?.next {
            if let vc = next as? UIViewController { return vc }
            parentResponder = next
        }
        return nil
    }
}
