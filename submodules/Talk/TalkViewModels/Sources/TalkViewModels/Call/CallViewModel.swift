//
//  CallViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Combine
import Chat
import SwiftUI
import ChatDTO
import Additive
import TalkModels
import WebRTC

public enum CameraType: String {
    case front
    case back
    case unknown
}

public class CallTimerViewModel: ObservableObject {
    public var startCallTimer: Timer?
    public var startCallDate: Date?
    @Published public var timerCallString: String?
    
    public func startTimer() {
        startCallDate = Date()
        startCallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.timerCallString = (self?.startCallDate?.timerString)
            }
        }
    }
    
    public func reset() {
        startCallTimer?.invalidate()
        startCallTimer = nil
    }
}

@MainActor
public class CallViewModel: ObservableObject {
    @Published public var startCall: StartCall?
    @Published public var isLoading = false
    @Published public var activeLargeCall: CallParticipantUserRTC?
    @Published public var showCallView: Bool = false
    @Published public var offlineParticipants: [Participant] = []
    @Published public var newSticker: StickerResponse?
    @Published public var raiseHand = false
    public var timerViewModel = CallTimerViewModel()
    
    public var isCallStarted: Bool { startCall != nil }
    public var usersRTC: [CallParticipantUserRTC] {[]}
    public var activeUsers: [CallParticipantUserRTC] = []
    public var call: CreateCall?
    public var callId: Int? { call?.callId ?? 0 }
    public var startCallRequest: StartCallRequest?
    public var isSpeakerOn: Bool = false
    public var cameraType: CameraType = .unknown
    public var cancellableSet: Set<AnyCancellable> = []
    public var isReceiveCall: Bool { call?.creator.id != AppState.shared.user?.id }
    public var callTitle: String? { isReceiveCall ? call?.title : startCallRequest?.titleOfCalling }
    public var recordingViewModel = RecordingViewModel(callId: 0)

    public init() {
        NotificationCenter.call.publisher(for: .call)
            .compactMap { $0.object as? CallEventTypes }
            .sink { [weak self] event in
                Task { @MainActor in
                    await self?.onCallEvent(event)
                }
            }
            .store(in: &cancellableSet)
        
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
    }

    public func startCall(thread: Conversation? = nil, contacts: [Contact]? = nil, isVideoOn: Bool, groupName: String = "group") {
        startCallRequest = .init(client: .init(video: isVideoOn), contacts: contacts, thread: thread, type: isVideoOn ? .video : .voice, groupName: groupName)
        guard let req = startCallRequest else { return }
        toggleCallView(show: true)
        Task { @ChatGlobalActor in
            if req.isGroupCall {
                ChatManager.activeInstance?.call.requestGroupCall(req)
            } else {
                ChatManager.activeInstance?.call.requestCall(req)
            }
        }
    }

    public func recall(_ participant: Participant?) {
//        guard let participant = participant, let callId = callId, let coreUserId = participant.coreUserId else { return }
//        ChatManager.call?.renewCallRequest(.init(invitees: [.init(id: "\(coreUserId)", idType: .coreUserId)], callId: callId)) { _ in }
    }

    public func getParticipants() {
        getActiveParticipants()
        getThreadParticipants()
    }

    public func getActiveParticipants() {
        guard let callId = callId else { return }
        isLoading = true
        Task {
            do {
                let callParticipants = try await GetActiveCallParticipantsRequester().get(callId)
                for i in activeUsers.indices {
                    if let participant = callParticipants.first(where: { $0.userId == activeUsers[i].callParticipant.userId })?.participant {
                        activeUsers[i].callParticipant.participant = participant
                    }
                }
                objectWillChaneWithAnimation()
            } catch {
                print("Failed to get active call participants")
            }
        }
    }

    public func getThreadParticipants() {
        guard let threadId = call?.conversation?.id else { return }
        isLoading = true
//        Task { @ChatGlobalActor in
//            ChatManager.activeInstance?.conversation.participant.get(.init(threadId: threadId, offset: 0, count: 50))
//        }
    }

    // Create call don't mean the call realy started. CallStarted Event is real one when a call realy accepted by at least one participant.
    private func initCreateCall(_ response: ChatResponse<CreateCall>) {
        call = response.result
    }

