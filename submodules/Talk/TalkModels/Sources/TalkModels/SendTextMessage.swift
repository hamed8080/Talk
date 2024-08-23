import Chat

public class SendTextMessage: HistoryMessageBaseCalss, UnSentMessageProtocol {
    public var sendTextMessageRequest: SendTextMessageRequest

    public init(from sendTextMessageRequest: SendTextMessageRequest, thread: Conversation?) {
        self.sendTextMessageRequest = sendTextMessageRequest
        let message = Message(
                threadId: sendTextMessageRequest.threadId,
                message: sendTextMessageRequest.textMessage,
                uniqueId: sendTextMessageRequest.uniqueId,
                conversation: thread
        )
        super.init(message: message)
    }

    public init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
