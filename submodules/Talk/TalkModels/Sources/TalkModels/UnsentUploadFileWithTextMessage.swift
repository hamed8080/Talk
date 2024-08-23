import ChatModels

public class UnsentUploadFileWithTextMessage: HistoryMessageBaseCalss, UnSentMessageProtocol {
    public var uploadFileMessage: UploadFileMessage
    
    public init(uploadFileMessage: UploadFileMessage, message: Message) {
        self.uploadFileMessage = uploadFileMessage
        super.init(message: message)
    }
}
