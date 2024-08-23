import Chat

public class ForwardMessage: HistoryMessageBaseCalss, UnSentMessageProtocol {
    public var forwardMessageRequest: ForwardMessageRequest
    public var destinationThread: Conversation

    public init(from forwardMessageRequest: ForwardMessageRequest, destinationThread: Conversation, thread: Conversation?) {
        self.forwardMessageRequest = forwardMessageRequest
        self.destinationThread = destinationThread
        let message = Message(
            uniqueId: forwardMessageRequest.uniqueId,
            conversation: thread
        )
        super.init(message: message)
    }

    public init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
