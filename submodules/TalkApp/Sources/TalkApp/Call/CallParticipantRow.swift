//
//  CallParticipantRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatModels
import SwiftUI
import WebRTC

struct CallParticipantRow: View {
    var userRTC: CallParticipantUserRTC
    @EnvironmentObject var viewModel: CallViewModel

    var body: some View {
        HStack(spacing: 8) {
//            ImageLaoderView(url: userRTC.callParticipant.participant?.image, userName: userRTC.callParticipant.participant?.name?.uppercased())
//                .frame(width: 48, height: 48)
//                .cornerRadius(24)
            VStack {
//                Text(userRTC.callParticipant.title ?? "")
//                    .font(.headline)
//
//                HStack(spacing: 0) {
//                    if let callStatusString = userRTC.callParticipant.callStatusString {
//                        Text(callStatusString)
//                            .foregroundColor(userRTC.callParticipant.callStatusStringColor)
//                            .font(.caption.bold())
//                    }
//                }
            }
            Spacer()
//            if userRTC.callParticipant.active == false {
//                Button {
//                    viewModel.recall(userRTC.callParticipant.participant)
//                } label: {
//                    Image(systemName: "phone.fill.badge.plus")
//                        .resizable()
//                        .scaledToFit()
//                        .foregroundColor(.blue)
//                        .frame(width: 24, height: 24)
//                        .padding(8)
//                }
//            }
//            Circle()
//                .fill(userRTC.callParticipant.mute == true ? Color.gray : .green)
//                .shadow(color: .gray.opacity(0.22), radius: 5, x: 0, y: 0)
//                .overlay(
//                    Image(systemName: userRTC.callParticipant.mute ? "mic.slash.fill" : "mic.fill")
//                        .resizable()
//                        .scaledToFit()
//                        .foregroundColor(.white)
//                        .frame(width: 16, height: 16)
//                        .padding(2)
//                )
//                .frame(width: 32, height: 32)
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 4)
    }
}

struct OfflineParticipantRow: View {
    var participant: Participant
    @EnvironmentObject var viewModel: CallViewModel
//    @StateObject var imageLoader = ImageLoader()

    var body: some View {
        HStack(spacing: 8) {
//            ImageLaoderView(url: participant.image, userName: participant.name?.uppercased())
//                .frame(width: 48, height: 48)
//                .cornerRadius(24)
            VStack {
                Text(participant.name ?? "")
                    .font(.headline)
            }
            Spacer()
            Button {
                viewModel.recall(participant)
            } label: {
                Image(systemName: "phone.fill.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .padding(8)
            }
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 4)
    }
}

// struct CallParticipantRow_Previews: PreviewProvider {
//
//    static var previews: some View {
//        let viewModel = CallViewModel.shared
//        let callParticipants = MockData.generateCallParticipant(count: 1, callStatus: .accepted)
//        let clientDTO = ClientDTO(clientId: "", topicReceive: "", topicSend: "", userId: 0, desc: "", sendKey: nil, video: true, mute: false)
//        let dto = ChatDataDTO(sendMetaData: "", screenShare: "", reciveMetaData: "", turnAddress: "", brokerAddressWeb: "", kurentoAddress: "")
//        let startCall = StartCall(certificateFile: "", clientDTO: clientDTO, chatDataDto: dto, callName: "", callImage: nil)
//        CallParticipantRow(userRTC: CallParticipantUserRTC(callParticipant: callParticipants.first!, config: WebRTCConfig(startCall: startCall, isSendVideoEnabled: false), delegate: PreviewDelegate()))
//        .environmentObject(viewModel)
//        .onAppear {
//            viewModel.objectWillChange.send()
//        }
//    }
// }
