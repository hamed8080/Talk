//
//  ThreadRowActionMenu.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Foundation
import SwiftUI
import TalkViewModels
import ActionableContextMenu
import TalkModels
import Chat
import TalkModels
import TalkUI

struct ThreadRowActionMenu: View {
    @Binding var showPopover: Bool
    var isDetailView: Bool = false
    var thread: CalculatedConversation
    @EnvironmentObject var viewModel: ThreadsViewModel
    private var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var body: some View {
        if canPinUnPin {
            ContextMenuButton(title: pinUnpinTitle, image: "pin") {
                onPinUnpinTapped()
            }
        }

        if canMuteUnmute {
            ContextMenuButton(title: muteUnmuteTitle, image: "speaker.slash") {
                onMuteUnmuteTapped()
            }
        }

        if !isDetailView, !thread.closed {
            ContextMenuButton(title: archiveTitle, image: archiveImage) {
                onArchiveUnArchiveTapped()
            }
        }

        if EnvironmentValues.isTalkTest {
            ContextMenuButton(title: "Thread.clearHistory".bundleLocalized(), image: "clock") {
                onClearHistoryTapped()
            }
            .sandboxLabel()
            
            ContextMenuButton(title: "Thread.addToFolder".bundleLocalized(), image: "folder.badge.plus") {
                onAddToFolderTapped()
            }
            .sandboxLabel()
            
            ContextMenuButton(title: "Thread.spam".bundleLocalized(), image: "ladybug") {
                onSpamTapped()
            }
            .sandboxLabel()
            
            if canAddParticipant {
                ContextMenuButton(title: "Thread.invite".bundleLocalized(), image: "person.crop.circle.badge.plus") {
                    onInviteTapped()
                }
                .sandboxLabel()
            }
            
            ContextMenuButton(title: "\(thread.id ?? -1)", image: "info") {
                UIPasteboard.general.string = "\(thread.id ?? -1)"
                dump(thread)
            }
            .sandboxLabel()
        }

        Divider()

        if isDetailView, thread.group == true {
            ContextMenuButton(title: leaveTitle, image: "rectangle.portrait.and.arrow.right", iconColor: Color.App.red) {
                onLeaveConversationTapped()
            }
            .foregroundStyle(Color.App.red)
        }

        /// You should be admin or the thread should be a p2p thread with two people.
        if isDetailView, thread.admin == true || thread.group == false {
            ContextMenuButton(title: deleteTitle, image: "trash", iconColor: Color.App.red) {
                onDeleteConversationTapped()
            }
            .foregroundStyle(Color.App.red)
        }

        if isDetailView, thread.group == true, thread.type?.isChannelType == false, thread.admin == true {
            Divider()
            ContextMenuButton(title: "Thread.closeThread".bundleLocalized(), image: "lock") {
                onCloseConversationTapped()
            }
        }
    }

    private func onPinUnpinTapped() {
        showPopover = false
        delayActionOnHidePopover {
            viewModel.togglePin(thread.toStruct())
        }
    }

    private func onMuteUnmuteTapped() {
        showPopover = false
        delayActionOnHidePopover {
            viewModel.toggleMute(thread.toStruct())
        }
    }

    private func onClearHistoryTapped() {
        showPopover = false
        delayActionOnHidePopover {
            viewModel.clearHistory(thread.toStruct())
        }
    }

    private func onAddToFolderTapped() {
        showPopover = false
        delayActionOnHidePopover {
            viewModel.showAddThreadToTag(thread.toStruct())
        }
    }

    private func onSpamTapped() {
        showPopover = false
        delayActionOnHidePopover {
            viewModel.spamPV(thread.toStruct())
        }
    }

    private func onArchiveUnArchiveTapped() {
        showPopover = false
        delayActionOnHidePopover {
            let isUnarchived = thread.isArchive == false || thread.isArchive == nil
            AppState.shared.objectsContainer.archivesVM.toggleArchive(thread.toStruct())
            if isUnarchived {
                showArchivePopupIfNeeded()
            }
        }
    }

    private func onInviteTapped() {
        showPopover = false
        delayActionOnHidePopover {
            viewModel.showAddParticipants(thread.toStruct())
        }
    }

    private func onLeaveConversationTapped() {
        showPopover = false
        delayActionOnHidePopover {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(LeaveThreadDialog(conversation: thread.toStruct()))
        }
    }

    private func onDeleteConversationTapped() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadDialog(threadId: thread.id))
        showPopover = false
    }

    private func onCloseConversationTapped() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(CloseThreadDialog(conversation: thread.toStruct()))
        showPopover = false
    }

    private func delayActionOnHidePopover(_ action: (() -> Void)? = nil) {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            action?()
        }
    }

    private var deleteTitle: String {
        let deleteKey = thread.group == false ? "" : "Thread.delete".bundleLocalized()
        let key = thread.type?.isChannelType == true ? "Thread.channel" : thread.group == true ? "Thread.group" : ""
        let groupLocalized = String(format: deleteKey, String(localized: .init(key), bundle: Language.preferedBundle))
        let p2pLocalized = String(localized: .init("Genreal.deleteConversation"), bundle: Language.preferedBundle)
        return thread.group == true ? groupLocalized : p2pLocalized
    }

    private var  leaveTitle: String {
        let leaveKey = String(localized: .init("Thread.leave"), bundle: Language.preferedBundle)
        let key = thread.type?.isChannelType == true ? "Thread.channel" : "Thread.group"
        return String(format: leaveKey, String(localized: .init(key), bundle: Language.preferedBundle))
    }

    private var archiveTitle: String {
        let archiveKey = thread.isArchive == true ? "Thread.unarchive" : "Thread.archive"
        return archiveKey.bundleLocalized()
    }

    private var archiveImage: String {
        return thread.isArchive == true ?  "tray.and.arrow.up" : "tray.and.arrow.down"
    }

    private var pinUnpinTitle: String {
        let key = (thread.pin ?? false) ? "Thread.unpin" : "Thread.pin"
        return key.bundleLocalized()
    }

    private var canPinUnPin: Bool {
        !isDetailView && (thread.pin == true || viewModel.serverSortedPins.count < 5)
    }

    private var canMuteUnmute: Bool {
        thread.type != .selfThread && !isDetailView
    }

    private var muteUnmuteTitle: String {
        let key = (thread.mute ?? false) ? "Thread.unmute" : "Thread.mute"
        return key.bundleLocalized()
    }

    private func showArchivePopupIfNeeded() {
        if AppState.shared.objectsContainer.archivesVM.hasShownToastGuide { return }
        let leadingView = Image(systemName: "tray.and.arrow.up")
        AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: leadingView,
                                                            message: "ArchivedTab.guide".bundleLocalized(),
                                                            messageColor: Color.App.textPrimary,
                                                            duration: .slow)
        AppState.shared.objectsContainer.archivesVM.hasShownToastGuide = true
    }
}
