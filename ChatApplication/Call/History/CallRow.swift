//
//  CallRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct CallRow: View {
    
    private (set) var call:Call
    private var viewModel:CallsHistoryViewModel
    
    init(call: Call , viewModel:CallsHistoryViewModel) {
        self.call = call
        self.viewModel = viewModel
    }
    
    var body: some View {
        
        HStack{
            Avatar(url: call.partnerParticipant?.image, userName: call.partnerParticipant?.name, style: .init(size: 48,textSize: 18))
            VStack(alignment: .leading){
                Text(call.conversation?.title ?? call.partnerParticipant?.name ?? "")
                
                HStack{
                    Image(systemName: call.isIncomingCall ? "arrow.down.left" : "arrow.up.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor( call.isIncomingCall ? Color.red : Color.green)
                    
                    if let createTime = call.createTime, let date = Date(milliseconds: Int64(createTime)){
                        Text(date.getShortFormatOfDate())
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: call.type == .VIDEO_CALL ? "video.fill" : "phone.fill")
                .resizable()
                .scaledToFit()
                .padding(12)
                .frame(width: 38, height: 38)
                .foregroundColor(.blue.opacity(0.9))
        }
        .contentShape(Rectangle())
        .padding([.leading , .trailing] , 16)
        .padding([.top , .bottom] , 4)
    }
}

struct CallRow_Previews: PreviewProvider {
    static var call:Call{
        let partnerParticipant = Participant(admin:nil,
                                             auditor:nil,
                                             blocked: false,
                                             cellphoneNumber: nil,
                                             contactFirstName: "Hamed",
                                             contactId:nil,
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
                        type: .VOICE_CALL,
                        isGroup: false,
                        createTime: 1626173608000,
                        startTime: nil,
                        endTime: 1612076779373,
                        status: .ACCEPTED,
                        callParticipants: nil,
                        partnerParticipant: partnerParticipant)
        return call
    }
    
    static var previews: some View {
        CallRow(call: call,viewModel: CallsHistoryViewModel())
    }
}
