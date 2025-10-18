//
//  UploadFileMessage+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension UploadFileMessage {

    convenience init(videoItem: ImageItem, model: SendMessageModel) {
        let uploadRequest = UploadFileRequest(videoItem: videoItem, model.userGroupHash)
        let textRequest = SendTextMessageRequest(threadId: model.threadId,
                                                 textMessage: model.textMessage,
                                                 messageType: .podSpaceVideo)
        self.init(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: model.conversation)
        id = -(model.uploadFileIndex ?? 1)
    }

    convenience init(dropItem: DropItem, model: SendMessageModel) {
        let textMessage = model.textMessage
        let uploadRequest = UploadFileRequest(dropItem: dropItem, model.userGroupHash)
        let textRequest = textMessage.isEmpty == true ? nil : SendTextMessageRequest(threadId: model.threadId,
                                                                                     textMessage: textMessage,
                                                                                     messageType: .podSpaceFile)
        self.init(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: model.conversation)
        id = -(model.uploadFileIndex ?? 1)
        ownerId = model.meId
        conversation = model.conversation
    }
}

/// Image
public extension UploadFileMessage {
    convenience init(imageItem: ImageItem, model: SendMessageModel, isReplyRequest: Bool = false, isReplyPrivatelyRequest: Bool = false) {
        let uploadRequest = UploadImageRequest(imageItem: imageItem, model.userGroupHash)
        let textRequest = SendTextMessageRequest(threadId: model.threadId,
                                                 textMessage: model.textMessage,
                                                 messageType: .podSpacePicture)
        
        var replyRequest: ReplyMessageRequest?
        if isReplyRequest {
            replyRequest = ReplyMessageRequest(threadId: model.threadId,
                                                  repliedTo: model.replyMessage?.id ?? -1,
                                                  textMessage: model.textMessage,
                                                  messageType: .podSpacePicture
            )
        }
        
        var replyPrivatelyRequest: ReplyPrivatelyRequest?
        if isReplyPrivatelyRequest {
            replyPrivatelyRequest = ReplyPrivatelyRequest(model: model)
        }
        
        self.init(imageFileRequest: uploadRequest, sendTextMessageRequest: textRequest, replyRequest: replyRequest, replyPrivatelyRequest: replyPrivatelyRequest, thread: model.conversation)
        id = -(model.uploadFileIndex ?? 1)
        messageType = .podSpacePicture
        ownerId = model.meId
        conversation = model.conversation
        if isReplyPrivatelyRequest, let uniqueId = uniqueId {
            self.replyPrivatelyRequest?.uniqueId = uniqueId
            self.replyPrivatelyRequest?.messageType = .podSpacePicture
        }
    }
}

/// File
public extension UploadFileMessage {
    convenience init?(url: URL, isLastItem: Bool = false, model: SendMessageModel, isReplyRequest: Bool = false, isReplyPrivatelyRequest: Bool = false) {
        let textMessage = model.textMessage
        guard let uploadRequest = UploadFileRequest(url: url, model.userGroupHash) else { return nil }
        var textRequest: SendTextMessageRequest? = nil
        let isMusic = url.isMusicMimetype
        let newMessageType = isMusic ? ChatModels.MessageType.podSpaceSound : .podSpaceFile
        if isLastItem {
            textRequest = SendTextMessageRequest(threadId: model.threadId, textMessage: textMessage, messageType: newMessageType)
        }
        
        self.init(uploadFileRequest: uploadRequest,
                  sendTextMessageRequest: textRequest,
                  replyRequest: isReplyRequest ? ReplyMessageRequest(threadId: model.threadId,
                                                                     repliedTo: model.replyMessage?.id ?? -1,
                                                                     textMessage: textMessage,
                                                                     messageType: newMessageType) : nil,
                  replyPrivatelyRequest: isReplyPrivatelyRequest ? ReplyPrivatelyRequest(model: model) : nil,
                  thread: model.conversation)
        id = -(model.uploadFileIndex ?? 1)
        messageType = newMessageType
        ownerId = model.meId
        conversation = model.conversation
        
        if isReplyPrivatelyRequest, let uniqueId = uniqueId {
            self.replyPrivatelyRequest?.uniqueId = uniqueId
            self.replyPrivatelyRequest?.messageType = newMessageType
        }
    }
}

/// Voice message
public extension UploadFileMessage {
    convenience init?(audioFileURL: URL?, model: SendMessageModel, isReplyRequest: Bool = false, isReplyPrivatelyRequest: Bool = false) {
        guard let audioFileURL = audioFileURL, let uploadRequest = UploadFileRequest(audioFileURL: audioFileURL, model.userGroupHash) else { return nil }
        let textRequest = SendTextMessageRequest(threadId: model.threadId,
                                                 textMessage: "",
                                                 messageType: .podSpaceVoice)
        
        
        
        let replyPrivatelyRequest = ReplyPrivatelyRequest(model: model)
        self.init(uploadFileRequest: uploadRequest,
                  sendTextMessageRequest: textRequest,
                  replyRequest: isReplyRequest ? ReplyMessageRequest(threadId: model.threadId,
                                                                     repliedTo: model.replyMessage?.id ?? -1,
                                                                     textMessage: "",
                                                                     messageType: .podSpaceVoice) : nil,
                  replyPrivatelyRequest: isReplyPrivatelyRequest ? replyPrivatelyRequest : nil,
                  thread: model.conversation)
                
        messageType = .podSpaceVoice
        ownerId = model.meId
        conversation = model.conversation
        if isReplyPrivatelyRequest, let uniqueId = uniqueId {
            self.replyPrivatelyRequest?.uniqueId = uniqueId
            self.replyPrivatelyRequest?.messageType = .podSpaceVoice
        }
    }
}

/// Location message
public extension UploadFileMessage {
    convenience init(location: LocationItem, model: SendMessageModel ) {
        let textMessage = model.textMessage
        var textRequest: SendTextMessageRequest? = nil
        let locationRequest = LocationMessageRequest(item: location, model: model)
    
        self.init(uploadFileRequest: nil,
                  sendTextMessageRequest: textRequest,
                  replyRequest: nil,
                  replyPrivatelyRequest: nil,
                  locationRequest: locationRequest,
                  thread: model.conversation)
        uniqueId = locationRequest.uniqueId
        id = -(model.uploadFileIndex ?? 1)
        messageType = .podSpacePicture
        ownerId = model.meId
        conversation = model.conversation
    }
}
