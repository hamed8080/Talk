//
//  UploadFileStateMediator.swift
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
public class UploadFileStateMediator {
    
    internal func onVMSatatechanged(element: UploadManagerElement) async {
        await onUploadChanged(element)
    }
    
    private func getIconState(vm: UploadFileViewModel) -> String {
        switch vm.state {
        case .completed: vm.message.iconName ?? "arrow.up"
        case .uploading: "xmark"
        case .paused: "play.fill"
        case .error: "exclamationmark.circle"
        default: "arrow.up"
        }
    }
    
    private func onUploadChanged(_ element: UploadManagerElement) async {
        let vm = element.viewModel
        let state = MessageFileState.init(
            progress: min(CGFloat(vm.uploadPercent) / 100, 1.0),
            isUploading: vm.state == .uploading,
            state: vm.state == .completed ? .completed : vm.state == .error ? .error : .undefined,
            iconState: getIconState(vm: vm),
            blurRadius: vm.message.isImage && vm.state != .completed ? 16 : 0,
            preloadImage: (vm.message as? UploadFileMessage)?.uploadImageRequest?.dataToSend.flatMap(UIImage.init)
        )
        vm.message.metadata = state.state == .completed ? vm.fileMetaData?.jsonString : nil
        await changeStateTo(element: element, state: state)
    }
    
    private func changeStateTo(element: UploadManagerElement, state: MessageFileState) async {
        guard let threadVM = viewModel(element) else { return }
        if let (vm, indexPath) = await threadVM.historyVM.sections.viewModelAndIndexPath(uploadElementUniqueId: element.id) {
            let fileURL = await vm.message.fileURL
            vm.setFileState(state, fileURL: fileURL)
            state.state == .completed ?
            threadVM.delegate?.uploadCompleted(at: indexPath, viewModel: vm) :
            threadVM.delegate?.updateProgress(at: indexPath, viewModel: vm)
        }
    }
    
    internal func append(elements: [UploadManagerElement]) async {
        if let element = elements.first, let threadVM = viewModel(element) {
            let historyVM = threadVM.historyVM
            let beforeSectionCount = historyVM.sections.count
            await historyVM.injectUploadsAndSort(elements)
            let tuple = historyVM.sections.indexPathsForUpload(requests: elements.compactMap{$0.viewModel.message}, beforeSectionCount: beforeSectionCount)
            threadVM.delegate?.inserted(tuple.sectionIndex ?? IndexSet(), tuple.indices, nil, nil, true)
            
            // Sleep for better animation when we insert something at the end of the list in upload for multiple items.
            // We have to wait because of the height of the send
            // container to be settled and then it can scroll to the right position
            // after setting the contentInset bottom.
            try? await Task.sleep(for: .seconds(0.5))
            let sectionCount = historyVM.sections.count
            let rowCount = historyVM.sections.last?.vms.count ?? 0
            let indexPath = IndexPath(row: rowCount - 1, section: sectionCount - 1)
            await threadVM.scrollVM.scrollToLastUploadedMessageWith(indexPath)
            
            /// Force to hide move to buttom.
            historyVM.delegate?.showMoveToBottom(show: false)
            
            /// Hide empty thread dialog if it was showing
            await historyVM.showEmptyThread(show: false)
        }
    }
    
    public func removed(_ element: UploadManagerElement) {
        if let threadVM = viewModel(element) {
            let tuple = threadVM.historyVM.sections.viewModelAndIndexPath(uploadElementUniqueId: element.id)
            if let indexPath = tuple?.indexPath {
                threadVM.historyVM.deleteIndices([indexPath])
            }
        }
    }

    private func log(_ string: String) {
        Logger.log(title: "UploadFileStateMediator", message: string)
    }
}

extension UploadFileStateMediator {
    private func viewModel(_ element: UploadManagerElement) -> ThreadViewModel? {
        guard
            let threadId = element.threadId,
            let viewModel = AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
        else { return nil }
        return viewModel
    }
}

extension UploadFileStateMediator {
    func stopSignalForActiveThread(threadId: Int) {
        let activeThread = AppState.shared.objectsContainer.navVM.presentedThreadViewModel
        if !isUploading(threadId: threadId), activeThread?.threadId == threadId {
            activeThread?.viewModel.cancelSignal()
        }
    }
    
    func isUploading(threadId: Int) -> Bool {
        AppState.shared.objectsContainer.uploadsManager.elements.contains(where: {$0.threadId == threadId})
    }
}
