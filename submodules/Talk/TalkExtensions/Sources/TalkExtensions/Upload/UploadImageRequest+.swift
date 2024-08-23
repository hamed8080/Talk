//
//  UploadImageRequest+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension UploadImageRequest {

    init(imageItem: ImageItem, _ userGroupHash: String?) {
        self = UploadImageRequest(data: imageItem.data,
                           fileExtension: "png",
                           fileName: "\(imageItem.fileName ?? "").png",
                           mimeType: "image/png",
                           userGroupHash: userGroupHash,
                           hC: imageItem.height,
                           wC: imageItem.width
        )
    }
}
