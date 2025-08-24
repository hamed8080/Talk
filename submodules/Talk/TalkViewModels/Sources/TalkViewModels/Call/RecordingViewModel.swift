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

public protocol RecordingProtocol {
    var callId: Int? { get set }
    var startRecodrdingDate: Date? { get set }
    var recorder: Participant? { get set }
    var isRecording: Bool { get set }
    var recordingTimerString: String? { get set }
    var recordingTimer: Timer? { get set }
    var cancellableSet: Set<AnyCancellable> { get set }
    func onCallStartRecording(_ response: ChatResponse<Participant>)
    func onCallStopRecording(_ response: ChatResponse<Participant>)
    func startRecordingTimer()
    func callEvent(_ notification: NSNotification)
    func toggleRecording()
    func startRecording(_ callId: Int)
    func stopRecording(_ callId: Int)
}

public class RecordingViewModel: ObservableObject, RecordingProtocol {
    public var callId: Int?
    public var isRecording: Bool = false
    public var recorder: Participant?
    public var startRecodrdingDate: Date?
    public var recordingTimerString: String?
    public var recordingTimer: Timer?
    public var cancellableSet: Set<AnyCancellable> = []

    public init(callId: Int?) {
        self.callId = callId
//        NotificationCenter.default.addObserver(self, selector: #selector(callEvent(_:)), name: .callEventName, object: nil)
    }

    @objc public func callEvent(_ notification: NSNotification) {
        guard let type = (notification.object as? CallEventTypes) else { return }
        if case let .startCallRecording(response) = type {
            onCallStartRecording(response)
        } else if case let .stopCallRecording(response) = type {
            onCallStopRecording(response)
        }
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
//        ChatManager.call?.startRecording(.init(subjectId: callId), completion: onCallStartRecording)
    }

    public func stopRecording(_ callId: Int) {
//        ChatManager.call?.stopRecording(.init(subjectId: callId), completion: onCallStopRecording)
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
