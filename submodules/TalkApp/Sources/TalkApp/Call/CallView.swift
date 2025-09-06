//
//  CallView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatDTO
import ChatExtensions
import ChatModels
import SwiftUI
import WebRTC

struct CallView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @Environment(\.localStatusBarStyle) var statusBarStyle: LocalStatusBarStyle
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var recordingViewModel: RecordingViewModel
    @State var showRecordingToast = false
    @State var location: CGPoint = .init(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 164)
    @State var showDetailPanel: Bool = false
    @State var showCallParticipants: Bool = false

    var gridColumns: [GridItem] {
        let videoCount = viewModel.activeUsers.count
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: videoCount <= 2 ? 1 : 2)
    }

    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.location = value.location
            }
    }

    var body: some View {
        ZStack {
            CenterAciveUserRTCView()
            if viewModel.isCallStarted, isIpad {
                listLargeIpadParticipants
                GeometryReader { reader in
                    CallStartedActionsView(showDetailPanel: $showDetailPanel)
                        .position(location)
                        .gesture(
                            simpleDrag.simultaneously(with: simpleDrag)
                        )
                        .onAppear {
                            location = CGPoint(x: reader.size.width / 2, y: reader.size.height - 128)
                        }
                }
            } else if viewModel.isCallStarted {
                VStack {
                    Spacer()
                    listSmallCallParticipants
                    CallStartedActionsView(showDetailPanel: $showDetailPanel)
                }
            }
            CenterArriveStickerView()
            StartCallActionsView()
            RecordingDotView()
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.usersRTC.count)
        .background(Color.App.bgPrimary.ignoresSafeArea())
        .onAppear {
            self.statusBarStyle.currentStyle = .lightContent
        }
        .onDisappear {
            self.statusBarStyle.currentStyle = .default
        }
        .onChange(of: recordingViewModel.recorder) { _ in
            showRecordingToast = recordingViewModel.recorder != nil
        }
        .toast(isShowing: $showRecordingToast,
               title: "The recording call is started.",
               message: "The session is recording by \(recordingViewModel.recorder?.name ?? "").") {
            if let recorder = recordingViewModel.recorder {
//                ImageLaoderView(url: recorder.image, userName: recorder.name ?? recorder.firstName)
//                    .font(.system(size: 16).weight(.heavy))
//                    .foregroundColor(.white)
//                    .frame(width: 48, height: 48)
//                    .background(Color.blue.opacity(0.4))
//                    .cornerRadius(32)
            }
        }
        .onChange(of: viewModel.showCallView) { _ in
            if viewModel.showCallView == false {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .sheet(isPresented: $showDetailPanel) {
            MoreControlsView(showDetailPanel: $showDetailPanel, showCallParticipants: $showCallParticipants)
        }
        .sheet(isPresented: $showCallParticipants) {
            CallParticipantListView()
        }
    }

    @ViewBuilder var listLargeIpadParticipants: some View {
        if viewModel.activeUsers.count <= 2 {
            HStack(spacing: 16) {
                ForEach(viewModel.activeUsers) { userrtc in
                    UserRTCView(userRTC: userrtc)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .padding([.leading, .trailing], 12)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(viewModel.activeUsers) { userrtc in
                        UserRTCView(userRTC: userrtc)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                }
                .padding([.leading, .trailing], 12)
            }
        }
    }

    @ViewBuilder var listSmallCallParticipants: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: [GridItem(.flexible(), spacing: 0)], spacing: 0) {
                ForEach(viewModel.activeUsers) { userrtc in
                    UserRTCView(userRTC: userrtc)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .onTapGesture {
                            viewModel.activeLargeCall = userrtc
                        }
                }
                .padding([.all], isIpad ? 8 : 6)
            }
        }
        .frame(height: viewModel.defaultCellHieght + 25) // +25 for when a user start talking showing frame
    }
    
    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

struct CallControlsView_Previews: PreviewProvider {
    @State static var showDetailPanel: Bool = false
    @State static var showCallParticipants: Bool = false
    @ObservedObject static var viewModel = CallViewModel()
    static var recordingVM = RecordingViewModel(callId: 1)

    static var previews: some View {
        Group {
            CallView()
                .previewDisplayName("CallContent")
            StartCallActionsView()
                .previewDisplayName("StartCallActionsView")
            CallControlItem(iconSfSymbolName: "trash", subtitle: "Delete")
                .previewDisplayName("CallControlItem")
            CallStartedActionsView(showDetailPanel: $showDetailPanel)
                .previewDisplayName("CallStartedActionsView")
            MoreControlsView(showDetailPanel: $showDetailPanel, showCallParticipants: $showCallParticipants)
                .previewDisplayName("MoreControlsView")
        }
        .environmentObject(AppState.shared)
        .environmentObject(viewModel)
        .environmentObject(recordingVM)
        .onAppear {
//            callAllNeededMethodsForPreview()
        }
    }

//    static func callAllNeededMethodsForPreview() {
//        fakeParticipant(count: 5).forEach { callParticipant in
//            viewModel.addCallParicipants([callParticipant])
//        }
//        let participant = MockData.participant(0)
//        let receiveCall = CreateCall(type: .videoCall, creatorId: 0, creator: participant, threadId: 0, callId: 0, group: false)
//        let clientDto = ClientDTO(clientId: "", topicReceive: "", topicSend: "", userId: 0, desc: "", sendKey: "", video: true, mute: false)
//        let chatDataDto = ChatDataDTO(sendMetaData: "", screenShare: "", reciveMetaData: "", turnAddress: "", brokerAddressWeb: "", kurentoAddress: "")
//        let startedCall = StartCall(certificateFile: "", clientDTO: clientDto, chatDataDto: chatDataDto, callName: nil, callImage: nil)
//        viewModel.call = receiveCall
//        ChatManager.call?.preview(startCall: startedCall)
//        viewModel.onCallStarted(startedCall)
//        recordingVM.isRecording = true
//        recordingVM.startRecodrdingDate = Date()
//        recordingVM.startRecordingTimer()
//    }
//
//    static func fakeParticipant(count: Int) -> [CallParticipant] {
//        var participants: [CallParticipant] = []
//        for i in 1 ... count {
//            let participant = MockData.participant(0)
//            participant.name = "Hamed Hosseini \(i) "
//            participants.append(CallParticipant(sendTopic: "TestTopic \(i)", participant: participant))
//        }
//        return participants
//    }
}


