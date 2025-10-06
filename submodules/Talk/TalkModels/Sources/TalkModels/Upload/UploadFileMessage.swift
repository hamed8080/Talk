import Foundation
import Chat

public class UploadFileMessage: HistoryMessageBaseCalss, UploadProtocol {
    public var replyRequest: ReplyMessageRequest?
    public var sendTextMessageRequest: SendTextMessageRequest?
    public var uploadFileRequest: UploadFileRequest?
    public var uploadImageRequest: UploadImageRequest?
    public var replyPrivatelyRequest: ReplyPrivatelyRequest?
    public var locationRequest: LocationMessageRequest?

    public init(uploadFileRequest: UploadFileRequest? = nil,
                imageFileRequest: UploadImageRequest? = nil,
                sendTextMessageRequest: SendTextMessageRequest? = nil,
                replyRequest: ReplyMessageRequest? = nil,
                replyPrivatelyRequest: ReplyPrivatelyRequest? = nil,
                locationRequest: LocationMessageRequest? = nil,
                thread: Conversation?) {
        self.sendTextMessageRequest = sendTextMessageRequest
        self.uploadFileRequest = uploadFileRequest
        self.uploadImageRequest = imageFileRequest
        self.replyRequest = replyRequest
        self.replyPrivatelyRequest = replyPrivatelyRequest
        self.locationRequest = locationRequest
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
            uniqueId: uploadFileRequest?.uniqueId ?? imageFileRequest?.uniqueId,
            conversation: thread
        )
        super.init(message: message)
    }

    public init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

public extension UploadFileMessage {
    var fileSize: Int? {
        let contentSize = uploadFileRequest?.dataToSend?.count ?? uploadImageRequest?.dataToSend?.count
        if contentSize != 0 {
            return contentSize
        } else if let fileSize = uploadFileRequest?.fileSize ?? uploadImageRequest?.fileSize {
            return Int(fileSize)
        }
        return nil
    }
    
    var fileName: String? {
        uploadFileRequest?.fileName ?? uploadImageRequest?.fileName
    }
    
    var uploadRequestUniuqeId: String? {
        uploadFileRequest?.uniqueId ?? uploadImageRequest?.uniqueId ?? locationRequest?.uniqueId
    }
}
