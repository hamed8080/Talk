//
//  DownloadsManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/1/25.
//

import Foundation
import Combine
import Chat

enum DownloadsManagerError: Error {
    case duplicate
}

@MainActor
public final class DownloadsManager: ObservableObject {
    private var cancellableSet = Set<AnyCancellable>()
    @Published public private(set) var elements: [DownloadManagerElement] = []
    private let stateMediator = DownloadFileStateMediator()
    public init(){}
    
    public func enqueue(element: DownloadManagerElement) throws {
        /// Reject if it is already downloaded
        if element.viewModel.isInCache { return } 
        if elements.contains(where: {$0.viewModel.message.id == element.viewModel.message.id}) { throw DownloadsManagerError.duplicate }
        element.viewModel.objectWillChange.sink { [weak self] in
            Task {
                await self?.onDownloadStateChanged(element)
            }
        }.store(in: &cancellableSet)
        elements.append(element)
        elements.sort(by: {$0.date < $1.date})
        
        /// Download the first element if the user tap on the item.
        if elements.count(where: {$0.viewModel.state == .downloading }) == 0 {
            downloadNextElement(element)
        }
    }
    
    private func onDownloadStateChanged(_ element: DownloadManagerElement) async {
        await stateMediator.onVMSatatechanged(element: element)
        if element.viewModel.state == .completed {
            onComplete(messageId: element.viewModel.message.id ?? -1)
        }
    }
    
    private func onComplete(messageId: Int) {
        elements.removeAll(where: {$0.viewModel.message.id == messageId})
        guard var element = elements.first else { return }
        downloadNextElement(element)
    }
    
    private func downloadNextElement(_ element: DownloadManagerElement) {
        if let index = elements.firstIndex(where: {$0.id == element.id}) {
            elements[index].isInQueue = false
        }
        element.viewModel.startDownload()
    }
    
    public func pause(element: DownloadManagerElement) {
        element.viewModel.pauseDownload()
    }
    
    public func resume(element: DownloadManagerElement) {
        element.viewModel.resumeDownload()
    }
    
    public func cancel(element: DownloadManagerElement) {
        element.viewModel.cancelDownload()
        elements.removeAll(where: {$0.viewModel.message.id == element.viewModel.message.id})
    }
    
    public func pauseAll() {
        elements.forEach { element in
            element.viewModel.pauseDownload()
        }
    }
    
    public func cancelAll() {
        elements.forEach { element in
            element.viewModel.cancelDownload()
        }
        elements.removeAll()
    }
    
    /// By resuming just one download another one will be triggered once download is completed.
    public func resumeAll() {
        elements.first?.viewModel.resumeDownload()
    }
    
    public func element(for messageId: Int) -> DownloadManagerElement? {
        return elements.first(where: {$0.viewModel.message.id == messageId})
    }
}

@MainActor
extension DownloadsManager {
    /// Enqueue a download or toggle pause/resume
    /// Notice: It only will toggle only if the message is actively downloading or was pauesd.
    /// So by tapping multiple times on a row it won't start download or pause them
    public func toggleDownloading(message: Message) {
        if let element = element(for: message.id ?? -1), element.viewModel.state != .undefined {
            if element.viewModel.state == .downloading {
                pause(element: element)
            } else if element.viewModel.state == .paused {
                resume(element: element)
            }
        } else {
            Task {
                try? enqueue(element: await .init(message: message))
            }
        }
    }
}
