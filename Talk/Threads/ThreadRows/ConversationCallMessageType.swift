//
//  ConversationCallMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions

struct ConversationCallMessageType: View {
    var message: Message
    @Environment(\.colorScheme) var color

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time {
                let date = Date(milliseconds: Int64(time))
                HStack(spacing: 2) {
                    if let key = message.callHistory?.status?.key {
                        Text(key)
                        Text("\(date.localFormattedTime ?? "")")
                            .fontWeight(.bold)
                    }
                }
                .font(.fFootnote)
                .foregroundColor(color == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                .padding(2)
            }

            Image(systemName: message.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(message.type == .startCall ? Color.App.color2 : Color.App.red)
        }
        .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 8))
        .background(Color.App.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius:(6)))
    }
}
