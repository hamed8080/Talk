//
//  UploadFileWithReplyPrivatelyMessage+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension UploadFileWithReplyPrivatelyMessage {
    typealias UploadReplyRequest = UploadFileWithReplyPrivatelyMessage

    class func make(imageItem: ImageItem, model: SendMessageModel) -> UploadReplyRequest? {
        let imageReq = UploadImageRequest(imageItem: imageItem, model.userGroupHash)
        return make(type: .podSpacePicture, model: model, imageReq: imageReq)
    }

    class func make(attachmentFile: AttachmentFile, model: SendMessageModel) -> UploadReplyRequest? {
        guard let url = attachmentFile.request as? URL, let fileReq = UploadFileRequest(url: url, model.userGroupHash) else { return nil }
        return make(type: .podSpaceFile, model: model, fileReq: fileReq)
    }

    class func make(voiceURL: URL?, model: SendMessageModel) -> UploadReplyRequest? {
        guard let url = voiceURL, let fileReq = UploadFileRequest(url: url, model.userGroupHash) else { return nil }
        return make(type: .podSpaceVoice, model: model, fileReq: fileReq)
    }
}

extension UploadFileWithReplyPrivatelyMessage {
    private class func replyPrivatelyMessage(model: SendMessageModel) -> ReplyInfo? {
        let replyMessage = model.replyPrivatelyMessage
        let replyInfo = ReplyInfo(repliedToMessageId: replyMessage?.id,
                                  message: replyMessage?.message,
                                  messageType: replyMessage?.messageType,
                                  metadata: replyMessage?.metadata,
                                  systemMetadata: replyMessage?.systemMetadata,
                                  repliedToMessageNanos: replyMessage?.timeNanos,
                                  repliedToMessageTime: replyMessage?.time,
                                  participant: replyMessage?.participant)
        return replyInfo
    }

    private class func make(type: ChatModels.MessageType,
                            model: SendMessageModel,
                            imageReq: UploadImageRequest? = nil,
                            fileReq: UploadFileRequest? = nil) -> UploadFileWithReplyPrivatelyMessage? {
        guard var req = ReplyPrivatelyRequest(model: model) else { return nil }
        req.uniqueId = imageReq?.uniqueId ?? fileReq?.uniqueId ?? ""
        let replyInfo = replyPrivatelyMessage(model: model)
        var request: UploadFileWithReplyPrivatelyMessage?
        if let imageReq = imageReq {
            request = .init(replyPrivatelyRequest: req, uploadImageRequest: imageReq)
        } else if let fileReq = fileReq {
            request = .init(replyPrivatelyRequest: req, uploadFileRequest: fileReq)
        }
        request?.uniqueId = req.uniqueId
        request?.replyPrivatelyRequest.messageType = type
        request?.replyPrivatelyRequest.uniqueId = req.uniqueId
        request?.id = -(model.uploadFileIndex ?? 1)
        request?.replyInfo = replyInfo
        request?.messageType = type
        request?.ownerId = model.meId
        request?.conversation = model.conversation
        return request
    }
}
