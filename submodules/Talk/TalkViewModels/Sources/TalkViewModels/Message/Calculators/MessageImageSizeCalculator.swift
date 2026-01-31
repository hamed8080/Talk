//
//  MessageImageSizeCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit
import Chat
import TalkModels

public final class MessageImageSizeCalculator {
    private let message: HistoryMessageType
    private let fileMetaData: FileMetaData?
    private let isImage: Bool
    
    public init(message: HistoryMessageType, fileMetaData: FileMetaData?, isImage: Bool) {
        self.message = message
        self.fileMetaData = fileMetaData
        self.isImage = isImage
    }
    
    func imageSize() -> CGSize? {
        if isImage {
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let uploadMapSizeWidth = message is UploadFileMessage ? DownloadFileStateMediator.emptyImage.size.width : nil
            let uploadMapSizeHeight = message is UploadFileMessage ? DownloadFileStateMediator.emptyImage.size.height : nil
            let uploadImageReq = (message as? UploadFileMessage)?.uploadImageRequest
            let imageWidth = CGFloat(fileMetaData?.file?.actualWidth ?? uploadImageReq?.wC ?? Int(uploadMapSizeWidth ?? 0))
            let maxWidth = ThreadViewModel.maxAllowedWidth
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageHeight = CGFloat(fileMetaData?.file?.actualHeight ?? uploadImageReq?.hC ?? Int(uploadMapSizeHeight ?? 0))
            let originalWidth: CGFloat = imageWidth
            let originalHeight: CGFloat = imageHeight
            var designerWidth: CGFloat = maxWidth
            var designerHeight: CGFloat = maxWidth
            let originalRatio: CGFloat = max(0, originalWidth / originalHeight) // To escape nan 0/0 is equal to nan
            let designRatio: CGFloat = max(0, designerWidth / designerHeight) // To escape nan 0/0 is equal to nan
            if originalRatio > designRatio {
                designerHeight = max(0, designerWidth / originalRatio) // To escape nan 0/0 is equal to nan
            } else {
                designerWidth = designerHeight * originalRatio
            }
            let isSquare = originalRatio >= 1 && originalRatio <= 1.5
            var newSizes = CGSize(width: 0, height: 0)
            let hasText = message.message?.count ?? 0 > 1
            
            if originalWidth < designerWidth && originalHeight < designerHeight && !hasText {
                let leadingMargin: CGFloat = 4
                let trailingMargin: CGFloat = 4
                let minWidth: CGFloat = 128 // 96 to draw image downloading label and progress button over image view
                newSizes.width = max(leadingMargin + minWidth + trailingMargin, originalWidth)
                newSizes.height = originalHeight
            } else if hasText {
                newSizes.width = maxWidth
                newSizes.height = maxWidth
            } else if isSquare {
                newSizes.width = designerWidth
                newSizes.height = designerHeight
            } else {
                newSizes.width = min(designerWidth * 1.5, maxWidth)
                newSizes.height = min(designerHeight * 1.5, maxWidth)
            }
            
            // We do this because if we got NAN as a result of 0 / 0 we have to prepare a value other than zero
            // Because in maxWidth we can not say maxWidth is Equal zero and minWidth is equal 128
            if newSizes.width == 0 {
                newSizes.width = ThreadViewModel.maxAllowedWidth
            }
            let minWidth: CGFloat = 148 - 8 // It will prevent cutting progressView as much as possible.
            if newSizes.width < minWidth {
                newSizes.width = minWidth
            }
            
            if newSizes.height <= 48 {
                newSizes.height = 48
            }
            return newSizes
        }
        return nil
    }
}
