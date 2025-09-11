//
//  UserRTCView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import Chat
import TalkUI

struct UserRTCView: View {
    let userRTC: CallParticipantUserRTC
    @EnvironmentObject var viewModel: CallViewModel

    var body: some View {
        ZStack {
            if userRTC.isVideoTrackEnable, let track = userRTC.videoTrack {
                RTCVideoReperesentable(videoTrack: track)
            } else if let participant = userRTC.callParticipant.participant {
                audioOnlyParticipant(participant: participant)
            }
//            muteAndVideoState
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.App.bgSecondary)
        .border(Color.clear, width: userRTC.isSpeaking ? 3 : 0)
        .cornerRadius(8)
        .scaleEffect(x: userRTC.isSpeaking ? 1.02 : 1, y: userRTC.isSpeaking ? 1.02 : 1)
        .animation(.easeInOut, value: userRTC.isSpeaking)
        .overlay(alignment: .bottomTrailing) {
            Text(userRTC.callParticipant.title ?? "")
                .lineLimit(1)
                .foregroundColor(Color.primary)
                .font(Font.fBody)
                .opacity(0.8)
        }
    }
    
    @ViewBuilder
    private func audioOnlyParticipant(participant: Participant) -> some View {
        ImageLoaderView(participant: participant)
            .id("\(participant.image ?? "")\(participant.id ?? 0)")
            .font(.fBoldBody)
            .foregroundColor(.white)
            .frame(width: 96, height: 96)
            .background(Color(uiColor:String.getMaterialColorByCharCode(str: participant.name ?? participant.username ?? "")))
            .clipShape(RoundedRectangle(cornerRadius:(36)))
    }
    
    private var muteAndVideoState: some View {
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
                }
                .padding(.all, isIpad ? 8 : 4)
                .background(.ultraThinMaterial)
                .cornerRadius(4)
            }
            
            Spacer()
        }
    }
    
    private var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
