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
            let isInQueue = uploadVMS.contains(where: {$0.key == viewModelUniqueId})
            let isFileOrMap = message is UploadProtocol
            let canUpload = isFileOrMap && !isInQueue
            if canUpload {
                let uploadFileVM = UploadFileViewModel(message: message)

                uploadVMS[viewModelUniqueId] = uploadFileVM
                uploadFileVM.objectWillChange.sink { [weak self] in
                    Task { [weak self] in
                        await self?.onUploadChanged(uploadFileVM, message, viewModelUniqueId: viewModelUniqueId)
                    }
                }
                .store(in: &cancelableSet)
                if message.isImage || message is UploadFileWithLocationMessage {
                    uploadFileVM.startUploadImage()
                } else {
                    uploadFileVM.startUploadFile()
                }
            }
        }
    }

    private func unRegister(viewModelUniqueId: String) {
        queue.sync {
            // $0.message.id == nil in uploading locaiton is nil
            if uploadVMS.contains(where: {$0.key == viewModelUniqueId}) {
                uploadVMS.removeValue(forKey: viewModelUniqueId)
            }
        }
    }

    public func cancel(viewModelUniqueId: String) async {
        if let vm = uploadVMS.first(where: {$0.key == viewModelUniqueId})?.value {
            if let indexPath = viewModel?.historyVM.mSections.viewModelAndIndexPath(viewModelUniqueId: viewModelUniqueId)?.indexPath {
                viewModel?.historyVM.mSections[indexPath.section].vms.remove(at: indexPath.row)
                viewModel?.delegate?.removed(at: indexPath)
            }
            vm.cancelUpload()
            unRegister(viewModelUniqueId: viewModelUniqueId)
        }
    }

    private func getIconState(vm: UploadFileViewModel) -> String {
        if vm.state == .uploading {
            return "xmark"
        } else if vm.state == .paused {
            return "play.fill"
        } else if vm.state == .completed {
            return vm.message.iconName?.replacingOccurrences(of: ".circle", with: "") ?? "arrow.down"
        } else {
            return "arrow.up"
        }
    }

    private func onUploadChanged(_ vm: UploadFileViewModel, _ message: HistoryMessageType, viewModelUniqueId: String) async {
        let isCompleted = vm.state == .completed
        let isUploading = vm.state == .uploading
        let progress = min(CGFloat(vm.uploadPercent) / 100, 1.0)
        let iconState = getIconState(vm: vm)
        var preloadImage: UIImage?
        var blurRadius: CGFloat = 0
        if let data = (message as? UploadFileMessage)?.uploadImageRequest?.dataToSend, let uiimage = UIImage(data: data) {
            preloadImage = uiimage
        }

        if message.isImage, !isCompleted {
            blurRadius = 16
        }
        let fileState = MessageFileState.init(progress: progress,
                                              isUploading: isUploading,
                                              state: isCompleted ? .completed : .undefined,
                                              iconState: iconState,
                                              blurRadius: blurRadius,
                                              preloadImage: preloadImage
        )
        await changeStateTo(state: fileState, metaData: vm.fileMetaData, viewModelUniqueId: viewModelUniqueId)
    }

    @HistoryActor
    private func changeStateTo(state: MessageFileState, metaData: FileMetaData?, viewModelUniqueId: String) async {
        let tuple = await viewModel?.historyVM.mSections.viewModelAndIndexPath(viewModelUniqueId: viewModelUniqueId)
        tuple?.vm.message.metadata = metaData?.jsonString
        let fileURL = await tuple?.vm.message.fileURL
        await MainActor.run {
            guard let tuple = tuple else { return }
            tuple.vm.setFileState(state, fileURL: fileURL)
            if state.state == .completed {
                viewModel?.delegate?.uploadCompleted(at: tuple.indexPath, viewModel: tuple.vm)
            } else {
                viewModel?.delegate?.updateProgress(at: tuple.indexPath, viewModel: tuple.vm)
            }
        }
        if state.state == .completed {
            await unRegister(viewModelUniqueId: viewModelUniqueId)
        }
    }
}
