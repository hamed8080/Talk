//
//  UploadImageRequest+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension UploadFileMessage {

    convenience init(videoItem: ImageItem, videoModel: SendMessageModel) {
        let uploadRequest = UploadFileRequest(videoItem: videoItem, videoModel.userGroupHash)
        let textRequest = SendTextMessageRequest(threadId: videoModel.threadId,
                                                 textMessage: videoModel.textMessage,
                                                 messageType: .podSpaceVideo)
        self.init(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: videoModel.conversation)
        id = -(videoModel.uploadFileIndex ?? 1)
    }

    convenience init(imageItem: ImageItem, imageModel: SendMessageModel) {
        let uploadRequest = UploadImageRequest(imageItem: imageItem, imageModel.userGroupHash)
        let textRequest = SendTextMessageRequest(threadId: imageModel.threadId,
                                                 textMessage: imageModel.textMessage,
                                                 messageType: .podSpacePicture)
        self.init(imageFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: imageModel.conversation)
        id = -(imageModel.uploadFileIndex ?? 1)
        ownerId = imageModel.meId
        conversation = imageModel.conversation
    }

    convenience init(dropItem: DropItem, dropModel: SendMessageModel) {
        let textMessage = dropModel.textMessage
        let uploadRequest = UploadFileRequest(dropItem: dropItem, dropModel.userGroupHash)
        let textRequest = textMessage.isEmpty == true ? nil : SendTextMessageRequest(threadId: dropModel.threadId,
                                                                                     textMessage: textMessage,
                                                                                     messageType: .podSpaceFile)
        self.init(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: dropModel.conversation)
        id = -(dropModel.uploadFileIndex ?? 1)
        ownerId = dropModel.meId
        conversation = dropModel.conversation
    }

    convenience init?(urlItem: URL, isLastItem: Bool, urlModel: SendMessageModel) {
        let textMessage = urlModel.textMessage
        guard let uploadRequest = UploadFileRequest(url: urlItem, urlModel.userGroupHash) else { return nil }
        var textRequest: SendTextMessageRequest? = nil
        let isMusic = urlItem.isMusicMimetype
        let newMessageType = isMusic ? ChatModels.MessageType.podSpaceSound : .podSpaceFile
        if isLastItem {
            textRequest = SendTextMessageRequest(threadId: urlModel.threadId, textMessage: textMessage, messageType: newMessageType)
        }
        self.init(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: urlModel.conversation)
        id = -(urlModel.uploadFileIndex ?? 1)
        messageType = newMessageType
        ownerId = urlModel.meId
        conversation = urlModel.conversation
    }

    convenience init?(audioFileURL: URL?, model: SendMessageModel) {
        guard let audioFileURL = audioFileURL, let uploadRequest = UploadFileRequest(audioFileURL: audioFileURL, model.userGroupHash) else { return nil }
        let textRequest = SendTextMessageRequest(threadId: model.threadId,
                                                 textMessage: "",
                                                 messageType: .podSpaceVoice)
        self.init(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: model.conversation)
        messageType = .podSpaceVoice
        ownerId = model.meId
        conversation = model.conversation
    }
    
    convenience init?(audioFileURL: URL?, model: SendMessageModel, isReplyRequest: Bool) {
        guard let audioFileURL = audioFileURL, let uploadRequest = UploadFileRequest(audioFileURL: audioFileURL, model.userGroupHash) else { return nil }
        let replyRequest = ReplyMessageRequest(threadId: model.threadId,
                                              repliedTo: model.replyMessage?.id ?? -1,
                                              textMessage: "",
                                              messageType: .podSpaceVoice
        )
        self.init(uploadFileRequest: uploadRequest, replyRequest: replyRequest, thread: model.conversation)
        messageType = .podSpaceVoice
        ownerId = model.meId
        conversation = model.conversation
    }
    
    convenience init(imageItem: ImageItem, model: SendMessageModel, isReplyRequest: Bool) {
        let imageRequest = UploadImageRequest(imageItem: imageItem, model.userGroupHash)
        let replyRequest = ReplyMessageRequest(threadId: model.threadId,
                                              repliedTo: model.replyMessage?.id ?? -1,
                                              textMessage: "",
                                              messageType: .podSpacePicture
        )
        self.init(imageFileRequest: imageRequest, replyRequest: replyRequest, thread: model.conversation)
        messageType = .podSpacePicture
        ownerId = model.meId
        conversation = model.conversation
    }
    
    convenience init?(urlItem: URL, urlModel: SendMessageModel, isReplyRequest: Bool) {
        let textMessage = urlModel.textMessage
        guard let uploadRequest = UploadFileRequest(url: urlItem, urlModel.userGroupHash) else { return nil }
        var replyRequest: ReplyMessageRequest? = nil
        let isMusic = urlItem.isMusicMimetype
        let newMessageType = isMusic ? ChatModels.MessageType.podSpaceSound : .podSpaceFile
        replyRequest = ReplyMessageRequest(threadId: urlModel.threadId, repliedTo: urlModel.replyMessage?.id ?? -1, textMessage: textMessage, messageType: newMessageType)
        self.init(uploadFileRequest: uploadRequest, sendTextMessageRequest: nil, replyRequest: replyRequest, thread: urlModel.conversation)
        id = -(urlModel.uploadFileIndex ?? 1)
        messageType = newMessageType
        ownerId = urlModel.meId
        conversation = urlModel.conversation
    }
}
