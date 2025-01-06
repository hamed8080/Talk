//
//  ThreadLastMessageView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import TalkExtensions

struct ThreadLastMessageView: View {
    let isSelected: Bool
    let thread: CalculatedConversation
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
    let thread: CalculatedConversation
    private static let pinImage = Image("ic_pin")

    var body: some View {
        if let callMessage = thread.callMessage {
            HStack(spacing: 0) {
                ConversationCallMessageType(message: callMessage)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Spacer()
                muteView
                pinView
            }
        } else {
            HStack(spacing: 0) {
                if thread.addRemoveParticipant != nil {
                    addOrRemoveParticipantsView
                } else if thread.participantName != nil {
                    praticipantNameView
                }

                if thread.fiftyFirstCharacter != nil {
                    fiftyFirstTextView
                } else if thread.sentFileString != nil {
                    fileNameLastMessageTextView
                }
                if thread.createConversationString != nil {
                    createdConversation
                }
                Spacer()
                muteView
                pinView
            }
        }
    }

    @ViewBuilder
    private var addOrRemoveParticipantsView: some View {
        if let addOrRemoveParticipant = thread.addRemoveParticipant {
            Text(addOrRemoveParticipant)
                .font(.iransansCaption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
        }
    }

    @ViewBuilder
    private var praticipantNameView: some View {
        if let participantName = thread.participantName {
            Text(participantName)
                .font(.iransansCaption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
        }
    }

//    @ViewBuilder
//    private var lastMessageIcon: some View {
//        //            if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
//        //                Image(systemName: iconName)
//        //                    .resizable()
//        //                    .frame(width: 16, height: 16)
//        //                    .foregroundStyle(Color.App.color1)
//        //            }
//    }

    @ViewBuilder
    private var createdConversation: some View {
        if let createConversationString = thread.createConversationString {
            Text(createConversationString)
                .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
                .font(.iransansCaption2)
                .fontWeight(.regular)
        }
    }

    @ViewBuilder
    private var fiftyFirstTextView: some View {
        if let fiftyFirstCharacter = thread.fiftyFirstCharacter {
            Text(verbatim: fiftyFirstCharacter)
                .font(.iransansCaption2)
                .fontWeight(.regular)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
        }
    }

    @ViewBuilder
    private var fileNameLastMessageTextView: some View {
        if let sentFileString = thread.sentFileString {
            Text(sentFileString)
                .font(.iransansCaption2)
                .fontWeight(.regular)
                .lineLimit(thread.group == false ? 2 : 1)
                .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
        }
    }

    @ViewBuilder
    private var muteView: some View {
        if thread.mute == true {
            Image(systemName: "bell.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
        }
    }

    @ViewBuilder
    private var pinView: some View {
        if thread.pin == true, thread.hasSpaceToShowPin {
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
