//
//  UploadFileRequest+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension UploadFileRequest {

    init(videoItem: ImageItem, _ userGroupHash: String? = nil) {        
        self = UploadFileRequest(data: videoItem.data,
                                 fileExtension: "mp4",
                                 fileName: "\(videoItem.fileName ?? "").\(videoItem.fileExt ?? "")",
                                 mimeType: "video/mp4",
                                 userGroupHash: userGroupHash)
    }

    init(dropItem: DropItem, _ userGroupHash: String? = nil) {
        self = UploadFileRequest(data: dropItem.data ?? Data(),
                          fileExtension: "\(dropItem.ext ?? "")",
                          fileName: "\(dropItem.name ?? "").\(dropItem.ext ?? "")", // it should have file name and extension
                          mimeType: nil,
                          userGroupHash: userGroupHash)
    }

    init?(url: URL, _ userGroupHash: String? = nil) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self =  UploadFileRequest(data: data,
                                  fileExtension: "\(url.fileExtension)",
                                  fileName: "\(url.fileName).\(url.fileExtension)", // it should have file name and extension
                                  mimeType: url.mimeType,
                                  originalName: "\(url.fileName).\(url.fileExtension)",
                                  userGroupHash: userGroupHash)
    }

    init?(audioFileURL: URL, _ userGroupHash: String? = nil) {
        guard let data = try? Data(contentsOf: audioFileURL) else { return nil }
        self = UploadFileRequest(data: data,
                          fileExtension: ".\(audioFileURL.fileExtension)",
                          fileName: "\(audioFileURL.fileName).\(audioFileURL.fileExtension)",
                          mimeType: audioFileURL.mimeType,
                          userGroupHash: userGroupHash)
    }
}


