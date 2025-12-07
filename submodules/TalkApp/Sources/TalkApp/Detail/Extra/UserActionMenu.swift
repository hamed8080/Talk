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
    @Binding var showPopover: Bool
    let participant: Participant
    @EnvironmentObject var contactViewModel: ContactsViewModel

    var body: some View {
        Divider()

        let blockKey = participant.blocked == true ? "General.unblock" : "General.block"
        ContextMenuButton(title: blockKey.bundleLocalized(), image: participant.blocked == true ? "hand.raised.slash" : "hand.raised", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
           onBlockUnblockTapped()
        }

        if EnvironmentValues.isTalkTest {
            ContextMenuButton(title: "General.share".bundleLocalized(), image: "square.and.arrow.up", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                showPopover = false
            }
            .disabled(true)
            .sandboxLabel()

            ContextMenuButton(title: "Thread.export".bundleLocalized(), image: "tray.and.arrow.up", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                showPopover = false
            }
            .disabled(true)
            .sandboxLabel()
        }
    }

    private func onBlockUnblockTapped() {
        showPopover = false
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
}

struct UserActionMenu_Previews: PreviewProvider {
    static var previews: some View {
        UserActionMenu(showPopover: .constant(true), participant: .init(name: "Hamed Hosseini"))
    }
}
