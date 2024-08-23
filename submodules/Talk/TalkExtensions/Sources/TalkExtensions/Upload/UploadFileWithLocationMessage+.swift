//
//  UploadFileWithLocationMessage+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension UploadFileWithLocationMessage {
    convenience init(message: Message, location: LocationItem, model: SendMessageModel) {
        let req = LocationMessageRequest(item: location, model: model)
        self.init(locationRequest: req, message: message)
        self.uniqueId = req.uniqueId
        self.messageType = .podSpacePicture
        self.threadId = model.threadId
        self.conversation = model.conversation
        self.time = UInt(Date().millisecondsSince1970)
        self.ownerId = model.meId
    }
}