    public func toggleCallView(show: Bool) {
        showCallView = show
        objectWillChange.send()
    }

    public func onConnectionStatusChanged(_ status: ConnectionStatus) {
//        if startCall != nil, status == .connected {
//            callInquiry()
//        }
    }

    public func onCallEvent(_ event: CallEventTypes) {
        switch event {
        case let .callStarted(response):
            if let startCall = response.result, let callId = response.subjectId {
                Task { @ChatGlobalActor in
                    let callParticipants = await ChatManager.activeInstance?.call.currentUserRTCList(callId: callId) ?? []
                    await onCallStarted(startCall, callId, callParticipants)
                }
                getParticipants()
            }
        case let .callCreate(response):
            onCallCreated(response.result)
        case let .callReceived(response):
            onReceiveCall(response.result)
        case .callDelivered:
            break
        case let .callEnded(response):
            onCallEnd(response?.result ?? 0)
        case let .groupCallCanceled(response):
            if response.result?.participant?.id == AppState.shared.user?.id {
                onCallEnd(response.result?.callId)
            }
        case let .callCanceled(response):
            onCallCanceled(response.result)
        case .callRejected:
            break
        case let .callParticipantJoined(response):
            onCallParticipantJoined(response.result)
        case let .callParticipantLeft(response):
            onCallParticipantLeft(response.result)
        case let .callParticipantMute(response):
            onMute(response.result)
        case let .callParticipantUnmute(response):
            onUNMute(response.result)
        case .callParticipantsRemoved:
            break
        case let .turnVideoOn(response):
            onVideoOn(response.result)
        case let .turnVideoOff(response):
            onVideoOff(response.result)
//        case .callClientError:
//            break
        case .callParticipantStartSpeaking:
            objectWillChaneWithAnimation()
        case .callParticipantStopSpeaking:
            objectWillChaneWithAnimation()
        case let .sticker(response):
            onCallSticker(response.result)
        case let .maxVideoSessionLimit(response):
            onMaxVideoSessionLimit(response.result)
        case let .startCallRecording(response):
            recordingViewModel.onCallStartRecording(response)
        case let .stopCallRecording(response):
            recordingViewModel.onCallStopRecording(response)
        case let .videoTrackAdded(track, clientId):
            onVideoTrackAdded(track, clientId)
        case let .audioTrackAdded(track, clientId):
            onAudioTrackAdded(track, clientId)
        default:
            break
        }
    }

    public func onCallCreated(_ createCall: CreateCall?) {
        call = createCall
        toggleCallView(show: true)
    }

    public func onReceiveCall(_ createCall: CreateCall?) {
        call = createCall
        toggleCallView(show: true)
    }

    // maybe reject or canceled after a time out
    public func onCallCanceled(_: Call?) {
        // don't remove showCallView == true leads to show callViewControls again in receiver of call who rejected call
        if showCallView {
            resetCall()
        }
    }

    public func onCallStarted(_ startCall: StartCall, _ callId: Int, _ callParticipants: [CallParticipantUserRTC]) async {        
        self.activeUsers = callParticipants
        recordingViewModel = RecordingViewModel(callId: callId)
        self.startCall = startCall
        timerViewModel.startTimer()
        fetchCallParticipants(startCall)
        
        objectWillChaneWithAnimation()
    }

    public func fetchCallParticipants(_ startCall: StartCall?) {
//        guard let callId = startCall?.callId else { return }
//        ChatManager.call?.activeCallParticipants(.init(subjectId: callId)) { [weak self] response in
//            response.result?.forEach { callParticipant in
//                if let callParticipantUserRTC = self?.usersRTC.first(where: { $0.callParticipant == callParticipant }) {
//                    callParticipantUserRTC.callParticipant.update(callParticipant)
//                }
//            }
//            self?.objectWillChaneWithAnimation()
//        }
    }

    public func callInquiry() {
//        guard let callId = startCall?.callId else { return }
//        ChatManager.call?.callInquery(.init(subjectId: callId)) { [weak self] response in
//            response.result?.forEach { callParticipant in
//                if let callParticipantUserRTC = self?.usersRTC.first(where: { $0.callParticipant == callParticipant }) {
//                    callParticipantUserRTC.callParticipant.update(callParticipant)
//                }
//            }
//            self?.objectWillChaneWithAnimation()
//        }
    }

