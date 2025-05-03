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
            
            if threadVM?.thread.group == true, !viewModel.calMessage.isMe {
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
                self?.onSaveVideoAction(model)
                onMenuClickedDismiss()
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
        AppState.shared.appStateNavigationModel.replyPrivately = message
        AppState.shared.openThread(participant: participant)
    }

    func onForwardAction(_ model: ActionModel) {
        model.threadVM?.sendContainerViewModel.clear() /// Close edit message if set select mode to forward
        model.threadVM?.delegate?.setSelection(true)
        if let uniqueId = model.message.uniqueId,
           let indexPath = model.threadVM?.historyVM.sectionsHolder.sections.indicesByMessageUniqueId(uniqueId) {
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
        let value = MessageParticipantsSeenNavigationValue(message: message, threadVM: model.threadVM!)
        AppState.shared.objectsContainer.navVM.append(value: value)
    }

    func onSaveAction(_ model: ActionModel) {
        Task {
            if let url = await model.viewModel.message.fileURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(image, model.viewModel, nil, nil)
                let icon = Image(systemName: "externaldrive.badge.checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.App.white)
                AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.imageSaved", messageColor: Color.App.textPrimary)
            }
        }
    }

    func onSaveVideoAction(_ model: ActionModel) {
        let message = model.viewModel.message
        Task { @AppBackgroundActor in
            guard let url = await message.makeTempURL() else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                if saved {
                    Task {
                        try? FileManager.default.removeItem(at: url)
                        await MainActor.run {
                            let icon = Image(systemName: "externaldrive.badge.checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.App.white)
                            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.videoSaved", messageColor: Color.App.textPrimary)
                        }
                    }
                }
            }
        }
    }

    func onCopyAction(_ model: ActionModel) {
        UIPasteboard.general.string = model.message.message
    }

    func onDeleteCacheAction(_ model: ActionModel) {
        guard let message = model.message as? Message, let threadVM = model.threadVM else { return }
        model.threadVM?.clearCacheFile(message: message)
        if let uniqueId = message.uniqueId, let indexPath = model.threadVM?.historyVM.sectionsHolder.sections.indicesByMessageUniqueId(uniqueId) {
            Task.detached {
                try? await Task.sleep(for: .milliseconds(500))
                let newVM = MessageRowViewModel(message: message, viewModel: threadVM)
                await newVM.recalculate(mainData: newVM.getMainData())
                await threadVM.historyVM.sectionsHolder.reload(at: IndexPath(row: indexPath.row, section: indexPath.section), vm: newVM)
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
        model.threadVM?.delegate?.openReplyMode(nil)
        model.threadVM?.sendContainerViewModel.clear() /// Close edit message if set select mode to forward
        model.threadVM?.delegate?.setSelection(true)
        if let uniqueId = model.message.uniqueId,
           let indexPath = model.threadVM?.historyVM.sectionsHolder.sections.indicesByMessageUniqueId(uniqueId) {
            model.threadVM?.delegate?.setTableRowSelected(indexPath)
        }
        cell?.select()
    }
}
