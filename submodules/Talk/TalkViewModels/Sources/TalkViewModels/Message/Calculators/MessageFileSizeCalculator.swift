//
//  MessageFileSizeCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit
import Chat
import TalkModels

public final class MessageFileSizeCalculator {
    private let message: HistoryMessageType
    private let fileMetaData: FileMetaData?
    
    public init(message: HistoryMessageType, fileMetaData: FileMetaData?) {
        self.message = message
        self.fileMetaData = fileMetaData
    }
    
    func calculate() -> String? {
        let normal = message as? UploadFileMessage
        let fileReq = normal?.uploadFileRequest
        let imageReq = normal?.uploadImageRequest
        let size = fileSizeOfURL(fileReq?.filePath) ?? fileReq?.data.count ?? imageReq?.data.count ?? 0
        let uploadFileSize: Int64 = Int64(size)
        let realServerFileSize = fileMetaData?.file?.size
        let fileSize = (realServerFileSize ?? uploadFileSize).toSizeStringShort(locale: Language.preferredLocale)?.replacingOccurrences(of: "٫", with: ".")
        return fileSize
    }
    
    func fileSizeOfURL(_ fileURL: URL?) -> Int? {
        guard let fileURL = fileURL else { return nil }
        let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        return fileSize
    }
}
