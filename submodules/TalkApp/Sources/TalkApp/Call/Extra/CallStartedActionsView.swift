//
//  CallStartedActionsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import Chat

struct CallStartedActionsView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @Binding var showDetailPanel: Bool

    var body: some View {
        VStack {
            if isIpad {
                Rectangle()
                    .frame(width: 128, height: 5)
                    .foregroundColor(Color.primary)
                    .cornerRadius(5)
                    .offset(y: -36)
            }
            ConnectionStatusToolbar()
            HStack {
                Text(viewModel.callTitle?.uppercased() ?? "")
                    .foregroundColor(.primary)
                    .font(.title3.bold())
                Spacer()
                Text(viewModel.timerCallString ?? "")
                    .foregroundColor(.primary)
                    .font(.title3.bold())
            }
            .fixedSize()
            .padding([.leading, .trailing])

            HStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(CallSticker.allCases, id: \.self) { sticker in
                            Button {
                                viewModel.sendSticker(sticker)
                            } label: {
                                sticker.systemImage
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    }
                }
                .frame(width: 48)

                CallControlItem(iconSfSymbolName: "ellipsis", subtitle: "More", color: .gray) {
                    withAnimation {
                        showDetailPanel.toggle()
                    }
                }
//
//                if let isMute = viewModel.usersRTC.first(where: { $0.isMe })?.callParticipant.mute {
//                    CallControlItem(iconSfSymbolName: isMute ? "mic.slash.fill" : "mic.fill", subtitle: "Mute", color: isMute ? .gray : .green) {
//                        viewModel.toggleMute()
//                    }
//                }
//
//                if let videoEnable = viewModel.activeUsers.first(where: { $0.isMe })?.callParticipant.video {
//                    CallControlItem(iconSfSymbolName: videoEnable ? "video.fill" : "video.slash.fill", subtitle: "Video", color: videoEnable ? .green : .gray) {
//                        viewModel.toggleCamera()
//                    }
//                }

                CallControlItem(iconSfSymbolName: viewModel.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", subtitle: "Speaker", color: viewModel.isSpeakerOn ? .green : .gray) {
                    viewModel.toggleSpeaker()
                }

                CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "End Call", color: .red) {
                    viewModel.endCall()
                }
            }
        }
        .animation(.easeInOut, value: viewModel.timerCallString)
        .padding(isIpad ? [.all] : [.trailing, .leading], isIpad ? 48 : 16)
        .background(controlBackground)
        .cornerRadius(isIpad ? 16 : 0)
    }

    @ViewBuilder var controlBackground: some View {
        if isIpad {
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
        } else {
            Color.clear
        }
    }
    
    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
