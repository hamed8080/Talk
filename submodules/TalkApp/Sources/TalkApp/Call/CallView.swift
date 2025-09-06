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
}

extension CallView {
    var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
}

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

struct RecordingDotView: View {
    @EnvironmentObject var callState: CallViewModel
    @EnvironmentObject var recordingViewModel: RecordingViewModel
    @State var showRecordingIndicator: Bool = false

    var body: some View {
        if recordingViewModel.isRecording {
            Image(systemName: "record.circle")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color.red)
                .position(x: 32, y: 24)
                .opacity(showRecordingIndicator ? 1 : 0)
                .animation(.easeInOut, value: showRecordingIndicator)
                .onAppear {
//                    Timer.scheduledTimer(withTimeInterval: showRecordingIndicator ? 0.7 : 1, repeats: true) { _ in
//                        showRecordingIndicator.toggle()
//                    }
                }
        } else {
            EmptyView()
        }
    }
}

/// When receive or start call to someone you will see this screen and it will show only if call is not started.
struct StartCallActionsView: View {
    @EnvironmentObject var viewModel: CallViewModel

    var body: some View {
        if viewModel.isCallStarted == false {
            VStack {
                Spacer()
                Text("\(viewModel.callTitle ?? "") \(viewModel.isReceiveCall ? "Ringing..." : "Calling...")")
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    if viewModel.call?.type == .video {
                        Spacer()
                        CallControlItem(iconSfSymbolName: "video.fill", subtitle: "Answer", color: .green) {
                            viewModel.answerCall(video: true, audio: true)
                        }
                    }

                    Spacer()

                    CallControlItem(iconSfSymbolName: "phone.fill", subtitle: "Answer", color: .green) {
                        viewModel.answerCall(video: false, audio: true)
                    }

                    Spacer()

                    CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "Reject Call", color: .red) {
                        viewModel.cancelCall()
                    }
                    Spacer()
                }
            }
        }
    }
}

struct MoreControlsView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @EnvironmentObject var recordingViewModel: RecordingViewModel
    @Binding var showDetailPanel: Bool
    @Binding var showCallParticipants: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    CallControlItem(iconSfSymbolName: "record.circle", subtitle: "Record", color: .red, vertical: true) {
                        recordingViewModel.toggleRecording()
                    }

                    if recordingViewModel.isRecording {
                        Spacer()
                        Text(recordingViewModel.recordingTimerString ?? "")
                            .fontWeight(.medium)
                            .padding([.leading, .trailing], 16)
                            .padding([.top, .bottom], 8)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.thinMaterial)
                            )
                    }
                }

                CallControlItem(iconSfSymbolName: "person.fill.badge.plus", subtitle: "prticipants", color: .gray, vertical: true) {
                    withAnimation {
                        showDetailPanel.toggle()
                        showCallParticipants.toggle()
                    }
                }

                CallControlItem(iconSfSymbolName: "questionmark.app.fill", subtitle: "Update Participants Status", color: .blue, vertical: true) {
                    viewModel.callInquiry()
                }

                Spacer()
            }
            .padding()
            Spacer()
        }
    }
}

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
}

extension CallStartedActionsView {
    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

struct CallControlItem: View {
    var iconSfSymbolName: String
    var subtitle: String
    var color: Color?
    var vertical: Bool = false
    var action: (() -> Void)?
    @State var isActive = false

    var body: some View {
        Button(action: {
            isActive.toggle()
            action?()
        }, label: {
            if vertical {
                HStack {
                    content
                }
            } else {
                VStack {
                    content
                }
            }
        })
//        .buttonStyle(DeepButtonStyle(backgroundColor: Color.clear, shadow: 12))
    }

    @ViewBuilder var content: some View {
        Circle()
            .fill(color ?? .blue)
            .overlay(
                Image(systemName: iconSfSymbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .padding(2)
            )
            .frame(width: 52, height: 52)
        Text(subtitle)
            .fontWeight(.bold)
            .font(.system(size: 10))
            .fixedSize()
    }
}

struct CenterArriveStickerView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @State var animate = false
//    @StateObject var imageLoader = ImageLoader()

    var body: some View {
        if let sticker = viewModel.newSticker {
            HStack(spacing: 4) {
                Text(sticker.participant.name ?? "")
                    .font(.caption2)
//                ImageLaoderView(url: sticker.participant.image, userName: sticker.participant.name)
//                    .frame(width: 28, height: 28)
//                    .cornerRadius(18)
                sticker.sticker.systemImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.yellow)
                    .scaleEffect(x: animate ? 1 : 0.8, y: animate ? 1 : 0.8)
                    .animation(.easeInOut, value: viewModel.newSticker != nil)
                    .transition(.scale)
                    .onAppear {
                        withAnimation(.spring().repeatForever(autoreverses: true)) {
                            animate.toggle()
                        }
                    }
            }
        }
    }
}

struct UserRTCView: View {
    let userRTC: CallParticipantUserRTC
    @EnvironmentObject var viewModel: CallViewModel

    var body: some View {
        if let rendererView = userRTC.renderer as? UIView {
            ZStack {
                if viewModel.isVideoActive(userRTC) {
                    RTCVideoReperesentable(rendererView: rendererView)
                        .frame(width: 300, height: 300)
                        .background(Color.red)
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
}

extension UserRTCView {
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

struct RTCVideoReperesentable: UIViewRepresentable {
    let rendererView: UIView
    
    func makeUIView(context: Context) -> UIView {
        return rendererView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

