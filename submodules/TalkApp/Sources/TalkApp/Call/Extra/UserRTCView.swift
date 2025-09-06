//
//  UserRTCView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import Chat

struct UserRTCView: View {
    let userRTC: CallParticipantUserRTC
    @EnvironmentObject var viewModel: CallViewModel

    var body: some View {
        if let rendererView = userRTC.renderer as? UIView {
            ZStack {
                if userRTC.isVideoTrackEnable {
                    RTCVideoReperesentable(rendererView: rendererView)
                        .frame(width: 300, height: 300)
                        .background(.red)
                } else {
                    // only audio
//                    ImageLaoderView(url: userRTC.callParticipant.participant?.image, userName: userRTC.callParticipant.participant?.username?.uppercased())
//                        .frame(width: isIpad ? 64 : 32, height: isIpad ? 64 : 32)
//                        .cornerRadius(isIpad ? 64 : 32)
                }

                HStack {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: userRTC.callParticipant.mute ? "mic.slash.fill" : "mic.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIpad ? 24 : 16, height: isIpad ? 24 : 16)
                                .foregroundColor(Color.primary)

                            Image(systemName: userRTC.callParticipant.video == true ? "video" : "video.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIpad ? 24 : 16, height: isIpad ? 24 : 16)
                                .foregroundColor(Color.primary)
                            Text(userRTC.callParticipant.title ?? "")
                                .lineLimit(1)
                                .foregroundColor(Color.primary)
                                .font(isIpad ? .body : .caption2)
                                .opacity(0.8)
//                            if userRTC.isMe, userRTC.callParticipant.video == true {
//                                Button {
//                                    viewModel.switchCamera()
//                                } label: {
//                                    Image(systemName: "arrow.triangle.2.circlepath")
//                                        .resizable()
//                                        .scaledToFit()
//                                        .frame(width: isIpad ? 36 : 28, height: isIpad ? 36 : 28)
//                                        .foregroundColor(Color.primary)
//                                }
//                            }
                        }
                        .padding(.all, isIpad ? 8 : 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                    }
                    if isIpad {
                        Spacer()
                    }
                }
            }
            .frame(height: viewModel.defaultCellHieght)
            .background(Color.clear.opacity(0.7))
            .border(Color.clear, width: userRTC.isSpeaking ? 3 : 0)
            .cornerRadius(8)
            .scaleEffect(x: userRTC.isSpeaking ? 1.02 : 1, y: userRTC.isSpeaking ? 1.02 : 1)
            .animation(.easeInOut, value: userRTC.isSpeaking)
        }
    }
    
    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
