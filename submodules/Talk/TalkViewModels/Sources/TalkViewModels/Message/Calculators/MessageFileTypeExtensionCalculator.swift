//
//  MessageFileTypeExtensionCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import TalkModels
import ChatModels

public final class MessageFileTypeExtensionCalculator {
    private let message: HistoryMessageType
    private let fileMetaData: FileMetaData?
    
    public init(message: HistoryMessageType, fileMetaData: FileMetaData?) {
        self.message = message
        self.fileMetaData = fileMetaData
    }
    
    func fileTypeString() -> String? {
        let normal = message as? UploadFileMessage
        let fileReq = normal?.uploadFileRequest
        let imageReq = normal?.uploadImageRequest
        
        let uploadFileType = fileReq?.originalName ?? imageReq?.originalName
        let serverFileType = fileMetaData?.file?.originalName
        let split = (serverFileType ?? uploadFileType)?.split(separator: ".")
        let ext = fileMetaData?.file?.extension ?? fileReq?.fileExtension ?? imageReq?.fileExtension
        let lastSplit = String(split?.last ?? "")
        let extensionName = (ext ?? lastSplit)
        return extensionName.isEmpty ? nil : extensionName.uppercased()
    }
}
