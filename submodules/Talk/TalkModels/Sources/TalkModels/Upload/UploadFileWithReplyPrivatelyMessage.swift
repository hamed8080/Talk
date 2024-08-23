import Chat

public class UploadFileWithReplyPrivatelyMessage: HistoryMessageBaseCalss, UploadProtocol {
    public var replyPrivatelyRequest: ReplyPrivatelyRequest
    public var uploadFileRequest: UploadFileRequest?
    public var uploadImageRequest: UploadImageRequest?

    public init(replyPrivatelyRequest: ReplyPrivatelyRequest, uploadFileRequest: UploadFileRequest) {
        self.replyPrivatelyRequest = replyPrivatelyRequest
        self.uploadFileRequest = uploadFileRequest
        super.init(message: Message())
    }

    public init(replyPrivatelyRequest: ReplyPrivatelyRequest, uploadImageRequest: UploadImageRequest) {
        self.replyPrivatelyRequest = replyPrivatelyRequest
        self.uploadImageRequest = uploadImageRequest
        super.init(message: Message())
    }
}
