//
//  UploadManagerElement.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/1/25.
//

import Foundation
import Chat
import TalkModels

@MainActor
public struct UploadManagerElement: Identifiable {
    public nonisolated var id: String
    
    public let viewModel: UploadFileViewModel
    public let date = Date()
    public var isInQueue = true
    
    public init(message: HistoryMessageType) async {
        let viewModel = await UploadFileViewModel(message: message)
        self.id = viewModel.uploadUniqueId ?? ""
        self.viewModel = viewModel
    }
    
    public var threadId: Int? { viewModel.message.threadId ?? viewModel.message.conversation?.id }
}

extension UploadManagerElement: @preconcurrency CustomDebugStringConvertible {
    @MainActor
    public var debugDescription: String {
        return
"""
{
    id: \(id),
    date: \(date.millisecondsSince1970),
    isInQueue: \(isInQueue),
    threadId: \(threadId ?? -1),
    percent: \(viewModel.uploadPercent),
    fileName: \(viewModel.fileNameString),
    fileSize: \(viewModel.fileSizeString)
}
"""
    }
}
