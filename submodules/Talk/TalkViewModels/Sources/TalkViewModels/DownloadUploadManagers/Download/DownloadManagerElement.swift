//
//  DownloadManagerElement.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/1/25.
//

import Foundation
import Chat

@MainActor
public struct DownloadManagerElement: @preconcurrency Identifiable {
    public var id: Int {viewModel.message.id ?? -1}
    
    public let viewModel: DownloadFileViewModel
    public let isMap: Bool
    public let isVideo: Bool
    public let isImage: Bool
    public let date = Date()
    public var isInQueue = true
    
    public init(message: Message) async {
        let viewModel = await DownloadFileViewModel(message: message)
        let mtd = await DownloadManagerElement.getMetaData(viewModel.message)
        self.isMap = mtd?.mapLink != nil || mtd?.latitude != nil
        isVideo = message.isVideo
        isImage = message.isImage
        self.viewModel = viewModel
    }
    
    @AppBackgroundActor
    private static func getMetaData(_ message: Message) -> FileMetaData? {
        return message.fileMetaData
    }
    
    public var threaId: Int? { viewModel.message.threadId ?? viewModel.message.conversation?.id }
}
