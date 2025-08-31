//
//  RecordingViewModel.swift
//  ChatApplication
//
//  Created by hamed on 12/4/22.
//

import Combine
import ChatModels
import ChatCore
import Foundation
import SwiftUI
import Chat

public class RecordingViewModel: ObservableObject {
    public var callId: Int?
    public var isRecording: Bool = false
    public var recorder: Participant?
    public var startRecodrdingDate: Date?
    public var recordingTimerString: String?
    public var recordingTimer: Timer?
    public var cancellableSet: Set<AnyCancellable> = []

    public init(callId: Int?) {
        self.callId = callId
    }
    
    public func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.recordingTimerString = self?.startRecodrdingDate?.timerString
                self?.objectWillChange.send()
            }
        }
    }

    public func toggleRecording() {
        guard let callId = callId else { return }
        if isRecording {
            stopRecording(callId)
        } else {
            startRecording(callId)
        }
    }

    public func startRecording(_ callId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.call.startRecording(.init(subjectId: callId))
        }
    }

    public func stopRecording(_ callId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.call.stopRecording(.init(subjectId: callId))
        }
    }

    public func onCallStartRecording(_ response: ChatResponse<Participant>) {
        recorder = response.result
        isRecording = true
        startRecodrdingDate = Date()
        startRecordingTimer()
    }

    public func onCallStopRecording(_: ChatResponse<Participant>) {
        isRecording = false
        recorder = nil
        startRecodrdingDate = nil
    }
}