    public func onCallEnd(_: Int?) {
        resetCall()
    }

    /// Setup UI and WEBRCT for new participant joined to the call
    public func onCallParticipantLeft(_ callParticipants: [CallParticipant]?) {
//        callParticipants?.forEach { callParticipant in
//            if let participant = callParticipant.participant {
//                offlineParticipants.append(participant)
//            }
//        }
//        ChatManager.call?.reCalculateActiveVideoSessionLimit()
//        objectWillChaneWithAnimation()
    }

    public func onMute(_ callParticipants: [CallParticipant]?) {
        syncUserRTCs()
    }

    public func onUNMute(_ callParticipants: [CallParticipant]?) {
        syncUserRTCs()
    }

    public func onVideoOn(_ callParticipants: [CallParticipant]?) {
        syncUserRTCs()
    }

    public func onVideoOff(_ callParticipants: [CallParticipant]?) {
        syncUserRTCs()
    }
    
    private func syncUserRTCs() {
        guard let callId = callId else { return }
        let copy = activeUsers
        Task { @ChatGlobalActor in
            /// Sync Chat SDK instances with itself
            let chatSDKInstances = ChatManager.activeInstance?.call.currentUserRTCList(callId: callId) ?? []
            await MainActor.run {
                activeUsers = chatSDKInstances
                
                /// We will do this to prevent deleting the participant inside the CallParticipantUserRTC.callParticipnat.participant
                /// beacuse once session is created this property is nil by the server,
                /// the client app will fetch it later with 110 and the keep those in this.
                for i in activeUsers.indices {
                    let oldRTC = copy.first(where: { $0.callParticipant.userId == activeUsers[i].callParticipant.userId })
                    
                    if let participant = oldRTC?.callParticipant.participant {
                        activeUsers[i].callParticipant.participant = participant
                    }
                }
                
                objectWillChaneWithAnimation()
            }
        }
    }

    public func onMaxVideoSessionLimit(_ callParticipant: CallParticipant?) {
        if callParticipant != nil {
            objectWillChaneWithAnimation()
        }
    }

    public func onCallParticipantJoined(_ callParticipants: [CallParticipant]?) {
        callParticipants?.forEach { callParticipant in
            offlineParticipants.removeAll(where: { $0.id == callParticipant.userId })
        }
        addCallParicipants(callParticipants)
        objectWillChaneWithAnimation()
    }

    public func objectWillChaneWithAnimation() {
        withAnimation {
            objectWillChange.send()
        }
    }

    public func resetCall() {
        call = nil
        startCall = nil
        toggleCallView(show: false)
        timerViewModel.reset()
        startCallRequest = nil
        activeUsers = []
        printCallLogsFile()
    }

