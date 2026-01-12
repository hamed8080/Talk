//
//  MessageFilePathOnDiskCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import Chat
import TalkModels
import UIKit

public final class MessageFilePathOnDiskCalculator {
    private let message: HistoryMessageType
    
    public init(message: HistoryMessageType) {
        self.message = message
    }

    @ChatGlobalActor
    public func getFileURL() async -> URL? {
        if let url = await message.url {
            return await getFileURLOnDisk(url: url)
        }
        return nil
    }
    
    @ChatGlobalActor
    private func getFileURLOnDisk(url: URL) -> URL? {
        if ChatManager.activeInstance?.file.isFileExist(url) == false { return nil }
        let fileURL = ChatManager.activeInstance?.file.filePath(url)
        return fileURL
    }
}
