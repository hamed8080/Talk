//
//  AvatarView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct AvatarView: View {
    @EnvironmentObject var navVM: NavigationModel
    var message: Message
    let viewModel: ThreadViewModel?

    var body: some View {
        if !(viewModel?.isSameUser(message: message) == true), message.participant != nil {
            Button {
                if let participant = message.participant {
                    navVM.append(participantDetail: participant)
                }
            } label: {
                HStack(spacing: 8) {
                    if message.isMe(currentUserId: AppState.shared.user?.id) {
                        Spacer()
                        Text("\(message.participant?.name ?? "")")
                            .font(.iransansBoldCaption)
                            .foregroundColor(.darkGreen)
                            .lineLimit(1)
                    }

                    if let image = message.participant?.image, let imageLoaderVM = viewModel?.threadsViewModel?.avatars(for: image) {
                        ImageLaoderView(imageLoader: imageLoaderVM, url: message.participant?.image, userName: message.participant?.name ?? message.participant?.username)
                            .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                            .font(.iransansSubheadline)
                            .foregroundColor(.white)
                            .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(MessageRowViewModel.avatarSize / 2)
                    } else {
                        Text(verbatim: String(message.participant?.name?.first ?? message.participant?.username?.first ?? " "))
                            .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                            .font(.iransansSubheadline)
                            .foregroundColor(.white)
                            .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(MessageRowViewModel.avatarSize / 2)
                    }
                    if !message.isMe(currentUserId: AppState.shared.user?.id) {
                        Text("\(message.participant?.name ?? "")")
                            .font(.iransansBoldCaption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                .padding(.bottom, 4)
                .padding([.leading, .trailing, .top])
            }
        } else {
            Rectangle()
                .frame(width: 36, height: 0)
                .hidden()
        }
    }
}
