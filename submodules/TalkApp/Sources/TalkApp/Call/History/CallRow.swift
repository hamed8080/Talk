//
//  CallRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import ChatModels
import SwiftUI

struct CallRow: View {
    private(set) var call: Call
    private var viewModel: CallsHistoryViewModel

    init(call: Call, viewModel: CallsHistoryViewModel) {
        self.call = call
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
//            ImageLaoderView(url: call.conversation?.computedImageURL ?? call.partnerParticipant?.image, userName: call.conversation?.title ?? call.partnerParticipant?.name?.uppercased())
//                .frame(width: 48, height: 48)
//                .cornerRadius(24)
            VStack(alignment: .leading) {
                Text(call.conversation?.title ?? call.partnerParticipant?.name ?? "")

                HStack {
                    Image(systemName: call.isIncomingCall(currentUserId: AppState.shared.user?.id) ? "arrow.down.left" : "arrow.up.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor(call.isIncomingCall(currentUserId: AppState.shared.user?.id) ? Color.red : Color.green)

//                    if let createTime = call.createTime {
//                        let date = Date(milliseconds: Int64(createTime))
//                        Text(date.timeAgoSinceDateCondense ?? "")
//                            .font(.system(size: 14))
//                            .foregroundColor(.gray)
//                    }
                }
            }

            Spacer()

            Image(systemName: call.type == .videoCall ? "video.fill" : "phone.fill")
                .resizable()
                .scaledToFit()
                .padding(12)
                .frame(width: 38, height: 38)
                .foregroundColor(.blue.opacity(0.9))
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 16)
        .padding([.top, .bottom], 4)
    }
}

struct CallRow_Previews: PreviewProvider {
    static var call: Call {
        let partnerParticipant = Participant(admin: nil,
                                             auditor: nil,
                                             blocked: false,
                                             cellphoneNumber: nil,
                                             contactFirstName: "Hamed",
                                             contactId: nil,
                                             contactName: nil,
                                             contactLastName: nil,
                                             coreUserId: nil,
                                             email: nil,
                                             firstName: nil,
                                             id: 18478,
                                             image: nil,
                                             keyId: nil,
                                             lastName: nil,
                                             myFriend: nil,
                                             name: "Hamed Hosseini",
                                             notSeenDuration: nil,
                                             online: false,
                                             receiveEnable: nil,
                                             roles: nil,
                                             sendEnable: nil,
                                             username: nil,
                                             chatProfileVO: nil)
        let call = Call(id: 1763,
                        creatorId: 18478,
                        type: .voiceCall,
                        isGroup: false,
                        createTime: 1_626_173_608_000,
                        startTime: nil,
                        endTime: 1_612_076_779_373,
                        status: .accepted,
                        callParticipants: nil,
                        partnerParticipant: partnerParticipant)
        return call
    }

    static var previews: some View {
        CallRow(call: call, viewModel: CallsHistoryViewModel())
    }
}
