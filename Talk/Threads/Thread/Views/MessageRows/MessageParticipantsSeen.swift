//
//  MessageParticipantsSeen.swift
//  Talk
//
//  Created by hamed on 11/15/23.
//

import SwiftUI
import TalkViewModels
import ChatModels
import TalkUI

struct MessageParticipantsSeen: View {
    @EnvironmentObject var threadVM: ThreadViewModel
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
                }
            }
        }
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: viewModel.participants.count)
        .padding(.horizontal, viewModel.isEmpty ? 0 : 6)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("SeenParticipants.title")
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    threadVM.scrollVM.disableExcessiveLoading()
                    AppState.shared.navViewModel?.remove(type: MessageParticipantsSeenNavigationValue.self)
                }
            }

            ToolbarItemGroup(placement: .principal) {
                Text("SeenParticipants.title")
                    .font(.iransansBoldBody)
                    .foregroundStyle(Color.App.textPrimary)
            }
        }
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
                .background(String.getMaterialColorByCharCode(str: participant.name ?? participant.username ?? ""))
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
                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"))
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
