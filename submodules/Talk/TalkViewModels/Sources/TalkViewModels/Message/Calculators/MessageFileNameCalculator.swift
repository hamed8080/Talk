//
//  MessageFileNameCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit
import Chat
import TalkModels

public final class MessageFileNameCalculator {
    private let message: HistoryMessageType
    private let fileMetaData: FileMetaData?
    
    public init(message: HistoryMessageType, fileMetaData: FileMetaData?) {
        self.message = message
        self.fileMetaData = fileMetaData
    }
    
    func calculateFileName() -> String? {
        let fileName = fileMetaData?.file?.name
        if fileName == "" || fileName == "blob", let originalName = fileMetaData?.file?.originalName {
            return originalName
        }
        return fileName ?? message.uploadFileName()?.replacingOccurrences(of: ".\(message.uploadExt() ?? "")", with: "")
    }
}
