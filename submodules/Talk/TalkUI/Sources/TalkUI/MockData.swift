import Chat
import Foundation
import TalkModels
import Chat

public struct MockDataModel: Decodable {
    public let threads: [Conversation]
    public let messages: [Message]
    public let contacts: [Contact]
    public let tags: [Tag]
    public let participants: [Participant]
    public let callParticipants: [CallParticipant]

    public init(threads: [Conversation], messages: [Message], contacts: [Contact], tags: [Tag], participants: [Participant], callParticipants: [CallParticipant]) {
        self.threads = threads
        self.messages = messages
        self.contacts = contacts
        self.tags = tags
        self.participants = participants
        self.callParticipants = callParticipants
    }
}

public final class MockData {
    /// Threads
    public static var thread: Conversation {
        let lastMessageVO = LastMessageVO(
            message: "Hi hamed how are you? are you ok? and what are you ding now. And i was thinking you are sad for my behavoi last night."
        )
        let thread = Conversation(
            canEditInfo: true,
            description: "description",
            id: 123,
            image: "avatar1",
            pin: false,
            title: "Hamed Hosseini",
            type: ThreadTypes.publicGroup,
            lastMessageVO: lastMessageVO
        )
        return thread
    }

    public static func generateThreads(count: Int = 50) -> [Conversation] {
        var threads: [Conversation] = mockDataModel.threads.map { thread in
            var thread = thread
            thread.lastMessageVO = LastMessageVO(message: thread.lastMessage)
            return thread
        }
        if threads.count < count {
            for i in 0 ... count {
                var thread = thread
                thread.title = mockDataModel.threads[Int.random(in: 1 ... 15)].title
                thread.description = mockDataModel.threads[Int.random(in: 1 ... 15)].description
                thread.image = mockDataModel.threads[Int.random(in: 1 ... 15)].image
                thread.lastMessageVO = LastMessageVO(message: mockDataModel.threads[Int.random(in: 1 ... 15)].lastMessage ?? "")
                thread.id = i
                threads.append(thread)
            }
        }
        return threads
    }

    /// Contacts
    public static var contact: Contact {
        let contact = Contact(
            blocked: false,
            cellphoneNumber: "+989369161601",
            email: nil,
            firstName: "Hamed",
            hasUser: true,
            id: 0,
            image: "avatar4",
            lastName: "Hosseini",
            user: nil,
            notSeenDuration: 1_622_969_881,
            time: nil,
            userId: nil
        )
        return contact
    }

    public static func generateContacts(count: Int = 50) -> [Contact] {
        var contacts: [Contact] = mockDataModel.contacts

        if contacts.count < count {
            var lastIndex = contacts.count + 2
            for _ in 0 ... count {
                var contact = contact
                contact.firstName = mockDataModel.contacts[Int.random(in: 1 ... 15)].firstName
                contact.lastName = mockDataModel.contacts[Int.random(in: 1 ... 15)].lastName
                contact.image = mockDataModel.contacts[Int.random(in: 1 ... 15)].image
                contact.id = lastIndex
                lastIndex += 1
                contacts.append(contact)
            }
        }
        return contacts
    }

    /// Message
    public static var message: Message {
        let message = Message(
            threadId: 0,
            id: 0,
            message: "Hello sahdkf ashfdl sad div exit \nHello",
            messageType: .text,
            seen: false,
            time: 1_636_807_773
        )
        return message
    }

    public static var uploadMessage: UploadFileMessage { UploadFileMessage(uploadFileRequest: UploadFileRequest(data: Data(), fileName: "Film.mp4"), sendTextMessageRequest: .init(threadId: 0, textMessage: "", messageType: .text), thread: thread) }

    public static func generateMessages(count: Int = 50) -> [Message] {
        //        var messages: [Message] = mockDataModel.messages.map { message in
        //            message.uniqueId = UUID().uuidString
        //            return message
        //        }
        var messages: [Message] = []
        var lastIndex = messages.count + 1
        for index in 0 ... count {
            var message = Message()
            message.uniqueId = UUID().uuidString
            message.message = "Test\(index)"
            message.time = UInt.random(in: 0 ... UInt.max)
            message.ownerId = index
            message.id = index
            message.messageType = .text
            message.uniqueId = UUID().string
            message.participant = participant(Int.random(in: 1 ... 12))
            message.previousId = lastIndex - 1
            lastIndex += 1
            messages.append(message)
        }
        return messages
    }

    /// Participants
    public static func participant(_ index: Int) -> Participant {
        let participant = Participant(
            admin: true,
            cellphoneNumber: "+989369161601",
            contactFirstName: "Hamed",
            contactName: "Hamed",
            contactLastName: "Hosseini",
            firstName: "Hamed",
            id: index,
            image: "avatar\(index)",
            lastName: "Hosseini",
            name: "Hamed",
            online: true,
            username: "hamed8080"
        )
        return participant
    }

    public static func generateParticipants(count: Int = 50) -> [Participant] {
        var participants: [Participant] = mockDataModel.participants

        if participants.count < count {
            var lastIndex = participants.count + 1
            for _ in 0 ... count {
                var participant = participant(1)
                participant.firstName = mockDataModel.participants[Int.random(in: 1 ... 15)].firstName
                participant.lastName = mockDataModel.participants[Int.random(in: 1 ... 15)].lastName
                participant.name = (participant.firstName ?? "") + " " + (participant.lastName ?? "")
                participant.image = mockDataModel.participants[Int.random(in: 1 ... 15)].image
                participant.id = lastIndex
                lastIndex += 1
                participants.append(participant)
            }
        }
        return participants
    }

    /// TAG
    public static var tag: Tag {
        let tag = Tag(
            id: 0,
            name: "Social",
            active: true,
            tagParticipants: generateTagParticipant()
        )
        return tag
    }

    public static func generateTags(count: Int = 50) -> [Tag] {
        var tags: [Tag] = []
        for index in 0 ... count {
            var tag = tag
            tag.name = "Tag Name \(index)"
            tag.id = index
            tag.active = Bool.random()
            tags.append(tag)
        }
        return tags
    }

    /// Tag Participant
    public static var tagParticipant: TagParticipant {
        let tagParticipant = TagParticipant(
            id: 0,
            active: true,
            tagId: 0,
            threadId: thread.id,
            conversation: thread
        )
        return tagParticipant
    }

    public static func generateTagParticipant(count: Int = 50) -> [TagParticipant] {
        var tagParticipants: [TagParticipant] = []
        for index in 0 ... count {
            let thread = generateThreads().randomElement()
            let tagParticipant = TagParticipant(
                id: index,
                active: Bool.random(),
                tagId: index,
                threadId: thread?.id,
                conversation: thread
            )
            tagParticipants.append(tagParticipant)
        }
        return tagParticipants
    }

    nonisolated(unsafe) public static var mockDataModel: MockDataModel = {
        guard let path = Bundle.main.path(forResource: "MockData", ofType: ".json") else {
            return MockDataModel(threads: [], messages: [], contacts: [], tags: [], participants: [], callParticipants: [])
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        return try! JSONDecoder().decode(MockDataModel.self, from: data)
    }()

    static func generateCallParticipant(count: Int = 5, callStatus: CallStatus = .accepted) -> [CallParticipant] {
        var callPrticipants: [CallParticipant] = []
        let participants = generateParticipants(count: count)
        for i in 0 ... (count - 1) {
            let callParticipant = CallParticipant(sendTopic: "Test", callStatus: callStatus, participant: participants[i])
            callPrticipants.append(callParticipant)
        }
        return callPrticipants
    }
}
