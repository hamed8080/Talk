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
public struct UploadManagerElement: @preconcurrency Identifiable {
    public var id: String { viewModel.uploadUniqueId ?? "" }
    
    public let viewModel: UploadFileViewModel
    public let date = Date()
    public var isInQueue = true
    
    public init(message: HistoryMessageType) async {
        let viewModel = await UploadFileViewModel(message: message)
        self.viewModel = viewModel
    }
    
    public var threadId: Int? { viewModel.message.threadId ?? viewModel.message.conversation?.id }
}
