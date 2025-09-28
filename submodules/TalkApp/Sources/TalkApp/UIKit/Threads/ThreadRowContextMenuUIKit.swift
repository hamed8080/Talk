//
//  ThreadRowContextMenuUIKit.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import TalkViewModels
import SwiftUI

class ThreadRowContextMenuUIKit: UIView {
    private let conversation: CalculatedConversation
    private let image: UIImage?
    private let container: ContextMenuContainerView?
    
    init(conversation: CalculatedConversation, image: UIImage?, container: ContextMenuContainerView?) {
        self.conversation = conversation
        self.image = image
        self.container = container
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        
        let menu = configureMenu()
        menu.contexMenuContainer = container
        menu.translatesAutoresizingMaskIntoConstraints = false
        addSubview(menu)
        
        let cell = ConversationCell(frame: .zero)
        cell.setConversation(conversation: conversation)
        cell.setImage(image)
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
       
        
        let hasSpaceToAddMorePin = vm.serverSortedPins.count < 5
        let isInArchiveList = conversation.isArchive == true
        if !isInArchiveList {
            let pinKey = conversation.pin == true ? "Thread.unpin" : "Thread.pin"
            let pinImage = conversation.pin == true ? "pin.slash" : "pin"
            let model = ActionItemModel(title: pinKey.bundleLocalized(), image: pinImage)
            let pinAction = ActionMenuItem(model: model) { [weak self] in
                guard let self = self else { return }
                if !hasSpaceToAddMorePin {
                    /// Hide menu
                    menu.contexMenuContainer?.hide()
                    
                    /// Show dialog
                    let warningView = WarningDialogView(message: "Errors.warningCantAddMorePinThread".bundleLocalized())
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(warningView)
                    return
                }
                
                vm.togglePin(conversation.toStruct())
                menu.contexMenuContainer?.hide()
            }
            menu.addItem(pinAction)
        }
        
        if conversation.type != .selfThread, conversation.isArchive ?? false == false {
            let muteKey = conversation.mute == true ? "Thread.unmute" : "Thread.mute"
            let muteImage = conversation.mute == true ? "speaker" : "speaker.slash"
            let model = ActionItemModel(title: muteKey.bundleLocalized(), image: muteImage)
            let muteAction = ActionMenuItem(model: model) { [weak self] in
                guard let self = self else { return }
                vm.toggleMute(conversation.toStruct())
                menu.contexMenuContainer?.hide()
            }
            menu.addItem(muteAction)
        }
        
        if !conversation.closed, conversation.type != .selfThread {
            let archiveKey = conversation.isArchive == true ? "Thread.unarchive" : "Thread.archive"
            let archiveImage = conversation.isArchive == true ? "tray.and.arrow.up" : "tray.and.arrow.down"
            let model = ActionItemModel(title: archiveKey.bundleLocalized(), image: archiveImage)
            let archiveAction = ActionMenuItem(model: model) { [weak self] in
                guard let self = self else { return }
                vm.toggleArchive(conversation.toStruct())
                menu.contexMenuContainer?.hide()
            }
            menu.addItem(archiveAction)
        }
        
        return menu
    }
}
