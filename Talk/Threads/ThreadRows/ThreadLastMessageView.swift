//
//  ThreadLastMessageView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct ThreadLastMessageView: View {
    let isSelected: Bool
    let thread: Conversation
    @EnvironmentObject var eventViewModel: ThreadEventViewModel

    var body: some View {
        VStack(spacing: 2) {
            if eventViewModel.isShowingEvent {
                ThreadEventView()
                    .transition(.push(from: .leading))
            } else {
                NormalLastMessageContainer(isSelected: isSelected, thread: thread)
            }
        }
        .animation(.easeInOut, value: eventViewModel.isShowingEvent)
    }
}

struct NormalLastMessageContainer: View {
    let isSelected: Bool
    let thread: Conversation
    // It must be here because we need to redraw the view after the thread inside ViewModel has changed.
    @EnvironmentObject var viewModel: ThreadsViewModel
    private static let pinImage = Image("ic_pin")

    var body: some View {
        if let callMessage = callMessage {
            ConversationCallMessageType(message: callMessage)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 0) {
                if let addOrRemoveParticipant = addOrRemoveParticipant {
                    Text(addOrRemoveParticipant)
                        .font(.iransansCaption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
                } else if let participantName = participantName {
                    Text(participantName)
                        .font(.iransansCaption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
                }

                //            if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
                //                Image(systemName: iconName)
                //                    .resizable()
                //                    .frame(width: 16, height: 16)
                //                    .foregroundStyle(Color.App.color1)
                //            }

                if let fiftyFirstCharacter = fiftyFirstCharacter {
                    Text(fiftyFirstCharacter)
                        .font(.iransansCaption2)
                        .fontWeight(.regular)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
                } else if let sentFileString = sentFileString {
                    Text(sentFileString)
                        .font(.iransansCaption2)
                        .fontWeight(.regular)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
                }

                if let createConversationString = createConversationString {
                    Text(createConversationString)
                        .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
                        .font(.iransansCaption2)
                        .fontWeight(.regular)
                }
                Spacer()

                if thread.mute == true {
                    Image(systemName: "bell.slash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
                }


                if thread.pin == true, hasSpaceToShowPin {
                    NormalLastMessageContainer.pinImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
                        .padding(.leading, thread.pin == true ? 4 : 0)
                        .offset(y: -2)
                }
            }
        }
    }

    private var lastMsgVO: Message? { thread.lastMessageVO }
    private var isCallType: Bool { lastMsgVO?.callHistory != nil }
    private var isMe: Bool { lastMsgVO?.isMe(currentUserId: AppState.shared.user?.id ?? -1) == true }
    private var isFileType: Bool { lastMsgVO?.isFileType == true }

    private var hasSpaceToShowPin: Bool {
        let allActive = thread.pin == true && thread.mute == true && thread.unreadCount ?? 0 > 0
        return !allActive
    }

    private var fiftyFirstCharacter: String? {
        if !isFileType, let message = lastMsgVO?.message?.replacingOccurrences(of: "\n", with: " ").prefix(50) {
            return String(message)
        } else {
            return nil
        }
    }

    private var addOrRemoveParticipant: String? {
        if let addOrRemoveParticipantString = lastMsgVO?.addOrRemoveParticipantString(meId: AppState.shared.user?.id) {
            return addOrRemoveParticipantString
        } else {
            return nil
        }
    }

    private var participantName: String? {
        if let participantName = lastMsgVO?.participant?.contactName ?? lastMsgVO?.participant?.name, thread.group == true {
            let meVerb = String(localized: .init("General.you"), bundle: Language.preferedBundle)
            let localized = String(localized: .init("Thread.Row.lastMessageSender"), bundle: Language.preferedBundle)
            let participantName = String(format: localized, participantName)
            let name = isMe ? "\(meVerb):" : participantName
            return Message.textDirectionMark + name
        } else {
            return nil
        }
    }

    private var createConversationString: String? {
        if lastMsgVO == nil, let creator = thread.inviter?.name {
            let type = thread.type
            let key = type?.isChannelType == true ? "Thread.createdAChannel" : "Thread.createdAGroup"
            let localizedLabel = String(localized: .init(key), bundle: Language.preferedBundle)
            let text = String(format: localizedLabel, creator)
            return text
        } else {
            return nil
        }
    }

    private var sentFileString: String? {
        if isFileType {
            let fileStringName = lastMsgVO?.fileStringName ?? "MessageType.file"
            let sentVerb = String(localized: .init(isMe ? "Genral.mineSendVerb" : "General.thirdSentVerb"), bundle: Language.preferedBundle)
            let formatted = String(format: sentVerb, fileStringName.localized(bundle: Language.preferedBundle))
            return Message.textDirectionMark + "\(formatted)"
        } else {
            return nil
        }
    }

    private var callMessage: Message? {
        if let message = lastMsgVO, message.type == .endCall || message.type == .startCall {
            return message
        } else {
            return nil
        }
    }
}
