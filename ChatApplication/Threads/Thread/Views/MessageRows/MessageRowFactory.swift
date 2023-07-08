//
//  MessageRowFactory.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatAppModels
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MessageRowFactory: View {
    var message: Message
    @State var calculation: MessageRowCalculationViewModel = .init()
    @EnvironmentObject var viewModel: ThreadViewModel
    @State private(set) var showParticipants: Bool = false
    private var isMe: Bool { message.isMe(currentUserId: AppState.shared.user?.id) }

    var body: some View {
        HStack(spacing: 0) {
            if message is UnreadMessageProtocol {
                UnreadMessagesBubble()
            } else {
                if let type = message.type {
                    if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                        TextMessageType(message: message)
                            .environmentObject(calculation)
                    } else if type == .participantJoin || type == .participantLeft {
                        ParticipantMessageType(message: message)
                    } else if type == .endCall || type == .startCall {
                        CallMessageType(message: message)
                    } else {
                        UnknownMessageType(message: message)
                    }
                }
            }
        }
        .transition(.asymmetric(insertion: .push(from: isMe ? .trailing : .leading), removal: .move(edge: isMe ? .trailing : .leading)))
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let threadVM = ThreadViewModel()
        List {
            ForEach(MockData.generateMessages(count: 5)) { message in
                MessageRowFactory(message: message, calculation: .init())
                    .environmentObject(threadVM)
            }
        }
        .environmentObject(MessageRowCalculationViewModel())
        .onAppear {
            threadVM.setup(thread: MockData.thread)
        }
        .listStyle(.plain)
    }
}