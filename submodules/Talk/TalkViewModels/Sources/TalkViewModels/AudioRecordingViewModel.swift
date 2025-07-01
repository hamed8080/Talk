//
//  AudioRecordingViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import AVFoundation
import Chat
import Foundation
import Logger
import TalkModels

@MainActor
protocol AudioRecordingViewModelprotocol: ObservableObject {
    var audioRecorder: AVAudioRecorder { get set }
    var startDate: Date { get set }
    var timerString: String { get set }
    var isRecording: Bool { get }
    var isPermissionGranted: Bool { get }
    var recordingFileName: String { get }
    var recordingOutputBasePath: URL? { get }
    var recordingOutputPath: URL? { get }
    func toggle()
    func start()
    func stop()
    func deleteFile()
    func cancel()
    func requestPermission()
}

@MainActor
public final class AudioRecordingViewModel: AudioRecordingViewModelprotocol {
    public lazy var audioRecorder = AVAudioRecorder()
    public var startDate: Date = .init()
    @Published public var timerString: String = ""
    @Published public var isRecording: Bool = false
    private var timer: Timer?
    public var isPermissionGranted: Bool { AVAudioSession.sharedInstance().recordPermission == .granted }
    public var recordingFileName: String = ""
    public var recordingOutputBasePath: URL? { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first }
    public var recordingOutputPath: URL?
    public weak var threadViewModel: ThreadViewModel?

    public init(){}

    public func toggle() {
        if !isRecording {
            start()
        } else {
            stop()
        }
    }

    public func start() {
        if !isPermissionGranted { requestPermission(); return }
        isRecording = true
        startDate = Date()
        threadViewModel?.sendSignal(.recordVoice)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            Task { @MainActor in
                self.timerString = self.startDate.distance(to: Date()).timerString(locale: Language.preferredLocale) ?? ""
            }
        }
        recordingFileName = "Voice-\(Date().fileDateString).wav"
        recordingOutputPath = recordingOutputBasePath?.appendingPathComponent(recordingFileName)
        guard let url = recordingOutputPath else { return }
        deleteFile()
        do {
            Task { [self] in
                await try activateSession()
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                ]
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder.record()
            }
        } catch {
            stop()
        }
    }
    
    @AppBackgroundActor
    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord)
        try session.setActive(true)
    }
    
    public func stop() {
        isRecording = false
        audioRecorder.stop()
        timer?.invalidate()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    public func cancel() {
        timerString = ""
        isRecording = false
        recordingOutputPath = nil
        stop()
        deleteFile()
    }

    public func deleteFile() {
        if let url = recordingOutputPath {
            try? FileManager.default.removeItem(at: url)
        }
    }

    public func requestPermission() {
        do {
            let recordingSession = AVAudioSession.sharedInstance()
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { @Sendable granted in
                Task { [weak self] in
                    await self?.onPermission(granted: granted)
                }
            }
        } catch {
            Logger.log(title: "ThreadViewModel", message: "Error to get recording permission: \(error.localizedDescription)")
        }
    }

    private func onPermission(granted: Bool) {
        if granted {
            start()
        } else {
            let error = AppErrorTypes.microphone_access_denied
            let chatError = ChatError(code: error.rawValue, hasError: true)
            AppState.shared.animateAndShowError(chatError)
            stop()
        }
    }
}
