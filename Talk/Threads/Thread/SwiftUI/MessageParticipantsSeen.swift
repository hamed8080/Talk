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
                        .font(.iransansBoldSubheadline)
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
        .padding(.horizontal, viewModel.isEmpty ? 0 : 6)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isLoading)
                .id(UUID())
        }
        .normalToolbarView(title: "SeenParticipants.title", type: MessageParticipantsSeenNavigationValue.self)
        .onAppear {
            viewModel.getParticipants()
        }
    }
}

struct MessageSeenParticipantRow: View {
    let participant: Participant

    var body: some View {
        HStack {
            let config = ImageLoaderConfig(url: participant.image ?? "", userName: String.splitedCharacter(participant.name ?? participant.username ?? ""))
            ImageLoaderView(imageLoader: .init(config: config))
                .id("\(participant.image ?? "")\(participant.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: participant.name ?? participant.username ?? "")))
                .clipShape(RoundedRectangle(cornerRadius:(22)))

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                        .font(.iransansBody)
                    if let cellphoneNumber = participant.cellphoneNumber, !cellphoneNumber.isEmpty {
                        Text(cellphoneNumber)
                            .font(.iransansCaption3)
                            .foregroundColor(.primary.opacity(0.5))
                    }
                    if  let notSeenDuration = participant.notSeenDuration?.localFormattedTime {
                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"), bundle: Language.preferedBundle)
                        let time = String(format: lastVisitedLabel, notSeenDuration)
                        Text(time)
                            .font(.iransansBody)
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
