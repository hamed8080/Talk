//
//  ParticipantRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import SwiftUI
import TalkUI
import TalkViewModels

struct ParticipantRow: View {
    let participant: Participant
    var isOnline: Bool { participant.notSeenDuration ?? 16000 < 15000 }

    var body: some View {
        HStack {
            ZStack {
                ImageLoaderView(participant: participant)
                    .id("\(participant.image ?? "")\(participant.id ?? 0)")
                    .font(.fBoldBody)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color(uiColor:String.getMaterialColorByCharCode(str: participant.name ?? participant.username ?? "")))
                    .clipShape(RoundedRectangle(cornerRadius:(22)))

//                Circle()
//                    .fill(Color.App.color2)
//                    .frame(width: 13, height: 13)
//                    .offset(x: -20, y: 18)
//                    .blendMode(.destinationOut)
//                    .overlay {
//                        Circle()
//                            .fill(isOnline ? Color.App.color2 : Color.App.iconSecondary)
//                            .frame(width: 10, height: 10)
//                            .offset(x: -20, y: 18)
//                    }
            }
//            .compositingGroup()

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                        .font(.fBody)
                    if let cellphoneNumber = participant.cellphoneNumber, !cellphoneNumber.isEmpty {
                        Text(cellphoneNumber)
                            .font(.fCaption3)
                            .foregroundColor(.primary.opacity(0.5))
                    }
//                    if  let notSeenDuration = participant.notSeenDuration?.localFormattedTime {
//                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"), bundle: Language.preferedBundle)
//                        let time = String(format: lastVisitedLabel, notSeenDuration)
//                        Text(time)
//                            .font(.fBody)
//                            .foregroundColor(Color.App.textSecondary)
//                    }
                }

                Spacer()
                ParticipantRowLables(participantId: participant.id)
            }
        }
        .lineLimit(1)
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
    }
}

struct ParticipantRowLables: View {
    /// It is essential to use the ViewModel version of the participant rather than pass it to the view as a `let participant`. It is needed when an add/remove admin or assistant access is updated.
    @EnvironmentObject var viewModel: ParticipantsViewModel
    var paritcipant: Participant? { viewModel.participants.first(where: { $0.id == participantId }) ?? viewModel.searchedParticipants.first(where: { $0.id == participantId })  }
    @State var participantId: Int?

    var body: some View {
        HStack {
            if let participant = paritcipant {
                if viewModel.thread?.inviter?.id == participantId {
                    Text("Participant.admin")
                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                        .foregroundColor(Color.App.accent)
                } else if participant.admin == true {
                    Text("Participant.admin")
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 4))
                        .foregroundColor(Color.App.accent)
                } else if participant.auditor == true {
                    Text("Participant.assistant")
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 4))
                        .foregroundColor(Color.App.accent)
                }
            }
        }
        .font(.fBoldCaption)
    }
}

#if DEBUG
struct ParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantRow(participant: MockData.participant(1))
    }
}
#endif
