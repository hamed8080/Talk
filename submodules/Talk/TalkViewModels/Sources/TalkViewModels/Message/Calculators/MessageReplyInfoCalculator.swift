//
//  MessageReplyInfoCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit
import Chat
import TalkModels

public final class MessageReplyInfoCalculator {
    private let message: HistoryMessageType
    private let sizes: ConstantSizes
    private let isReplyImage: Bool
    private let fileName: String?
    private let canShowIconFile: Bool
    private var fileMetadata: FileMetaData? = nil
    private let isImage: Bool
    
    public init(message: HistoryMessageType, sizes: ConstantSizes, calculatedMessage: MessageRowCalculatedData, isImage: Bool) {
        self.message = message
        self.sizes = sizes
        self.fileName = calculatedMessage.fileName
        self.canShowIconFile = calculatedMessage.canShowIconFile
        self.isReplyImage = calculatedMessage.isReplyImage
        self.isImage = isImage
        self.fileMetadata = decodeMetadata()        
    }
    
    public func calculateContainerWidth() -> CGFloat? {
        guard let replyInfo = message.replyInfo else { return nil }
        
        let staticReplyTextWidth = replyStaticTextWidth()
        let text = textForContianerCalculation()
        
        
        let replyWithIconWidth = replyPrimaryMessageFileIconWidth()
        let textWidth = messageContainerTextWidth(text: text, replyWidth: replyWithIconWidth)
        
        let iconWidth = replyIconOrImageWidth()
        let senderNameWidth = replySenderWidthCalculation(replyInfo: replyInfo)
        
        let senderNameWithIconOrImageInReply = replySenderWidthWithIconOrImage(replyInfo: replyInfo, iconWidth: iconWidth, senderNameWidth: senderNameWidth)
        let maxWidthWithSender = max(textWidth + staticReplyTextWidth, senderNameWithIconOrImageInReply + staticReplyTextWidth)
        
        if !isImage, text.count < 60 {
            return maxWidthWithSender
        } else if !isImage, replyInfo.message?.count ?? 0 < text.count {
            let maxAllowedWidth = min(maxWidthWithSender, ThreadViewModel.maxAllowedWidth)
            return maxAllowedWidth
        } else {
            return nil
        }
    }
    
    private func replySenderWidthCalculation(replyInfo: ReplyInfo) -> CGFloat {
        let senderNameText = replyInfo.participant?.contactName ?? replyInfo.participant?.name ?? ""
        let senderFont = UIFont.bold(.caption)
        let senderNameWidth = senderNameText.widthOfString(usingFont: senderFont)
        return senderNameWidth
    }
    
    private func replyStaticTextWidth() -> CGFloat {
        let staticText = "Message.replyTo".bundleLocalized()
        let font = UIFont.bold(.caption)
        let width = staticText.widthOfString(usingFont: font) + 12
        return width
    }
    
    private func replyIconOrImageWidth() -> CGFloat {
        let isReplyImageOrIcon = isReplyImage || canShowIconFile
        return isReplyImageOrIcon ? 32 : 0
    }
    
    private func replySenderWidthWithIconOrImage(replyInfo: ReplyInfo, iconWidth: CGFloat, senderNameWidth: CGFloat) -> CGFloat {
        let space: CGFloat = 1.5 + 32 /// 1.5 bar + 8 for padding + 8 for space between image and leading bar + 8 between image and sender name + 16 for padding
        let senderNameWithImageSize = senderNameWidth + space + iconWidth
        return senderNameWithImageSize
    }
    
    private func messageContainerTextWidth(text: String, replyWidth: CGFloat) -> CGFloat {
        let font = UIFont.normal(.body)
        let textWidth = text.widthOfString(usingFont: font) + replyWidth
        let minimumWidth: CGFloat = 128
        let maxOriginal = max(minimumWidth, textWidth + sizes.paddings.paddingEdgeInset.left + sizes.paddings.paddingEdgeInset.right)
        return maxOriginal
    }
    
    private func replyPrimaryMessageFileIconWidth() -> CGFloat {
        if fileName == nil || fileName?.isEmpty == true { return 0 }
        return 32
    }
    
    private func textForContianerCalculation() -> String {
        let fileNameText = fileName ?? ""
        let messageText = message.message?.prefix(150).replacingOccurrences(of: "\n", with: " ") ?? ""
        let messageFileText = messageText.count > fileNameText.count ? messageText : fileNameText
        return messageFileText
    }

    func calculateIsReplyImage() -> Bool {
        if let replyInfo = message.replyInfo {
            return [ChatModels.MessageType.picture, .podSpacePicture].contains(replyInfo.messageType)
        }
        return false
    }
    
    func replyLink() -> String? {
        return fileMetadata?.file?.link
    }
    
    func replyFileName() -> String? {
        return fileMetadata?.file?.originalName
    }
    
    private func decodeMetadata() -> FileMetaData? {
        guard let data = message.replyInfo?.metadata?.data(using: .utf8) else { return nil }
        let fileMetadata = try? JSONDecoder().decode(FileMetaData.self, from: data)
        return fileMetadata
    }
}
