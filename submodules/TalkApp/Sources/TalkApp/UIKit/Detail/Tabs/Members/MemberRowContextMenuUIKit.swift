//
//  MembersRowContextMenuUIKit.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import TalkViewModels
import SwiftUI

class MemberRowContextMenuUIKit: UIView {
    private let participant: Participant
    private let image: UIImage?
    private let container: ContextMenuContainerView?
    public weak var viewModel: ParticipantsViewModel?
    
    init(viewModel: ParticipantsViewModel?, participant: Participant, image: UIImage?, container: ContextMenuContainerView?) {
        self.viewModel = viewModel
        self.participant = participant
        self.image = image
        self.container = container
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let menu = configureMenu()
        menu.contexMenuContainer = container
        menu.translatesAutoresizingMaskIntoConstraints = false
        addSubview(menu)
        
        let cell = MemberCell(frame: .zero)
        cell.setItem(participant, image)
        cell.separtor.isHidden = true
        cell.contentView.backgroundColor = Color.App.bgPrimaryUIColor
        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.layer.cornerRadius = 16
        cell.layer.masksToBounds = true
        cell.contentView.layer.cornerRadius = 16
        cell.contentView.layer.masksToBounds = true
        addSubview(cell)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: container?.frame.height ?? 0),
            
            cell.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cell.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cell.heightAnchor.constraint(equalToConstant: 82),
            cell.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -48),
            
            menu.topAnchor.constraint(equalTo: cell.bottomAnchor, constant: 8),
            menu.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 0),
            menu.widthAnchor.constraint(equalToConstant: 256),
        ])
    }
    
    private func configureMenu() -> CustomMenu {
        let menu = CustomMenu()
        let vm = AppState.shared.objectsContainer.threadsVM
        let isMe = participant.id == AppState.shared.user?.id
        if !isMe, viewModel?.thread?.admin == true, (participant.admin ?? false) == false {
            let model = ActionItemModel(title: "Participant.addAdminAccess".bundleLocalized(), image: "person.crop.circle.badge.plus")
            let adminAction = ActionMenuItem(model: model) { [weak self] in
                guard let self = self else { return }
                viewModel?.makeAdmin(participant)
                menu.contexMenuContainer?.hide()
            }
            menu.addItem(adminAction)
        }
        
        if !isMe, viewModel?.thread?.admin == true, (participant.admin ?? false) == true {
            let model = ActionItemModel(title: "Participant.removeAdminAccess".bundleLocalized(), image: "person.crop.circle.badge.minus")
            let removeAdminAction = ActionMenuItem(model: model) { [weak self] in
                guard let self = self else { return }
                viewModel?.removeAdminRole(participant)
                menu.contexMenuContainer?.hide()
            }
            menu.addItem(removeAdminAction)
        }
        
        if !isMe, let viewModel = viewModel, viewModel.thread?.admin == true {
            let model = ActionItemModel(title: "General.delete".bundleLocalized(), image: "trash", color: Color.App.redUIColor ?? .red)
            let removeAdminAction = ActionMenuItem(model: model) { [weak self] in
                guard let self = self else { return }
                let dialog = AnyView(
                    DeleteParticipantDialog(participant: participant)
                        .environmentObject(viewModel)
                )
                AppState.shared.objectsContainer.appOverlayVM.dialogView = dialog
                menu.contexMenuContainer?.hide()
            }
            menu.addItem(removeAdminAction)
        }
        return menu
    }
}
