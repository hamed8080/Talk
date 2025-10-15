//
//  MessageContainerStackView+UIMenuItems.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import Chat
import TalkModels
import TalkViewModels
import TalkExtensions
import TalkUI
import SwiftUI
import Photos

//MARK: Action menus
@MainActor
extension MessageContainerStackView {

    public func menu(model: ActionModel, indexPath: IndexPath?, onMenuClickedDismiss: @escaping () -> Void ) -> CustomMenu {
        let message: HistoryMessageType = model.message
        let threadVM = model.threadVM
        let viewModel = model.viewModel

        let menu = CustomMenu()
        menu.contexMenuContainer = (viewModel.threadVM?.delegate as? ThreadViewController)?.contextMenuContainer


        let isChannel = threadVM?.thread.type?.isChannelType == true
        let admin = threadVM?.thread.admin == true
        if (isChannel && admin) || (!isChannel) {
            let replyAction = ActionMenuItem(model: .reply) { [weak self] in
                self?.onReplyAction(model)
                onMenuClickedDismiss()
            }
            menu.addItem(replyAction)
            
            if threadVM?.thread.type?.isChannelType == false, threadVM?.thread.group == true, !viewModel.calMessage.isMe {
                let replyPrivatelyAction = ActionMenuItem(model: .replyPrivately) { [weak self] in
                    self?.onReplyPrivatelyAction(model)
                    onMenuClickedDismiss()
                }
                menu.addItem(replyPrivatelyAction)
            }
        }

        let forwardAction = ActionMenuItem(model: .forward) { [weak self] in
            self?.onForwardAction(model)
            onMenuClickedDismiss()
        }
        menu.addItem(forwardAction)

        if viewModel.calMessage.canEdit {
            let emptyText = message.message == nil || message.message == ""
            let editAction = ActionMenuItem(model: emptyText ? .add : .edit) { [weak self] in
                self?.onEditAction(model)
                onMenuClickedDismiss()
            }
            menu.addItem(editAction)
        }

        if let threadVM = threadVM, viewModel.message.ownerId == AppState.shared.user?.id && threadVM.thread.group == true {
            let seenListAction = ActionMenuItem(model: .seenParticipants) { [weak self] in
                self?.onSeenListAction(model)
                onMenuClickedDismiss()
            }
            menu.addItem(seenListAction)
        }

        if viewModel.message.isImage, viewModel.fileState.state == .completed {
            let saveImageAction = ActionMenuItem(model: .saveImage) { [weak self] in
                self?.onSaveAction(model)
                onMenuClickedDismiss()
            }
            menu.addItem(saveImageAction)
        }

        if viewModel.calMessage.rowType.isVideo, viewModel.fileState.state == .completed {
            let saveVideoAction = ActionMenuItem(model: .saveVideo) { [weak self] in
                Task { [weak self] in
                    guard let self = self else { return }
                    if let url = await self.getURL(message: model.message) {
                        await PhotoLibrary.shared.onSaveVideoAction(url: url)
                        onMenuClickedDismiss()
                    }
                }
            }
            menu.addItem(saveVideoAction)
        }

        if !viewModel.message.isFileType || message.message?.isEmpty == false {
            let copyAction = ActionMenuItem(model: .copy) { [weak self] in
                self?.onCopyAction(model)
                onMenuClickedDismiss()
            }
            menu.addItem(copyAction)
        }
        
        if viewModel.message.isFileType, viewModel.fileState.state == .completed {
            let reDownload = ActionMenuItem(model: .reDownload) { [weak self] in
                self?.onReDownload(model)
                onMenuClickedDismiss()
            }
            menu.addItem(reDownload)
        }
        
        if EnvironmentValues.isTalkTest, message.isFileType == true {
            let deleteCacheAction = ActionMenuItem(model: .deleteCache) { [weak self] in
                self?.onDeleteCacheAction(model)
                onMenuClickedDismiss()
            }
            menu.addItem(deleteCacheAction)
        }
        
        if EnvironmentValues.isTalkTest {
            let printMessageDebug = ActionMenuItem(model: .debugPrint(id: model.message.id ?? -1)) { [weak self] in
                self?.onPrintDebug(model)
                onMenuClickedDismiss()
            }
            menu.addItem(printMessageDebug)
        }

        let isPinned = message.id == threadVM?.thread.pinMessage?.id && threadVM?.thread.pinMessage != nil
        if threadVM?.thread.admin == true {
            let pinAction = ActionMenuItem(model: isPinned ? .unpin : .pin) { [weak self] in
                self?.onPinAction(model)
                onMenuClickedDismiss()
            }
            menu.addItem(pinAction)
        }

        let selectAction = ActionMenuItem(model: .select) { [weak self] in
            self?.onSelectAction(model)
            onMenuClickedDismiss()
        }
        menu.addItem(selectAction)

        if let message = message as? Message {
            let isDeletable = DeleteMessagesViewModelModel.isDeletable(isMe: viewModel.calMessage.isMe, message: message, thread: threadVM?.thread)
            if isDeletable {
                let deleteAction = ActionMenuItem(model: .delete) { [weak self] in
                    self?.onDeleteAction(model)
                    onMenuClickedDismiss()
                }
                menu.addItem(deleteAction)
            }
        }
        menu.removeLastSeparator()
        return menu
    }
}

