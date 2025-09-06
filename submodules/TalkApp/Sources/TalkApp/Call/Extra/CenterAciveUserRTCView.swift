//
//  CenterAciveUserRTCView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import Chat
import WebRTC

struct CenterAciveUserRTCView: View {
    @EnvironmentObject var viewModel: CallViewModel
    var userRTC: CallParticipantUserRTC? { viewModel.activeLargeCall }
    var activeLargeRenderer = RTCMTLVideoView(frame: .zero)

    var body: some View {
        if let userRTC = userRTC {
//            if userRTC.callParticipant.video == true {
////                RTCVideoReperesentable(renderer: activeLargeRenderer)
////                    .ignoresSafeArea()
////                    .onAppear {
////                        userRTC.videoRTC.addVideoRenderer(activeLargeRenderer)
////                    }
//
//                VStack(alignment: .leading, spacing: 0) {
//                    HStack {
//                        Spacer()
//                        Button {
////                            userRTC.videoRTC.removeVideoRenderer(activeLargeRenderer)
////                            self.viewModel.activeLargeCall = nil
//                        } label: {
//                            Image(systemName: "xmark.circle")
//                                .resizable()
//                                .foregroundColor(.primary)
//                        }
//                        .frame(width: 36, height: 36)
//                    }
//                    .padding()
//                    Spacer()
//                }
//            } else {
//                // only audio
//                ImageLaoderView(url: userRTC.callParticipant.participant?.image, userName: userRTC.callParticipant.participant?.username?.uppercased())
//                    .frame(width: isIpad ? 64 : 32, height: isIpad ? 64 : 32)
//                    .cornerRadius(isIpad ? 64 : 32)
//            }
        } else {
            EmptyView()
        }
    }
}
