//
//  MockAppConfiguration.swift
//  Talk
//
//  Created by hamed on 1/19/24.
//

import Foundation
import Chat
import ChatModels
import ChatCore
import TalkModels
import TalkViewModels
import Logger
import Additive

@MainActor
class MockAppConfiguration: ChatDelegate {
    let conversation = Conversation(group: true, id: 1, type: .normal)
    var viewModels: [MessageRowViewModel] = []
    var forwardInfo: ForwardInfo!
    var replyInfo: ReplyInfo!
    var radioSelectVM: MessageRowViewModel!
    var avatarVM: MessageRowViewModel!
    var joinLinkVM: MessageRowViewModel!
    var groupParticipantNameVM: MessageRowViewModel!
    var messages: [Message] = []
    /// For Xcode preview it is essential to save conversatioVM inside the delegate to prevent being deallocated.
    var conversationVM: ThreadViewModel!

    func makeViewModel(message: Message) -> MessageRowViewModel {
        AppState.shared.objectsContainer.threadsVM.threads.append(conversation)
        return MessageRowViewModel(message: message, viewModel: conversationVM)
    }

    static var shared: MockAppConfiguration = MockAppConfiguration()
    static let isMeId = 1

    private init () {
//        AppState.shared.mockUser = .init(cellphoneNumber: nil,
//                                           coreUserId: nil,
//                                           email: nil,
//                                           id: MockAppConfiguration.isMeId,
//                                           image: nil,
//                                           lastSeen: nil,
//                                           name: "MySelf",
//                                           nickname: nil,
//                                           receiveEnable: nil,
//                                           sendEnable: nil,
//                                           username: nil,
//                                           ssoId: nil,
//                                           firstName: nil,
//                                           lastName: nil,
//                                           profile: nil)
        AppState.shared.objectsContainer = .init(delegate: self)
        AppState.shared.objectsContainer.audioPlayerVM = .init()
        conversationVM = ThreadViewModel(thread: conversation, threadsViewModel: AppState.shared.objectsContainer.threadsVM)

        let longText = """
This is a very long text to test how it would react to size change\n
In this new line we are going to test if it can break the line.
"""
        let fileMetaData = FileMetaData(file:
                .init(fileExtension: "pdf",
                      link: "https://podspace.pod.ir/api/files/59XAD7YZFXY4BSPS",
                      mimeType: "application/pdf",
                      name: "Report",
                      originalName: "Report.pdf",
                      size: 1350000)
        )
        let audioMetaData = FileMetaData(file:
                .init(fileExtension: "mp3",
                      link: "https://podspace.pod.ir/api/files/59XAD7YZFXY4BSPS",
                      mimeType: "audio/mpeg",
                      name: "dance the night",
                      originalName: "dance the night.mp3",
                      size: 48202520)
        )
        let imageMetaData = FileMetaData(file:
                .init(fileExtension: "jpg",
                      link: "https://podspace.pod.ir/api/images/59XAD7YZFXY4BSPS",
                      mimeType: "image/jpeg",
                      name: nil,
                      originalName: nil,
                      size: 50000,
                      actualHeight: 500, actualWidth: 500)
        )

        groupParticipantNameVM = {
            let message = Message(
                id: 1,
                message: longText,
                messageType: .text,
                ownerId: 2,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(
                    id: 2,
                    image: "https://avatars.githubusercontent.com/u/21770946?v=4",
                    name: "John Doe")
            )
            let vm = makeViewModel(message: message)
            vm.calMessage.isLastMessageOfTheUser = false
            return vm
        }()

        joinLinkVM = {
            let message = Message(
                id: 1,
                message: "\(AppRoutes.joinLink)FAKEUNIQUENAME",
                messageType: .text,
                ownerId: 2,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(
                    id: 2,
                    image: "https://avatars.githubusercontent.com/u/21770946?v=4",
                    name: "John Doe")
            )
            let vm = makeViewModel(message: message)
            return vm
        }()

        avatarVM = {
            let message = Message(
                id: 1,
                message: longText,
                messageType: .text,
                ownerId: 2,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(
                    id: 2,
                    image: "https://avatars.githubusercontent.com/u/21770946?v=4",
                    name: "John Doe")
            )
            let vm = makeViewModel(message: message)
            return vm
        }()

        radioSelectVM = {
            let message = Message(
                id: 1,
                message: longText,
                messageType: .text,
                ownerId:MockAppConfiguration.isMeId,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 0, name: "John Doe"))
            let vm = makeViewModel(message: message)
            vm.threadVM?.selectedMessagesViewModel.setInSelectionMode(true)
            return vm
        }()

        replyInfo = ReplyInfo(
            repliedToMessageId: 1,
            message: "TEST Reply ",
            messageType: .podSpacePicture,
            metadata: try? JSONEncoder().encode(imageMetaData).utf8String,
            repliedToMessageTime: 155600555
        )

        forwardInfo = ForwardInfo(
            conversation: ForwardInfoConversation(id: 1, title: "Forwarded thread title"),
            participant: .init(name: "Apple Seed")
        )

        messages = [
            .init(
                id: 1,
                message: longText,
                messageType: .text,
                ownerId: MockAppConfiguration.isMeId,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 1, name: "Myself")
            ),
            .init(
                id: 1,
                message: longText,
                messageType: .podSpacePicture,
                metadata: try? JSONEncoder().encode(imageMetaData).utf8String,
                ownerId: MockAppConfiguration.isMeId,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 2, name: "John doe")
            ),
            .init(
                id: 1,
                message: longText,
                messageType: .podSpaceFile,
                metadata: try? JSONEncoder().encode(fileMetaData).utf8String,
                ownerId: MockAppConfiguration.isMeId,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 2, name: "John doe")
            ),
            .init(
                id: 1,
                message: nil,
                messageType: .podSpaceFile,
                metadata: try? JSONEncoder().encode(fileMetaData).utf8String,
                ownerId: MockAppConfiguration.isMeId,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 2, name: "John doe")
            ),
            .init(
                id: 1,
                message: nil,
                messageType: .podSpaceSound,
                metadata: try? JSONEncoder().encode(audioMetaData).utf8String,
                ownerId: 2,
                seen: true,                
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 2, name: "John doe")
            ),
            .init(
                id: 1,
                message: longText,
                messageType: .text,
                metadata: nil,
                ownerId: 2,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 2, name: "John doe")
            ),
            .init(
                id: 1,
                message: longText,
                messageType: .text,
                ownerId: 2,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 2, name: "John Doe"),
                replyInfo: replyInfo
            ),
            .init(
                id: 1,
                message: longText,
                messageType: .text,
                ownerId: 2,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                forwardInfo: forwardInfo,
                participant: Participant(id: 2, name: "John Doe")
            )
        ]

        var vms: [MessageRowViewModel] = []
        messages.forEach { message in
            let vm = makeViewModel(message: message)
            vms.append(vm)
        }
        viewModels = vms
    }

    nonisolated func chatState(state: ChatCore.ChatState, currentUser: ChatModels.User?, error: ChatCore.ChatError?) {

    }

    nonisolated func chatEvent(event: ChatEventType) {

    }

    nonisolated func onLog(log: Log) {

    }
}
