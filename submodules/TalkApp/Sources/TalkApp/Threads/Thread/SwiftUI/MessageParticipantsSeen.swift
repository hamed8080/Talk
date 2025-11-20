//
//  MessageParticipantsSeen.swift
//  Talk
//
//  Created by hamed on 11/15/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels
import Chat
import Lottie

struct MessageParticipantsSeen: View {
    @StateObject var viewModel: MessageParticipantsSeenViewModel
    
    init(message: Message) {
        self._viewModel = StateObject(wrappedValue: .init(message: message))
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                if viewModel.isEmpty {
                    Text("SeenParticipants.noOneSeenTheMssage")
                        .font(Font.bold(.subheadline))
                        .foregroundColor(Color.App.textPrimary)
                        .frame(minWidth: 0, maxWidth: .infinity)
                } else {
                    ForEach(viewModel.participants) { participant in
                        MessageSeenParticipantRow(participant: participant)
                            .onAppear {
                                if participant == viewModel.participants.last {
                                    viewModel.loadMore()
                                }
                            }
                    }
                    .animation(.easeInOut, value: viewModel.participants.count)
                }
            }
        }
        .background(Color.App.bgPrimary)
        .overlay(alignment: .bottom) {
            if viewModel.isLoading {
                LottieView(animation: .named(viewModel.participants.isEmpty ? "talk_logo_animation.json" : "dots_loading.json"))
                    .playing()
                    .frame(height: 52)
            }
        }
        .normalToolbarView(title: "SeenParticipants.title", type: String.self)
        .onAppear {
            viewModel.getParticipants()
            AppState.shared.objectsContainer.navVM.pushToLinkId(id: "MessageParticipantsSeen-\(viewModel.message.id ?? 0)")
        }
        .onDisappear {
            
            /// We have to pop lastPath tracking because it has been pushed the path tracking once we were about to show this view
            /// So at the top for sure is this path, and disappear can be called either with swipe or back button.
            AppState.shared.objectsContainer.navVM.popLastPathTracking()
            AppState.shared.objectsContainer.navVM.popLinkId(id: "MessageParticipantsSeen-\(viewModel.message.id ?? 0)")
        }
    }
}

struct MessageSeenParticipantRow: View {
    let participant: Participant

    var body: some View {
        HStack {
            ImageLoaderView(participant: participant)
                .id("\(participant.image ?? "")\(participant.id ?? 0)")
                .font(Font.bold(.body))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: participant.name ?? participant.username ?? "")))
                .clipShape(RoundedRectangle(cornerRadius:(22)))

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                        .font(Font.normal(.body))
                    if let cellphoneNumber = participant.cellphoneNumber, !cellphoneNumber.isEmpty {
                        Text(cellphoneNumber)
                            .font(Font.normal(.caption3))
                            .foregroundColor(.primary.opacity(0.5))
                    }
                    if  let notSeenDuration = participant.notSeenDuration?.localFormattedTime {
                        let lastVisitedLabel = "Contacts.lastVisited".bundleLocalized()
                        let time = String(format: lastVisitedLabel, notSeenDuration)
                        Text(time)
                            .font(Font.normal(.body))
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .lineLimit(1)
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
    }
}

struct MessageParticipantsSeen_Previews: PreviewProvider {
    static var previews: some View {
        MessageParticipantsSeen(message: .init(id: 1))
    }
}
