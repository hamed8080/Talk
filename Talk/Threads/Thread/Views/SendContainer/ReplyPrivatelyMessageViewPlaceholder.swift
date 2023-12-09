//
//  ReplyPrivatelyMessageViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI

struct ReplyPrivatelyMessageViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if let replyMessage = AppState.shared.appStateNavigationModel.replyPrivately {
            HStack {
                SendContainerButton(image: "arrow.turn.up.left")

                VStack(alignment: .leading, spacing: 0) {
                    if let name = replyMessage.participant?.name {
                        Text(name)
                            .font(.iransansBoldBody)
                            .foregroundStyle(Color.App.primary)
                    }
                    Text(replyMessage.message ?? replyMessage.fileMetaData?.name ?? "")
                        .font(.iransansCaption2)
                        .foregroundColor(Color.App.placeholder)
                        .onTapGesture {
                            // TODO: Go to reply message location
                        }
                }

                Spacer()
                CloseButton {
                    AppState.shared.appStateNavigationModel = .init()
                    viewModel.animateObjectWillChange()
                }
                .padding(.trailing, 4)
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
        }
    }
}

struct ReplyPrivatelyMessageViewPlaceholder_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.replyMessage = .init(threadId: 1,
                                           message: "Test message", messageType: .text,
                                           participant: .init(name: "John Doe"))
            return viewModel
        }

        var body: some View {
            ReplyPrivatelyMessageViewPlaceholder()
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}