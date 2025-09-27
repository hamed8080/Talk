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
    @EnvironmentObject var thread: CalculatedConversation
    @EnvironmentObject var eventViewModel: ThreadEventViewModel

    var body: some View {
        VStack(spacing: 2) {
            if eventViewModel.isShowingEvent, eventViewModel.smt == .isTyping {
                ThreadEventView()
                    .transition(.push(from: .leading))
            } else {
                NormalLastMessageContainer(isSelected: isSelected)
            }
        }
        .animation(.easeInOut, value: eventViewModel.isShowingEvent)
    }
}

struct NormalLastMessageContainer: View {
    let isSelected: Bool
    @EnvironmentObject var thread: CalculatedConversation
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
                if let nsAttr = thread.subtitleAttributedString {
                    Text(AttributedString(nsAttr))
                        .font(.fCaption2)
                        .fontWeight(.regular)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
                }
                Spacer()
                muteView
                pinView
            }
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
