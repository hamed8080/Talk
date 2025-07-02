//
//  UploadFileManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import Chat
import TalkModels
import UIKit
import TalkExtensions

@MainActor
public final class UploadFileManager {
    private weak var viewModel: ThreadViewModel?
    private var uploadVMS: [String: UploadFileViewModel] = [:]
    private var cancelableSet: Set<AnyCancellable> = Set()
    private var queue = DispatchQueue(label: "UploadFileManagerSerialQueue")
    
    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    private func viewModel(for viewModelUniqueId: String) -> UploadFileViewModel? {
        queue.sync {
            uploadVMS.first(where: {$0.key == viewModelUniqueId})?.value
        }
    }

    public func register(message: HistoryMessageType, viewModelUniqueId: String) {
        queue.sync {
            guard uploadVMS[viewModelUniqueId] == nil, message is UploadProtocol else { return }
            let uploadFileVM = UploadFileViewModel(message: message)
            uploadVMS[viewModelUniqueId] = uploadFileVM
            uploadFileVM.objectWillChange.sink { [weak self] in
                Task { await self?.onUploadChanged(uploadFileVM, message, viewModelUniqueId) }
            }.store(in: &cancelableSet)
            uploadFileVM.startUpload()
        }
    }

    private func unRegister(viewModelUniqueId: String) {
        queue.sync { uploadVMS.removeValue(forKey: viewModelUniqueId) }
    }

    public func cancel(viewModelUniqueId: String) async {
        guard let vm = viewModel(for: viewModelUniqueId) else { return }
        if let indexPath = viewModel?.historyVM.sections.viewModelAndIndexPath(viewModelUniqueId: viewModelUniqueId)?.indexPath {
            await viewModel?.historyVM.deleteIndices([indexPath])
        }
        vm.action(.cancel)
        unRegister(viewModelUniqueId: viewModelUniqueId)
    }

    private func getIconState(vm: UploadFileViewModel) -> String {
        switch vm.state {
        case .completed: vm.message.iconName?.replacingOccurrences(of: ".circle", with: "") ?? "arrow.down"
        case .uploading: "xmark"
        case .paused: "play.fill"
        default: "arrow.up"
        }
    }

    private func onUploadChanged(_ vm: UploadFileViewModel, _ message: HistoryMessageType, _ viewModelUniqueId: String) async {
        let state = MessageFileState.init(
            progress: min(CGFloat(vm.uploadPercent) / 100, 1.0),
            isUploading: vm.state == .uploading,
            state: vm.state == .completed ? .completed : .undefined,
            iconState: getIconState(vm: vm),
            blurRadius: message.isImage && vm.state != .completed ? 16 : 0,
            preloadImage: (message as? UploadFileMessage)?.uploadImageRequest?.dataToSend.flatMap(UIImage.init)
        )
        await changeStateTo(state: state, metaData: vm.fileMetaData, viewModelUniqueId: viewModelUniqueId)
    }

    private func changeStateTo(state: MessageFileState, metaData: FileMetaData?, viewModelUniqueId: String) async {
        if let (vm, indexPath) = await viewModel?.historyVM.sections.viewModelAndIndexPath(viewModelUniqueId: viewModelUniqueId) {
            vm.message.metadata = metaData?.jsonString
            let fileURL = await vm.message.fileURL
            await MainActor.run {
                vm.setFileState(state, fileURL: fileURL)
                state.state == .completed ?
                viewModel?.delegate?.uploadCompleted(at: indexPath, viewModel: vm) :
                viewModel?.delegate?.updateProgress(at: indexPath, viewModel: vm)
            }
        }
        if state.state == .completed {
            await unRegister(viewModelUniqueId: viewModelUniqueId)
        }
    }
}
