//
//  UploadsManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/1/25.
//

import Foundation
import Combine
import Chat
import TalkModels

@MainActor
public final class UploadsManager: ObservableObject {
    private var cancellableSet = Set<AnyCancellable>()
    @Published public private(set) var elements: [UploadManagerElement] = []
    public let stateMediator = UploadFileStateMediator()
    public init(){
        registerConnection()
    }
    private let MAX_NUMBER_OF_CONCURRENT_UPLOAD = 1
    
    public func enqueue(element: UploadManagerElement) {
        element.viewModel.objectWillChange.sink { [weak self] in
            Task {
                await self?.onUploadStateChanged(element)
            }
        }.store(in: &cancellableSet)
        elements.append(element)
        elements.sort(by: {$0.date < $1.date})
        
        uploadNextElement()
    }
    
    private func onUploadStateChanged(_ element: UploadManagerElement) async {
        await stateMediator.onVMSatatechanged(element: element)
        if element.viewModel.state == .completed {
            onComplete(messageId: element.viewModel.message.id ?? -1)
        }
    }
    
    private func onComplete(messageId: Int) {
        elements.removeAll(where: {$0.viewModel.message.id == messageId})
        guard var element = elements.first else { return }
        uploadNextElement()
    }
    
    /**
     * Upload the next element if the user didn't try to make it pause.
     * If the model is in pause state, it means that the user doesn’t want to upload it from the time being.
     *
     * This checks the number of uploads to always remain lower or equal than **MAX_NUMBER_OF_CONCURRENT_UPLOAD**.
     */
    private func uploadNextElement() {
        let filtered = elements.filter{ $0.viewModel.state != .paused }
        guard filtered.count(where: {$0.viewModel.state == .uploading }) < MAX_NUMBER_OF_CONCURRENT_UPLOAD else { return }
        let firstUnPausedItem = filtered.first
        if let index = elements.firstIndex(where: {$0.id == firstUnPausedItem?.id}) {
            elements[index].isInQueue = false
        }
        firstUnPausedItem?.viewModel.startUpload()
    }
    
    public func pause(element: UploadManagerElement) {
        element.viewModel.action(.suspend)
        uploadNextElement()
    }
    
    public func resume(element: UploadManagerElement) {
        element.viewModel.action(.resume)
    }
    
    public func cancel(element: UploadManagerElement, userCanceled: Bool) {
        element.viewModel.userCanceled = userCanceled
        element.viewModel.action(.cancel)
        elements.removeAll(where: {$0.viewModel.message.id == element.viewModel.message.id})
        stateMediator.removed(element)
        uploadNextElement()
    }
    
    public func pauseAll() {
        elements.forEach { element in
            element.viewModel.action(.suspend)
        }
    }
    
    public func cancelAll() {
        elements.forEach { element in
            element.viewModel.action(.cancel)
        }
        elements.removeAll()
    }
    
    /// By resuming just one download another one will be triggered once download is completed.
    public func resumeAll() {
        for element in elements.prefix(3) {
            if element.viewModel.state == .error {
                element.viewModel.reUpload()
            } else {
                element.viewModel.action(.resume)
            }
        }
    }
}

@MainActor
extension UploadsManager {
    
    public func enqueue(with uploadMessages: [UploadFileMessage]) {
        Task {
            var elements: [UploadManagerElement] = []
            for message in uploadMessages {
                let element = await UploadManagerElement(message: message)
                enqueue(element: element)
                elements.append(element)
            }
            await stateMediator.append(elements: elements)
        }
    }
    
    public func reupload(element: UploadManagerElement) {
        guard let element = elements.first(where: { $0.viewModel.uploadUniqueId == element.viewModel.uploadUniqueId }) else { return }
        element.viewModel.reUpload()
    }
    
    public func hasAnyUpload(threadId: Int) -> Bool {
        elements.count(where: {$0.threadId == threadId}) > 0
    }
    
    public func lastUploadingMessage(threadId: Int) -> UploadManagerElement? {
        elements.filter({$0.threadId == threadId}).last
    }
    
    public func element(uniqueId: String) -> UploadManagerElement? {
        return elements.first(where: {$0.id == uniqueId})
    }
}

extension UploadsManager {
    private func registerConnection() {
        AppState.shared.$connectionStatus
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onConnectionStatusChanged(event)
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func onConnectionStatusChanged(_ event: ConnectionStatus) {
        if event == .connected {
            let elements = elements.sorted(by: {$0.date < $1.date}).prefix(3)
            elements.forEach { element in
                reupload(element: element)
            }
        } else if event == .disconnected {
            pauseAll()
        }
    }
}
