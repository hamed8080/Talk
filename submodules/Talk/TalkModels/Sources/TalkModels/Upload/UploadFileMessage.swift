import Foundation
import Chat

public class UploadFileMessage: HistoryMessageBaseCalss, UploadProtocol {
    public var sendTextMessageRequest: SendTextMessageRequest?
    public var uploadFileRequest: UploadFileRequest?
    public var uploadImageRequest: UploadImageRequest?

    public init(uploadFileRequest: UploadFileRequest, sendTextMessageRequest: SendTextMessageRequest? = nil, thread: Conversation?) {
        self.sendTextMessageRequest = sendTextMessageRequest
        self.uploadFileRequest = uploadFileRequest
        if let sendTextMessageRequest = sendTextMessageRequest {
            self.sendTextMessageRequest = sendTextMessageRequest
            self.uploadFileRequest = uploadFileRequest
        }
        let message = Message(
            threadId: sendTextMessageRequest?.threadId,
            message: sendTextMessageRequest?.textMessage,
            messageType: sendTextMessageRequest?.messageType,
            metadata: sendTextMessageRequest?.metadata,
            systemMetadata: sendTextMessageRequest?.systemMetadata,
            time: UInt(Date().millisecondsSince1970), 
            uniqueId: uploadFileRequest.uniqueId,
            conversation: thread
        )
        super.init(message: message)
    }

    public init(imageFileRequest: UploadImageRequest, sendTextMessageRequest: SendTextMessageRequest? = nil, thread: Conversation?) {
        self.sendTextMessageRequest = sendTextMessageRequest
        self.uploadImageRequest = imageFileRequest
        let message = Message(
            threadId: sendTextMessageRequest?.threadId,
            message: sendTextMessageRequest?.textMessage,
            messageType: sendTextMessageRequest?.messageType,
            metadata: sendTextMessageRequest?.metadata,
            systemMetadata: sendTextMessageRequest?.systemMetadata,
            time: UInt(Date().millisecondsSince1970),
            uniqueId: imageFileRequest.uniqueId,
            conversation: thread
        )
        super.init(message: message)
    }

    public init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
