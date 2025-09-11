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
    @State private var showStickerListView = false
    @State private var showAddParticipantSheet = false

    var body: some View {
        VStack {
            if showStickerListView {
                stickerLists
            } else {
                normalButtons
            }
        }
        .padding(isIpad ? [.all] : [.trailing, .leading], isIpad ? 48 : 16)
        .background(controlBackground)
        .cornerRadius(isIpad ? 16 : 0)
    }
    
    @ViewBuilder
    private var normalButtons: some View {
        HStack(spacing: 16) {
            Menu {
                Button(action: openConversation) {
                    HStack {
                        Text("شروع گفتگو")
                        Image(systemName: "message")
                        Spacer()
                    }
                }
                Button(action: record) {
                    HStack {
                        Text("ضبط جلسه")
                        Image(systemName: "record.circle")
                        Spacer()
                    }
                }
                Button(action: shareScreen) {
                    HStack {
                        Text("اشتراک صفحه نمایش")
                        Image(systemName: "display")
                        Spacer()
                    }
                }
                Button(action: addCallParticipant) {
                    HStack {
                        Text("افزودن عضو به تماس")
                        Image(systemName: "person.badge.plus")
                        Spacer()
                    }
                }
                Button(action: showStickersList) {
                    HStack {
                        Text("ارسال استیکر")
                        Image(systemName: "face.smiling")
                        Spacer()
                    }
                }
                Button(action: raiseHand) {
                    HStack {
                        Text("بالا بردن دست")
                        Image(systemName: "hand.raised")
                        Spacer()
                    }
                }
            } label: {
                CallControlItem(iconSfSymbolName: "ellipsis", subtitle: "", color: .gray) {
                    
                }
            }

            let isMute = viewModel.myUserRTC?.audioTrack?.isEnabled == true
            CallControlItem(iconSfSymbolName: isMute ? "mic.slash" : "mic", subtitle: "", color: isMute ? .green : .gray) {
                viewModel.toggleMute()
            }
            
            let isCameraOn = viewModel.myUserRTC?.isVideoTrackEnable == true
            CallControlItem(iconSfSymbolName: isCameraOn ? "video.fill" : "video.slash.fill", subtitle: "", color: isCameraOn ? .green : .gray) {
                viewModel.setCamera(on: isCameraOn ? false : true)
            }

            CallControlItem(iconSfSymbolName: viewModel.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", subtitle: "", color: viewModel.isSpeakerOn ? .green : .gray) {
                viewModel.toggleSpeaker()
            }

            CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "", color: .red) {
                viewModel.endCall()
            }
        }
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
            CallTimerView()
                .environmentObject(viewModel.timerViewModel)
        }
        .fixedSize()
        .padding([.leading, .trailing])
        .sheet(isPresented: $showAddParticipantSheet) {
            AddParticipantsToThreadView() { contacts in
                viewModel.addToCallContacts(Array(contacts))
                showAddParticipantSheet = false
            }
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        }
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
    
    private var stickerLists: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(CallSticker.allCases, id: \.self) { sticker in
                    Button {
                        showStickerListView = false
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
    }
    
    private var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private func openConversation() {
        viewModel.openConversation()
    }
    
    private func record() {
        viewModel.recordingViewModel.toggleRecording()
    }
    
    private func shareScreen() {
        
    }
    
    private func addCallParticipant() {
        showAddParticipantSheet = true
    }
    
    private func showStickersList() {
        showStickerListView.toggle()
    }
    
    private func raiseHand() {
        viewModel.toggleRaiseHand()
    }
}

struct CallTimerView: View {
    @EnvironmentObject var viewModel: CallTimerViewModel
    
    var body: some View {
        Text(viewModel.timerCallString ?? "")
            .foregroundColor(.primary)
            .font(.title3.bold())
            .animation(.easeInOut, value: viewModel.timerCallString)
    }
}
