//
//  DownloadFileStateMediator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/1/25.
//

import Foundation
import UIKit
import Chat
import TalkModels
import Logger

/// A mediator to prepare the new state for UI, and notify it.
@MainActor
class DownloadFileStateMediator {
    nonisolated(unsafe) public static var emptyImage = UIImage(named: "empty_image")!
    nonisolated(unsafe) public static var mapPlaceholder = UIImage(named: "map_placeholder")!
    
    internal func onVMSatatechanged(element: DownloadManagerElement) async {
        if element.isVideo {
            await onVideoChanged(element)
        } else if element.isImage || element.isMap {
            await onImageChanged(element)
        } else {
            await onFileChanged(element)
        }
    }
    
    private func getNewState(_ element: DownloadManagerElement) -> MessageFileState {
        let vm = element.viewModel
        let progress: CGFloat = CGFloat(vm.downloadPercentValue())
        let state = MessageFileState(
            progress: min(CGFloat(progress) / 100, 1.0),
            showDownload: vm.state != .completed,
            state: vm.state,
            iconState: getIconState(vm: vm),
            blurRadius: vm.state != .completed ? 16 : 0,
            preloadImage: preloadImage(element)
        )
        return state
    }
    
    private func preloadImage(_ element: DownloadManagerElement) -> UIImage? {
        if element.viewModel.state == .completed { return nil }
        return element.isMap ? DownloadFileManager.mapPlaceholder : element.isImage ? DownloadFileManager.emptyImage : nil
    }
    
    private func getIconState(vm: DownloadFileViewModel) -> String {
        if let iconName = vm.message.iconName, vm.state == .completed {
            return iconName
        } else if vm.state == .downloading {
            return "pause.fill"
        } else if vm.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }
    
    private func onVideoChanged(_ element: DownloadManagerElement) async {
        let newState = getNewState(element)
        let msg = element.viewModel.message
        let threadId = element.threaId ?? -1
        await changeStateTo(threadId: threadId, state: newState, messageId: msg.id ?? -1)
    }
    
    private func onImageChanged(_ element: DownloadManagerElement) async {
        guard let messageId = element.viewModel.message.id else { return }
        let newState = getNewState(element)
        let msg = element.viewModel.message
        let threadId = element.threaId ?? -1
        await changeStateTo(threadId: threadId, state: newState, messageId: messageId)
        await updateReplyImagesIfNeeded(element)
    }
    
    private func onFileChanged(_ element: DownloadManagerElement) async {
        let newState = getNewState(element)
        let msg = element.viewModel.message
        let threadId = element.threaId ?? -1
        await changeStateTo(threadId: threadId, state: newState, messageId: msg.id ?? -1)
    }
    
    @AppBackgroundActor
    private func changeStateTo(threadId: Int, state: MessageFileState, messageId: Int) async {
        guard
            let viewModel = await AppState.shared.objectsContainer.navVM.viewModel(for: threadId),
            let result = await viewModel.historyVM.sections.viewModelAndIndexPath(for: messageId)
        else { return }
        let fileURL = await result.vm.message.fileURL
        await MainActor.run {
            /// We have to check if the state is not completed yet,
            /// cuase if is was finished it will turn an downloaded image
            /// to blur view if we are getting the reply thumbnail
            if result.vm.fileState.state != .completed {
                result.vm.setFileState(state, fileURL: fileURL)
            }
            let delegate = viewModel.delegate
            if state.state == .completed {
                delegate?.downloadCompleted(at: result.indexPath, viewModel: result.vm)
            } else if state.state == .thumbnail {
                delegate?.updateThumbnail(at: result.indexPath, viewModel: result.vm)
            } else {
                delegate?.updateProgress(at: result.indexPath, viewModel: result.vm)
            }
        }
    }
    
    private func updateReplyImagesIfNeeded(_ element: DownloadManagerElement) async {
        guard
            element.viewModel.state == .completed,
            element.isMap || element.isImage,
            let url = element.viewModel.fileURL,
            let scaledImage = url.imageScale(width: 48)?.image,
            let threadId = element.threaId,
            let threadVM = AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
        else { return }
        
        let vms = threadVM.historyVM.sections
            .flatMap({$0.vms})
            .filter({$0.message.replyInfo?.id == element.viewModel.message.id})
        for vm in vms {
            await vm.setRelyImage(image: UIImage(cgImage: scaledImage))
            if let indexPath = await threadVM.historyVM.indexPath(vm: vm) {
                await threadVM.delegate?.updateReplyImageThumbnail(at: indexPath, viewModel: vm)
            }
        }
    }

    private func log(_ string: String) {
        Logger.log(title: "DownloadFileStateMediator", message: string)
    }
}
