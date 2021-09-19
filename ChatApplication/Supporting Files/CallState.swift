//
//  AppState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI
import FanapPodChatSDK
import WebRTC


struct CallStateModel {
    
    private (set) var startCall                    :StartCall?        = nil
    private (set) var showCallView                 :Bool              = false
    private (set) var connectionStatusString       :String            = ""
    private (set) var startCallDate                :Date?             = nil
    private (set) var timerCallString              :String?           = nil
    private (set) var isCallStarted                :Bool              = false
    private (set) var mutedCallParticipants        :[CallParticipant] = []
    private (set) var unmutedCallParticipants      :[CallParticipant] = []
    private (set) var turnOffVideoCallParticipants :[CallParticipant] = []
    private (set) var turnOnVideoCallParticipants  :[CallParticipant] = []
    private (set) var receiveCall                  :CreateCall?       = nil
    private (set) var selectedContacts             :[Contact]         = []
    private (set) var isP2PCalling                 :Bool              = false
    private (set) var isVideoCall                  :Bool              = false
    private (set) var callThreadId                 :Int?              = nil
    private (set) var groupName                    :String?           = nil
    
    mutating func setReceiveCall(_ receiveCall:CreateCall){
        self.receiveCall = receiveCall
        self.isVideoCall = receiveCall.type == .VIDEO_CALL
    }
    
    mutating func setShowCallView(_ showCallView:Bool){
        self.showCallView = showCallView
    }
    
    mutating func setConnectionState(_ stateString:String){
        self.connectionStatusString = stateString
    }
    
    mutating func addTurnOnCallParticipant(_ participants :[CallParticipant]){
        self.turnOnVideoCallParticipants.append(contentsOf: participants)
    }
    
    mutating func addTurnOffCallParticipant(_ participants :[CallParticipant]){
        self.turnOffVideoCallParticipants.append(contentsOf: participants)
    }
    
    mutating func addMuteCallParticipant(_ participants :[CallParticipant]){
        self.mutedCallParticipants.append(contentsOf: participants)
    }
    
    mutating func addUnMuteCallParticipant(_ participants :[CallParticipant]){
        self.unmutedCallParticipants.append(contentsOf: participants)
    }
    
    mutating func setStartDate(){
        self.startCallDate = Date()
    }
    
    mutating func setStartedCall(_ startCall:StartCall){
        self.startCall = startCall
        isCallStarted = true
        setStartDate()
    }
    
    mutating func setTimerString(_ timerString:String?){
        self.timerCallString = timerString
    }
    
    mutating func setIsP2PCalling(_ isP2PCalling:Bool){
        self.isP2PCalling = isP2PCalling
    }
    
    mutating func setSelectedContacts(_ selectedContacts:[Contact]){
        self.selectedContacts.append(contentsOf: selectedContacts)
    }
    
    mutating func setIsVideoCallRequest(_ isVideoCall:Bool){
        self.isVideoCall = isVideoCall
    }
   
    var isReceiveCall:Bool{
        return receiveCall != nil
    }
    
    var titleOfCalling:String{
        if isP2PCalling{
            return selectedContacts.first?.linkedUser?.username ?? "\(selectedContacts.first?.firstName ?? "") \(selectedContacts.first?.lastName ?? "")"
        }else{
            return groupName ?? "Group"
        }
    }
}

class CallState:ObservableObject,WebRTCClientDelegate {
   
    public static  let shared        :CallState         = CallState()
    private static var webrtcClient  :WebRTCClientNew?  = nil
    
    @Published
    var model          :CallStateModel    = CallStateModel()
    
    private (set) var startCallTimer :Timer?            = nil

    
    var localVideoRenderer  :RTCVideoRenderer? = nil
    var remoteVideoRenderer :RTCVideoRenderer? = nil
    
    func setConnectionStatus(_ status:ConnectionStatus){
        model.setConnectionState( status == .CONNECTED ? "" : String(describing: status) + " ...")
    }
    
    var answeredWithVideo = false
    var answeredWithAudio = false

