//
//  MessageAudioView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import Combine
import AVFoundation

@MainActor
final class MessageAudioView: UIView {
    // Views
    private let fileSizeLabel = UILabel()
    private let timeLabel = UILabel()
    private let waveView = AudioWaveFormView()
    private let fileNameLabel = UILabel()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.textPrimaryUIColor,
                                                      bgColor: Color.App.accentUIColor,
                                                      margin: 2
    )
    private let playbackSpeedButton = UIButton(type: .system)
    private var fileNameHeightConstraint: NSLayoutConstraint?
    
    
    // Models
    private var cancellableSet = Set<AnyCancellable>()
    private weak var viewModel: MessageRowViewModel?
    private var message: HistoryMessageType? { viewModel?.message }
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    private var playbackSpeed: PlaybackSpeed = .one
    
    // Sizes
    private let margin: CGFloat = 6
    private let verticalSpacing: CGFloat = 4
    private let progressButtonSize: CGFloat = 42
    private let playerProgressHeight: CGFloat = 3
    
    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        isOpaque = true
        
        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        progressButton.isUserInteractionEnabled = true
        progressButton.accessibilityIdentifier = "progressButtonMessageAudioView"
        addSubview(progressButton)
        
        waveView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveView)
        
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.font = UIFont.fBoldSubheadline
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileNameLabel.isOpaque = true
        addSubview(fileNameLabel)

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.fBoldCaption
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textSecondaryUIColor?.withAlphaComponent(0.7)
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageAudioView"
        fileSizeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileSizeLabel.isOpaque = true
        addSubview(fileSizeLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = Color.App.textPrimaryUIColor
        timeLabel.font = UIFont.fBoldCaption
        timeLabel.numberOfLines = 1
        timeLabel.textAlignment = .left
        timeLabel.accessibilityIdentifier = "timeLabelMessageAudioView"
        timeLabel.setContentHuggingPriority(.required, for: .vertical)
        timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        timeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        timeLabel.isOpaque = true
        addSubview(timeLabel)
        
        playbackSpeedButton.translatesAutoresizingMaskIntoConstraints = false
        playbackSpeedButton.isUserInteractionEnabled = true
        playbackSpeedButton.accessibilityIdentifier = "playbackSpeedButtonMessageAudioView"
        playbackSpeedButton.tintColor = Color.App.textPrimaryUIColor
        playbackSpeedButton.layer.cornerRadius = 12
        playbackSpeedButton.titleLabel?.font = UIFont.fBoldSubheadline
        playbackSpeedButton.setTitle("", for: .normal)
        playbackSpeedButton.addTarget(self, action: #selector(onPlaybackSpeedTapped), for: .touchUpInside)
        playbackSpeedButton.layer.backgroundColor = Color.App.bgSecondaryUIColor?.withAlphaComponent(0.8).cgColor
        playbackSpeedButton.isHidden = true
        addSubview(playbackSpeedButton)
        
        waveView.onSeek = { [weak self] to in
            self?.audioVM.seek(to)
        }
        fileNameHeightConstraint = fileNameLabel.heightAnchor.constraint(equalToConstant: 42)
        fileNameHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.heightAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            
            fileNameLabel.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: margin * 2),
            fileNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin * 2),
            fileNameLabel.topAnchor.constraint(equalTo: progressButton.topAnchor),
            
            waveView.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: margin * 2),
            waveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin * 2),
            waveView.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor),
            waveView.heightAnchor.constraint(equalToConstant: 42),
            
            fileSizeLabel.leadingAnchor.constraint(equalTo: waveView.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: waveView.bottomAnchor, constant: margin),
            fileSizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            timeLabel.leadingAnchor.constraint(equalTo: fileSizeLabel.trailingAnchor, constant: margin),
            timeLabel.topAnchor.constraint(equalTo: fileSizeLabel.topAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            timeLabel.bottomAnchor.constraint(equalTo: fileSizeLabel.bottomAnchor),
            
            playbackSpeedButton.widthAnchor.constraint(equalToConstant: 52),
            playbackSpeedButton.heightAnchor.constraint(equalToConstant: 28),
            playbackSpeedButton.topAnchor.constraint(equalTo: fileSizeLabel.topAnchor, constant: -4),
            playbackSpeedButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
        ])
        
        if isMe {
            playbackSpeedButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin).isActive = true
        } else {
            playbackSpeedButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin).isActive = true
        }
        registerObservers()
    }
    
    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        setAudioDurationAndWaveform()
        updateProgress(viewModel: viewModel)
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileNameLabel.isHidden = viewModel.message.type == .voice || viewModel.message.type == .podSpaceVoice
        fileNameHeightConstraint?.constant = fileNameLabel.isHidden ? 0 : 42
        waveView.setImage(to: viewModel.calMessage.waveForm)
        timeLabel.text = audioTimerString()
    }
    
    @objc private func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
        if isSameFile {
            if let viewModel = viewModel {
                updateProgress(viewModel: viewModel)
            }
        }
    }
    
    @objc private func onPlaybackSpeedTapped(_ sender: UIGestureRecognizer) {
        playbackSpeed = playbackSpeed.increase()
        playbackSpeedButton.setTitle(playbackSpeed.string(), for: .normal)
        audioVM.setPlayback(playbackSpeed.rawValue)
    }
    
    private func onPlayingStateChanged(_ isPlaying: Bool) {
        guard isSameFile else { return }
        let image = isPlaying ? "pause.fill" : "play.fill"
        progressButton.animate(to: 1.0, systemIconName: image)
        progressButton.setProgressVisibility(visible: false)
        playbackSpeedButton.setTitle(playbackSpeed.string(), for: .normal)
        playbackSpeedButton.isHidden = !isPlaying
    }
    
    private func onTimeChanged() {
        guard isSameFile else { return }
        waveView.setPlaybackProgress(progress)
        self.timeLabel.text = audioTimerString()
    }
    
    private func onClosed(_ closed: Bool) {
        if closed, isSameFile {}
    }
    
    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.fileState.progress
        let icon = viewModel.fileState.iconState
        let canShowDownloadUpload = viewModel.fileState.state != .completed
        progressButton.animate(to: progress, systemIconName: canShowDownloadUpload ? icon : playingIcon)
        progressButton.setProgressVisibility(visible: canShowProgress)
    }
    
    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isAudio { return }
        updateProgress(viewModel: viewModel)
        calculateWaveform(viewModel: viewModel)
        setAudioDurationAndWaveform()
    }
    
    private func calculateWaveform(viewModel: MessageRowViewModel) {
        if viewModel.calMessage.waveForm == nil {
            Task {
                await viewModel.recalculate(mainData: viewModel.getMainData())
                waveView.setImage(to: viewModel.calMessage.waveForm)
            }
        }
    }
    
    public func uploadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isAudio { return }
        updateProgress(viewModel: viewModel)
        setAudioDurationAndWaveform()
    }
    
    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }
    
    var isSameFile: Bool {
        if audioVM.fileURL == nil { return true } // It means it has never played a audio.
        if isSameFileConverted { return true }
        let furl = viewModel?.calMessage.fileURL
        return furl != nil && audioVM.fileURL?.absoluteString == furl?.absoluteString
    }
    
    var isSameFileConverted: Bool {
        message?.convertedFileURL != nil && audioVM.fileURL?.absoluteString == message?.convertedFileURL?.absoluteString
    }
    
    var progress: CGFloat {
        isSameFile ? min(audioVM.currentTime / audioVM.duration, 1.0) : 0
    }
    
    func registerObservers() {
        audioVM.$currentTime.sink { [weak self] time in
            self?.onTimeChanged()
        }
        .store(in: &cancellableSet)
        
        audioVM.$isPlaying.sink { [weak self] isPlaying in
            self?.onPlayingStateChanged(isPlaying)
        }
        .store(in: &cancellableSet)
        
        audioVM.$isClosed.sink { [weak self] closed in
            self?.onClosed(closed)
        }
        .store(in: &cancellableSet)
    }
    
    private func audioTimerString() -> String {
        let duration = (viewModel?.calMessage.voiceDuration ?? 0).timerString(locale: Language.preferredLocale) ?? " "
        let currentTime = audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? " "
        return isSameFile ? "\(currentTime) / \(duration)" : " "
    }
    
    var playingIcon: String {
        if !isSameFile { return "play.fill" }
        return audioVM.isPlaying ? "pause.fill" : "play.fill"
    }
    
    private func setAudioDurationAndWaveform() {
        guard let fileURL = viewModel?.calMessage.fileURL,
              let message = viewModel?.message,
              let url = AudioFileURLCalculator(fileURL: fileURL, message: message).audioURL() else { return }
        setAudioDuration(url: url)
        createWaveform(url: url, message: message)
    }
    
    private func setAudioDuration(url: URL) {
        viewModel?.calMessage.voiceDuration = voiceDuration(url)
        timeLabel.text = audioTimerString()
    }
    
    private func createWaveform(url: URL, message: HistoryMessageType) {
        if viewModel?.calMessage.waveForm != nil { return }
        Task { [weak self] in
            let waveImage = try? await WaveformGenerator(url: url).generate()
            await self?.viewModel?.calMessage.waveForm = waveImage
            
            /// Update the UI after creating the wave view and calculating the voice duration
            if let viewModel = await self?.viewModel {
                self?.waveView.setImage(to: viewModel.calMessage.waveForm)
            }
        }
    }
    
    private func voiceDuration(_ fileURL: URL) -> Double {
        let asset = AVAsset(url: fileURL)
        return Double(CMTimeGetSeconds(asset.duration))
    }
}

enum PlaybackSpeed: Float {
    case one = 1.0
    case oneAndHalf = 1.5
    case twice = 2.0
    
    func increase() -> PlaybackSpeed {
        switch self {
        case .one:
            return .oneAndHalf
        case .oneAndHalf:
            return .twice
        case .twice:
            return .one
        }
    }
    
    func string() -> String {
        switch self {
        case .one:
            "x1"
        case .oneAndHalf:
            "x1.5"
        case .twice:
            "x2"
        }
    }
}
