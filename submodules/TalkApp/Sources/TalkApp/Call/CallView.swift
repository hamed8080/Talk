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
    @State var showDetailPanel: Bool = false
    @State var showCallParticipants: Bool = false

    var body: some View {
        ZStack {
            if viewModel.isCallStarted {
                StartedCallView()
            }
            CenterArriveStickerView()
            if viewModel.isCallStarted == false {
                StartingCallView()
            }
            
            if recordingViewModel.isRecording {
                RecordingDotView()
            }
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
            MoreControlsView(showCallParticipants: $showCallParticipants)
        }
        .sheet(isPresented: $showCallParticipants) {
            CallParticipantListView()
        }
    }
}

struct CallControlsView_Previews: PreviewProvider {
    @State static var showCallParticipants: Bool = false
    @ObservedObject static var viewModel = CallViewModel()
    static var recordingVM = RecordingViewModel(callId: 1)

    static var previews: some View {
        Group {
            CallView()
                .previewDisplayName("CallContent")
            StartingCallView()
                .previewDisplayName("StartingCallView")
            CallControlItem(iconSfSymbolName: "trash", subtitle: "Delete")
                .previewDisplayName("CallControlItem")
            CallStartedActionsView()
                .previewDisplayName("CallStartedActionsView")
            MoreControlsView(showCallParticipants: $showCallParticipants)
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
