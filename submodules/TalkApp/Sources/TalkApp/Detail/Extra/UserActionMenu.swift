//
//  UserActionMenu.swift
//  Talk
//
//  Created by hamed on 11/1/23.
//

import SwiftUI
import TalkViewModels
import ActionableContextMenu
import TalkModels
import Chat
import TalkUI

struct UserActionMenu: View {
    let participant: Participant?
    @EnvironmentObject var contactViewModel: ContactsViewModel
    var thread: CalculatedConversation
    @EnvironmentObject var viewModel: ThreadsViewModel
    var onTapped: () -> Void

    var body: some View {
        /// You should be admin or the thread should be a p2p thread with two people.
        if thread.admin == true || thread.group == false {
            ContextMenuButton(title: deleteTitle, image: "trash", iconColor: Color.App.red, bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onDeleteConversationTapped()
            }
            .foregroundStyle(Color.App.red)
        }

        if thread.group == true, thread.type?.isChannelType == false, thread.admin == true {
            Divider()
            ContextMenuButton(title: "Thread.closeThread".bundleLocalized(), image: "lock", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onCloseConversationTapped()
            }
        }
        
        Divider()

        if let participant = participant {
            let blockKey = participant.blocked == true ? "General.unblock" : "General.block"
            ContextMenuButton(title: blockKey.bundleLocalized(), image: participant.blocked == true ? "hand.raised.slash" : "hand.raised", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onBlockUnblockTapped()
            }
        }
        
        sandboxTestOptions
    }
    
    @ViewBuilder
    var sandboxTestOptions: some View {
        if EnvironmentValues.isTalkTest {
            ContextMenuButton(title: "General.share".bundleLocalized(), image: "square.and.arrow.up", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onTapped()
            }
            .disabled(true)
            .sandboxLabel()
            
            ContextMenuButton(title: "Thread.export".bundleLocalized(), image: "tray.and.arrow.up", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onTapped()
            }
            .disabled(true)
            .sandboxLabel()
            
            ContextMenuButton(title: "Thread.clearHistory".bundleLocalized(), image: "clock", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onClearHistoryTapped()
            }
            .sandboxLabel()
            
            ContextMenuButton(title: "Thread.addToFolder".bundleLocalized(), image: "folder.badge.plus", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onAddToFolderTapped()
            }
            .sandboxLabel()
            
            ContextMenuButton(title: "Thread.spam".bundleLocalized(), image: "ladybug", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                onSpamTapped()
            }
            .sandboxLabel()
            
            if canAddParticipant {
                ContextMenuButton(title: "Thread.invite".bundleLocalized(), image: "person.crop.circle.badge.plus", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                    onInviteTapped()
                }
                .sandboxLabel()
            }
            
            ContextMenuButton(title: "\(thread.id ?? -1)", image: "info", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                UIPasteboard.general.string = "\(thread.id ?? -1)"
                dump(thread)
            }
            .sandboxLabel()
        }
    }

    private func onBlockUnblockTapped() {
        guard let participant = participant else { return }
        onTapped()
        delayActionOnHidePopover {
            if participant.blocked == true, let contactId = participant.contactId {
                contactViewModel.unblockWith(contactId)
            } else {
                contactViewModel.block(.init(id: participant.contactId))
            }
        }
    }

    private func delayActionOnHidePopover(_ action: (() -> Void)? = nil) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            action?()
        }
    }

    private func onClearHistoryTapped() {
        onTapped()
        delayActionOnHidePopover {
            viewModel.clearHistory(thread.toStruct())
        }
    }

    private func onAddToFolderTapped() {
        onTapped()
        delayActionOnHidePopover {
            viewModel.showAddThreadToTag(thread.toStruct())
        }
    }

    private func onSpamTapped() {
        onTapped()
        delayActionOnHidePopover {
            viewModel.spamPV(thread.toStruct())
        }
    }

    private func onInviteTapped() {
        onTapped()
        delayActionOnHidePopover {
            viewModel.showAddParticipants(thread.toStruct())
        }
    }

    private func onDeleteConversationTapped() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadDialog(threadId: thread.id))
        onTapped()
    }

    private func onCloseConversationTapped() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(CloseThreadDialog(conversation: thread.toStruct()))
        onTapped()
    }

    private var deleteTitle: String {
        let deleteKey = thread.group == false ? "" : "Thread.delete".bundleLocalized()
        let key = thread.type?.isChannelType == true ? "Thread.channel" : thread.group == true ? "Thread.group" : ""
        let groupLocalized = String(format: deleteKey, key.bundleLocalized())
        let p2pLocalized = "Genreal.deleteConversation".bundleLocalized()
        return thread.group == true ? groupLocalized : p2pLocalized
    }
    
    private var canAddParticipant: Bool {
        thread.group ?? false && thread.admin ?? false == true
    }
}

struct UserActionMenu_Previews: PreviewProvider {
    static var previews: some View {
        UserActionMenu(participant: .init(name: "Hamed Hosseini"), thread: .init()) {}
    }
}