    public func printCallLogsFile() {
        if let appSupportDir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let logFileDir = "WEBRTC-LOG"
            let url = appSupportDir.appendingPathComponent(logFileDir)
            DispatchQueue.global(qos: .background).async {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                let dateString = df.string(from: Date())
                FileManager.default.zipFile(urlPathToZip: url, zipName: "WEBRTC-Logs-\(dateString)") { zipFile in
                    if let zipFile = zipFile {
                        DispatchQueue.main.async {
                            AppState.shared.callLogs = [zipFile]
                        }
                    }
                }
            }
        }
    }

    public func toggleSpeaker() {
        guard let callId = callId else { return }
        let on = isSpeakerOn ? false : true
        Task { @ChatGlobalActor in
            await ChatManager.activeInstance?.call.setSpeaker(on: on, callId: callId)
            await MainActor.run {
                isSpeakerOn.toggle()
            }
        }
    }

    public func toggleMute() {
        guard
            let mute = myUserRTC?.callParticipant.mute,
            let callId = callId,
            let userId = myUserRTC?.callParticipant.userId
        else { return }
        Task { @ChatGlobalActor in
            if mute {
                ChatManager.activeInstance?.call.unmuteCallParticipants(.init(callId: callId, userIds: [userId]))
            } else {
                ChatManager.activeInstance?.call.muteCallParticipants(.init(callId: callId, userIds: [userId]))
            }
        }
    }

    public func setCamera(on: Bool) {
        guard let callId = callId else { return }
        Task { @ChatGlobalActor in
            if on {
                ChatManager.activeInstance?.call.turnOnVideoCall(.init(subjectId: callId))
            } else {
                ChatManager.activeInstance?.call.turnOffVideoCall(.init(subjectId: callId))
            }
        }
    }

    public func switchCamera() {
//        ChatManager.call?.switchCamera()
    }

    public func addCallParicipants(_ callParticipants: [CallParticipant]? = nil) {
//        guard let callParticipants = callParticipants else { return }
//        ChatManager.call?.addCallParticipants(callParticipants)
//        objectWillChaneWithAnimation()
    }

    /// You can use this method to reject or cancel a call not startrd yet.
    public func cancelCall() {
        toggleCallView(show: false)
        guard let callId = call?.callId,
              let creatorId = call?.creatorId,
              let type = call?.type,
              let isGroup = call?.group else { return }
        let cancelCall = Call(id: callId, creatorId: creatorId, type: type, isGroup: isGroup)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.call.cancelCall(.init(call: cancelCall))
        }
    }

    public func endCall() {
        if isCallStarted == false {
            cancelCall()
        } else {
            // TODO: realease microphone and camera at the moument and dont need to wait and get response from server
            if let callId = callId {
                Task { @ChatGlobalActor in
                    ChatManager.activeInstance?.call.endCall(.init(subjectId: callId))
                }
            }
        }
        resetCall()
    }

    public func answerCall(video: Bool, mute: Bool) {
        guard let callId = callId else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.call.acceptCall(
                AcceptCallRequest(
                    callId: callId,
                    client: SendClient(
                        id: nil,
                        type: .ios,
                        deviceId: nil,
                        mute: mute,
                        video: video,
                        desc: nil
                    )
                )
            )
        }
    }

    public static func joinToCall(_ callId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.call.acceptCall(.init(callId: callId, client: .init(mute: true, video: false)))
        }
    }

    public func sendSticker(_ sticker: CallSticker) {
        guard let callId = callId else { return }
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.call.sendCallSticker(.init(callId: callId, stickers: [sticker]))
        }
    }

    public func onCallSticker(_ sticker: StickerResponse?) {
        if sticker?.participant.id != AppState.shared.user?.id {
            Task {
                newSticker = sticker
                try? await Task.sleep(for: .seconds(3))
                newSticker = nil
            }
        }
    }
    
    public func onVideoTrackAdded(_ track: RTCVideoTrack, _ clientId: Int) {
        syncUserRTCs()
    }
    
    public func onAudioTrackAdded(_ track: RTCAudioTrack, _ clientId: Int) {
        syncUserRTCs()
    }
    
    public func openConversation() {
        guard let conversation = call?.conversation else { return }
        AppState.shared.objectsContainer.navVM.append(thread: conversation)
    }
    
    public func toggleRaiseHand() {
        let raiseHand = raiseHand
        if !raiseHand {
            /// we are going to raise our hand
            /// Play sound
            
        }
        guard let callId = callId else { return }
        let req = GeneralSubjectIdRequest(subjectId: callId)
        Task { @ChatGlobalActor in
            if raiseHand {
                ChatManager.activeInstance?.call.lowerHand(req)
            } else {
                ChatManager.activeInstance?.call.raiseHand(req)
            }
            await MainActor.run {
                self.raiseHand.toggle()
            }
        }
    }
    
    public func addToCallContacts(_ contacts: [Contact]) {
        guard let callId = callId else { return }
        let req = AddCallParticipantsRequest(callId: callId, contactIds: contacts.compactMap({$0.id}))
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.call.addCallPartcipant(req)
        }
    }
}

/// Size of the each cell in different size like iPad vs iPhone.
public extension CallViewModel {
    var defaultCellHieght: CGFloat {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let isMoreThanTwoParticipant = usersRTC.count > 2
        let ipadHieghtForTwoParticipant = (UIScreen.main.bounds.height / 2) - 32
        let ipadSize = isMoreThanTwoParticipant ? 350 : ipadHieghtForTwoParticipant
        return isIpad ? ipadSize : 150
    }
    
    public var myUserRTC: CallParticipantUserRTC? {
        activeUsers.first(where: { $0.callParticipant.userId == AppState.shared.user?.id })
    }
}