// MARK: Taped actions
@MainActor
private extension MessageContainerStackView {
    func onReplyAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        model.threadVM?.sendContainerViewModel.clear() /// Close edit message if set select mode to forward
        model.threadVM?.replyMessage = message
        model.threadVM?.delegate?.openReplyMode(message)
    }

    func onReplyPrivatelyAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        model.threadVM?.sendContainerViewModel.clear() /// Close edit message if set select mode to forward
        guard let participant = model.message.participant else { return }
        AppState.shared.objectsContainer.navVM.setReplyPrivately(message)
        Task {
            try await AppState.shared.objectsContainer.navVM.openThread(participant: participant)
        }
    }

    func onForwardAction(_ model: ActionModel) {
        AppState.shared.objectsContainer.navVM.setReplyPrivately(nil)
        model.threadVM?.delegate?.showReplyPrivatelyPlaceholder(show: false)
        model.threadVM?.delegate?.openReplyMode(nil)
        model.threadVM?.sendContainerViewModel.clear() /// Close edit message if set select mode to forward
        model.threadVM?.delegate?.setSelection(true)
        if let uniqueId = model.message.uniqueId,
           let indexPath = model.threadVM?.historyVM.sections.indicesByMessageUniqueId(uniqueId) {
            model.threadVM?.delegate?.setTableRowSelected(indexPath)
        }
        cell?.select()
    }

    func onEditAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        model.threadVM?.sendContainerViewModel.setEditMessage(message: message)
        model.threadVM?.delegate?.openEditMode(message)
    }

    func onSeenListAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        AppState.shared.objectsContainer.navVM.wrapAndPush(view: MessageParticipantsSeen(message: message))
    }

    func onSaveAction(_ model: ActionModel) {
        Task { [weak self] in
            guard let self = self else { return }
            if let fileURL = await model.message.fileURL {
                do {
                    try await SaveToAlbumViewModel(fileURL: fileURL).save()
                    
                    /// Show a toast after a successful saving.
                    let imageView = UIImageView(image: UIImage(systemName: "externaldrive.badge.checkmark"))
                    AppState.shared.objectsContainer.appOverlayVM.toast(
                        leadingView: imageView,
                        message: "General.imageSaved",
                        messageColor: Color.App.textPrimaryUIColor!
                    )
                } catch let error as SaveToAlbumViewModel.SaveToAlbumError {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(SaveToAlbumDialogView())
                }
            }
        }
    }
    
    @AppBackgroundActor
    private func getURL(message: any HistoryMessageProtocol) async -> URL? {
        return await message.makeTempURL()
    }

    func onCopyAction(_ model: ActionModel) {
        UIPasteboard.general.string = model.message.message
    }

    func onDeleteCacheAction(_ model: ActionModel) {
        guard let message = model.message as? Message, let threadVM = model.threadVM else { return }
        model.threadVM?.clearCacheFile(message: message)
        if let uniqueId = message.uniqueId, let indexPath = model.threadVM?.historyVM.sections.indicesByMessageUniqueId(uniqueId) {
            Task.detached {
                try? await Task.sleep(for: .milliseconds(500))
                let newVM = await MessageRowViewModel(message: message, viewModel: threadVM)
                await newVM.recalculate(mainData: newVM.getMainData())
                await threadVM.historyVM.reload(at: IndexPath(row: indexPath.row, section: indexPath.section), vm: newVM)
                if let hashCode = message.fileMetaData?.hashCode {
                    Task { @ChatGlobalActor in
                        try? await ChatManager.activeInstance?.file.cancelResumableDownload(hashCode: hashCode)
                    }
                }
            }
        }
    }
    
    func onReDownload(_ model: ActionModel) {
        guard let message = model.message as? Message, let threadVM = model.threadVM else { return }
        model.threadVM?.clearCacheFile(message: message)
        let viewModel = model.viewModel
        if let uniqueId = message.uniqueId, let indexPath = model.threadVM?.historyVM.sections.indicesByMessageUniqueId(uniqueId) {
            Task.detached {
                try? await Task.sleep(for: .milliseconds(500))
                let newVM = await MessageRowViewModel(message: message, viewModel: threadVM)
                await newVM.recalculate(mainData: newVM.getMainData())
                
                /// Register to download the file again
                await AppState.shared.objectsContainer.downloadsManager.toggleDownloading(message: message)
                
                /// Reload the message row with its new viewModel
                await threadVM.historyVM.reload(at: IndexPath(row: indexPath.row, section: indexPath.section), vm: newVM)
                
                /// Download again
                try? await Task.sleep(for: .microseconds(500))
                await newVM.onTap()
            }
        }
    }
    
    func onPrintDebug(_ model: ActionModel) {
        UIPasteboard.general.string = "\(model.message.id ?? -1)"
        dump(model.message)
    }

    func onDeleteAction(_ model: ActionModel) {
        Task {
            if let threadVM = model.threadVM {
                model.viewModel.calMessage.state.isSelected = true
                model.viewModel.threadVM?.selectedMessagesViewModel.add(model.viewModel)
                let deleteVM = DeleteMessagesViewModelModel()
                await deleteVM.setup(viewModel: threadVM)
                let dialog = DeleteMessageDialog(viewModel: deleteVM)
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
            }
        }
    }

    func onPinAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        let isPinned = model.message.id == model.threadVM?.thread.pinMessage?.id && model.threadVM?.thread.pinMessage != nil
        if !isPinned, let threadVM = model.threadVM {
            let dialog = PinMessageDialog(message: message, threadVM: threadVM)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
        } else {
            model.threadVM?.threadPinMessageViewModel.unpinMessage(model.message.id ?? -1)
        }
    }

    func onSelectAction(_ model: ActionModel) {
        AppState.shared.objectsContainer.navVM.setReplyPrivately(nil)
        model.threadVM?.delegate?.showReplyPrivatelyPlaceholder(show: false)
        model.threadVM?.delegate?.openReplyMode(nil)
        model.threadVM?.sendContainerViewModel.clear() /// Close edit message if set select mode to forward
        model.threadVM?.delegate?.setSelection(true)
        if let uniqueId = model.message.uniqueId,
           let indexPath = model.threadVM?.historyVM.sections.indicesByMessageUniqueId(uniqueId) {
            model.threadVM?.delegate?.setTableRowSelected(indexPath)
        }
        cell?.select()
    }
}
