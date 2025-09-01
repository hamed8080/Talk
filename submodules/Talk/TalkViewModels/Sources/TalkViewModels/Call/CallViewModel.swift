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

public enum CameraType: String {
    case front
    case back
    case unknown
}

public struct AnswerType {
    let video: Bool
    let mute: Bool
}

@MainActor
public protocol CallStateProtocol {
    var startCallRequest: StartCallRequest? { get set }
    var usersRTC: [CallParticipantUserRTC] { get }
    var cameraType: CameraType { get set }
    var answerType: AnswerType { get set }
    var call: CreateCall? { get set }
    var callId: Int? { get }
    var callTitle: String? { get }
    var isCallStarted: Bool { get }
    var newSticker: StickerResponse? { get set }
    static func joinToCall(_ callId: Int)
    func startCall(thread: Conversation?, contacts: [Contact]?, isVideoOn: Bool, groupName: String)
    func sendSticker(_ sticker: CallSticker)
}

@MainActor
public class CallViewModel: ObservableObject, CallStateProtocol {
    @Published public var startCall: StartCall?
    @Published public var isLoading = false
    @Published public var activeLargeCall: CallParticipantUserRTC?
    @Published public var showCallView: Bool = false
    @Published public var offlineParticipants: [Participant] = []
    @Published public var newSticker: StickerResponse?
    public var startCallDate: Date?
    public var startCallTimer: Timer?
    public var timerCallString: String?
    public var isCallStarted: Bool { startCall != nil }
    public var usersRTC: [CallParticipantUserRTC] {[]} // { ChatManager.activeInstance?.call.callParticipantsUserRTC ?? [] }
    public var activeUsers: [CallParticipantUserRTC] { [] } //usersRTC.filter { $0.callParticipant.active == true } }
    public var call: CreateCall?
    public var callId: Int? { call?.callId ?? 0 }
    public var startCallRequest: StartCallRequest?
    public var answerType: AnswerType = .init(video: false, mute: true)
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
//        guard let callId = callId else { return }
//        isLoading = true
//        ChatManager.call?.activeCallParticipants(.init(subjectId: callId)) { [weak self] response in
//            response.result?.forEach { callParticipant in
//                if let callParticipantUserRTC = self?.usersRTC.first(where: { $0.callParticipant == callParticipant }) {
//                    callParticipantUserRTC.callParticipant.update(callParticipant)
//                }
//            }
//            self?.isLoading = false
//            self?.objectWillChaneWithAnimation()
//        }
    }

    public func getThreadParticipants() {
//        guard let threadId = call?.conversation?.id else { return }
//        isLoading = true
//        ChatManager.activeInstance?.getThreadParticipants(.init(threadId: threadId)) { [weak self] response in
//            response.result?.forEach { participant in
//                let isInAcitveUsers = self?.activeUsers.contains(where: { $0.callParticipant.participant == participant }) ?? false
//                let isInOfflineUsers = self?.offlineParticipants.contains(where: { $0.id == participant.id }) ?? false
//                if !isInAcitveUsers, !isInOfflineUsers {
//                    self?.offlineParticipants.append(participant)
//                }
//            }
//            self?.isLoading = false
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
                onCallStarted(startCall, callId: callId)
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
        default:
            break
        }
    }

    public func onCallCreated(_ createCall: CreateCall?) {
        call = createCall
    }

    public func onReceiveCall(_ createCall: CreateCall?) {
//        toggleCallView(show: true)
//        call = createCall
//        AppState.shared.providerDelegate?.reportIncomingCall(uuid: uuid, handle: createCall?.title ?? "", hasVideo: createCall?.type == .videoCall, completion: nil)
    }

    // maybe reject or canceled after a time out
    public func onCallCanceled(_: Call?) {
        // don't remove showCallView == true leads to show callViewControls again in receiver of call who rejected call
        if showCallView {
            endCallKitCall()
            resetCall()
        }
    }

    public func onCallStarted(_ startCall: StartCall, callId: Int) {
        recordingViewModel = RecordingViewModel(callId: callId)
        self.startCall = startCall
        startCallDate = Date()
        startTimer()
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
//        callParticipants?.forEach { callParticipant in
//            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
//                callParticipantUserRTC.callParticipant.mute = true
//                callParticipantUserRTC.audioRTC.setTrackEnable(false)
//            }
//        }
//        objectWillChaneWithAnimation()
    }

    public func onUNMute(_ callParticipants: [CallParticipant]?) {
//        callParticipants?.forEach { callParticipant in
//            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
//                callParticipantUserRTC.callParticipant.mute = false
//                callParticipantUserRTC.audioRTC.setTrackEnable(true)
//            }
//        }
//        objectWillChaneWithAnimation()
    }

    public func onVideoOn(_ callParticipants: [CallParticipant]?) {
//        callParticipants?.forEach { callParticipant in
//            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
//                callParticipantUserRTC.callParticipant.video = true
//                callParticipantUserRTC.videoRTC.setTrackEnable(true)
//            }
//        }
//        ChatManager.call?.reCalculateActiveVideoSessionLimit()
//        objectWillChaneWithAnimation()
    }

    public func onVideoOff(_ callParticipants: [CallParticipant]?) {
//        callParticipants?.forEach { callParticipant in
//            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
//                callParticipantUserRTC.callParticipant.video = false
//                callParticipantUserRTC.videoRTC.setTrackEnable(false)
//            }
//        }
//        ChatManager.call?.reCalculateActiveVideoSessionLimit()
//        objectWillChaneWithAnimation()
    }

    public func isVideoActive(_ userRTC: CallParticipantUserRTC) -> Bool {
//        userRTC.callParticipant.video == true && userRTC.videoRTC.isVideoTrackEnable
        return false
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
        startCallTimer?.invalidate()
        startCallTimer = nil
        startCallRequest = nil
        endCallKitCall()
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
//        ChatManager.call?.toggleSpeaker()
//        isSpeakerOn.toggle()
    }

    public func toggleMute() {
//        guard let currentUserId = ChatManager.activeInstance?.userInfo?.id, let callId = startCall?.callId else { return }
//        if usersRTC.first(where: { $0.isMe })?.callParticipant.mute == true {
//            ChatManager.call?.unmuteCall(.init(callId: callId, userIds: [currentUserId]))
//        } else {
//            ChatManager.call?.muteCall(.init(callId: callId, userIds: [currentUserId]))
//        }
    }

    public func toggleCamera() {
//        guard let callId = startCall?.callId else { return }
//        if usersRTC.first(where: { $0.isMe })?.callParticipant.video == true {
//            ChatManager.call?.turnOffVideoCall(callId: callId)
//        } else {
//            ChatManager.call?.turnOnVideoCall(callId: callId)
//        }
    }

    public func switchCamera() {
//        ChatManager.call?.switchCamera()
    }

    public func startTimer() {
        startCallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.timerCallString = (self?.startCallDate?.timerString)
                self?.objectWillChaneWithAnimation()
            }
        }
    }

    public func endCallKitCall() {
//        AppState.shared.callMananger.endCall(uuid)
    }

    public func addCallParicipants(_ callParticipants: [CallParticipant]? = nil) {
//        guard let callParticipants = callParticipants else { return }
//        ChatManager.call?.addCallParticipants(callParticipants)
//        objectWillChaneWithAnimation()
    }

    /// You can use this method to reject or cancel a call not startrd yet.
    public func cancelCall() {
//        toggleCallView(show: false)
//        guard let callId = call?.callId,
//              let creatorId = call?.creatorId,
//              let type = call?.type,
//              let isGroup = call?.group else { return }
//        let cancelCall = Call(id: callId, creatorId: creatorId, type: type, isGroup: isGroup)
//        ChatManager.call?.cancelCall(.init(call: cancelCall))
//        endCallKitCall()
    }

    public func endCall() {
        endCallKitCall()
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

    public func answerCall(video: Bool, audio: Bool) {
//        if video {
//            toggleCamera()
//        }
//        answerType = AnswerType(video: video, mute: !audio)
//        AppState.shared.callMananger.callAnsweredFromCusomUI()
    }

    public static func joinToCall(_ callId: Int) {
//        Task { @ChatGlobalActor in
//            ChatManager.activeInstance?.call.acceptCall(.init(callId: callId, client: .init(mute: true, video: false)))
//            CallViewModel.shared.toggleCallView(show: true)
//            CallViewModel.shared.answerType = AnswerType(video: false, mute: true)
//            AppState.shared.callMananger.callAnsweredFromCusomUI()
//        }
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
}
