import Chat

public struct AttachmentModel: Sendable {
    public private(set) var count = 50
    public private(set) var offset = 0
    public private(set) var totalCount = 0
    public private(set) var messages: [Message] = []
    public private(set) var hasNext: Bool = false

    public init(){}

    public mutating func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    public mutating func preparePaginiation() {
        offset = messages.count
    }

    public mutating func setContentCount(totalCount: Int) {
        self.totalCount = totalCount
    }

    public mutating func setMessages(messages: [Message]) {
        self.messages = messages
        sort()
    }

    public mutating func appendMessages(messages: [Message]) {
        self.messages.append(contentsOf: filterNewMessagesToAppend(serverMessages: messages))
        sort()
    }

    /// Filter only new messages prevent conflict with cache messages
    public mutating func filterNewMessagesToAppend(serverMessages: [Message]) -> [Message] {
        let ids = messages.map(\.id)
        let newMessages = serverMessages.filter { message in
            !ids.contains { id in
                id == message.id
            }
        }
        return newMessages
    }

    public mutating func appendMessage(_ message: Message) {
        messages.append(message)
        sort()
    }

    public mutating func clear() {
        offset = 0
        count = 15
        totalCount = 0
        messages = []
    }

    public mutating func sort() {
        messages = messages.sorted { m1, m2 in
            if let t1 = m1.time, let t2 = m2.time {
                return t1 < t2
            } else {
                return false
            }
        }
    }
}
