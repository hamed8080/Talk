import Chat

public class EditTextMessage: HistoryMessageBaseCalss, UnSentMessageProtocol {
    public var editMessageRequest: EditMessageRequest

    public init(from editMessageRequest: EditMessageRequest, thread: Conversation?) {
        self.editMessageRequest = editMessageRequest
        let message = Message(
            threadId: editMessageRequest.threadId,
            message: editMessageRequest.textMessage,
            uniqueId: editMessageRequest.uniqueId,
            conversation: thread
        )
        super.init(message: message)
    }

    public init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
