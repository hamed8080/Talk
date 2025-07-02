//
//  DownloadsManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/1/25.
//

import Foundation
import Combine

enum DownloadsManagerError: Error {
    case duplicate
}

@MainActor
public final class DownloadsManager: ObservableObject {
    private var cancellableSet = Set<AnyCancellable>()
    public private(set) var elements: [DownloadManagerElement] = []
    private let stateMediator = DownloadFileStateMediator()
    public init(){}
    
    public func enqueue(element: DownloadManagerElement) throws {
        if elements.contains(where: {$0.viewModel.message.id == element.viewModel.message.id}) { throw DownloadsManagerError.duplicate }
        element.viewModel.objectWillChange.sink { [weak self] in
            Task {
                await self?.stateMediator.onVMSatatechanged(element: element)
                if element.viewModel.state == .completed {
                    self?.onComplete(messageId: element.viewModel.message.id ?? -1)
                }
            }
        }.store(in: &cancellableSet)
        elements.append(element)
        elements.sort(by: {$0.date < $1.date})
    }
    
    private func onComplete(messageId: Int) {
        elements.removeAll(where: {$0.viewModel.message.id == messageId})
        Task {
            await downloadNextElement()
        }
    }
    
    private func downloadNextElement() async {
        guard let element = elements.first else { return }
        element.viewModel.startDownload()
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
    }
    
    /// By resuming just one download another one will be triggered once download is completed.
    public func resumeAll() {
        elements.first?.viewModel.resumeDownload()
    }
}
