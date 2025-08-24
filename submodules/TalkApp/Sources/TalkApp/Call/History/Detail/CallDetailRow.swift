//
//  CallDetailRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Additive
import ChatModels
import SwiftUI

struct CallDetailRow: View {
    private(set) var call: Call
    private var viewModel: CallDetailViewModel

    init(call: Call, viewModel: CallDetailViewModel) {
        self.call = call
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: {}, label: {
            HStack {
//                ImageLaoderView(url: call.partnerParticipant?.image, userName: call.partnerParticipant?.name?.uppercased())
//                    .frame(width: 48, height: 48)
//                    .cornerRadius(24)
                VStack(alignment: .leading) {
                    Text(call.partnerParticipant?.name ?? "")
                        .foregroundColor(.black)
                    HStack {
                        Image(systemName: call.isIncomingCall(currentUserId: AppState.shared.user?.id) ? "arrow.down.left" : "arrow.up.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(call.isIncomingCall(currentUserId: AppState.shared.user?.id) ? Color.red : Color.green)

                        if let createTime = call.createTime {
                            let date = Date(milliseconds: Int64(createTime))
//                            Text(date.timeAgoSinceDateCondense ?? "")
//                                .font(.system(size: 14))
//                                .foregroundColor(.gray)
                        }
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
        })
    }
}

struct CallDetailModel_Previews: PreviewProvider {
    static var previews: some View {
        CallRow(call: CallRow_Previews.call, viewModel: CallsHistoryViewModel())
    }
}