	private init() {
		NotificationCenter.default.addObserver(self, selector: #selector(onReceiveCall(_:)), name: RECEIVE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRejectCall(_:)), name: REJECTED_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallStarted(_:)), name: STARTED_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallEnd(_:)), name: END_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMuteParticipants(_:)), name: MUTE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onUNMuteParticipants(_:)), name: UNMUTE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTurnVideoOnParticipants(_:)), name: TURN_ON_VIDEO_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTurnVideoOffParticipants(_:)), name: TURN_OFF_VIDEO_CALL_NAME_OBJECT, object: nil)
	}
	
	@objc func onReceiveCall(_ notification: NSNotification){
		if let createCall = notification.object as? CreateCall{
            model.setReceiveCall(createCall)
            model.setShowCallView(true)
		}
	}
    
    @objc func onRejectCall(_ notification: NSNotification){
        //don't remove showCallView == true leads to show callViewControls again in receiver of call who rejected call
        if let _ = notification.object as? Call, model.showCallView{
            model.setShowCallView(false)
        }
    }
    
    @objc func onCallStarted(_ notification: NSNotification){
        
        if let startCall = notification.object as? StartCall{
            model.setStartedCall(startCall)
            startTimer()
            
            //Vo - Voice and Vi- Video its hardcoded in all sdks such as:Android-Js,...
            let config =  WebRTCConfig(peerName           : startCall.chatDataDto.kurentoAddress,
                                      iceServers          : ["stun:46.32.6.188:3478","turn:\(startCall.chatDataDto.turnAddress)"],
                                      topicVideoSend      : answeredWithVideo || model.isVideoCall ? "Vi-\(startCall.clientDTO.topicSend)" : nil,
                                      topicVideoReceive   : "Vi-\(startCall.clientDTO.topicReceive)",
                                      topicAudioSend      : "Vo-\(startCall.clientDTO.topicSend)",
                                      topicAudioReceive   : "Vo-\(startCall.clientDTO.topicReceive)",
                                      brokerAddress       : startCall.chatDataDto.brokerAddressWeb,
                                      dataChannel         : false,
                                      customFrameCapturer : false,
                                      userName            : "mkhorrami",
                                      password            : "mkh_123456",
                                      videoConfig         : nil)
            CallState.webrtcClient = WebRTCClientNew(config: config , delegate: self)
            if let renderer = localVideoRenderer {
                CallState.webrtcClient?.startCaptureLocalVideo(renderer: renderer,fileName: model.isReceiveCall ? "webrtc_user_b.mp4" : "webrtc_user_a.mp4")
            }
            
            if let renderer = remoteVideoRenderer {
                CallState.webrtcClient?.renderRemoteVideo(renderer)
            }
        }
    }

    
    @objc func onCallEnd(_ notification: NSNotification){
        if let callId = notification.object as? Int , model.startCall?.callId == callId{
            CallState.webrtcClient?.close()
            resetCall()
        }
    }
    
    @objc func onMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addMuteCallParticipant(callParticipants)
        }
    }
    
    @objc func onUNMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addUnMuteCallParticipant(callParticipants)
        }
    }
    
    @objc func onTurnVideoOnParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addTurnOnCallParticipant(callParticipants)
        }
    }
    
    @objc func onTurnVideoOffParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addTurnOffCallParticipant(callParticipants)
        }
    }
    
    func resetCall(){
        model                   = CallStateModel()
        CallState.webrtcClient  = nil
    }
    
    func setLocalVideoRenderer(_ renderer:RTCVideoRenderer){
        localVideoRenderer  = renderer
    }
    
    func setRemoteVideoRenderer(_ renderer:RTCVideoRenderer){
        remoteVideoRenderer  = renderer
    }
    
    func setSpeaker(_ isOn:Bool){
        CallState.webrtcClient?.setSpeaker(on: isOn)
    }
    
    func setMute(_ isMute:Bool){
        CallState.webrtcClient?.setMute(isMute)
    }
    
    func setCameraIsOn(_ isCameraOn:Bool){
        CallState.webrtcClient?.setCameraIsOn(isCameraOn)
    }
    
    func switchCamera(_ isFront:Bool){
        guard let localVideoRenderer = localVideoRenderer else{return}
        CallState.webrtcClient?.switchCameraPosition(renderer: localVideoRenderer)
    }
    
    func close(){
        CallState.webrtcClient?.close()
    }
    
    func startTimer() {
        startCallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {[weak self] timer in
            DispatchQueue.main.async {
                self?.model.setTimerString(self?.model.startCallDate?.getDurationTimerString())
            }
        }
    }
}

//Implement WebRTCClientDelegate
extension CallState{
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: String) {
        
    }
    
    func didConnectWebRTC() {
        
    }
    
    func didDisconnectWebRTC() {
        
    }
}
