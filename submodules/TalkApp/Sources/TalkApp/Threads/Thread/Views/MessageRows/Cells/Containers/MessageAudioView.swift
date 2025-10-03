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
        playbackSpeedButton.layer.cornerRadius = MessageRowSizes.messageAudioViewPlayButtonCornerRadius
        playbackSpeedButton.titleLabel?.font = UIFont.fBoldSubheadline
        playbackSpeedButton.setTitle("", for: .normal)
        playbackSpeedButton.addTarget(self, action: #selector(onPlaybackSpeedTapped), for: .touchUpInside)
        playbackSpeedButton.layer.backgroundColor = Color.App.bgSecondaryUIColor?.withAlphaComponent(0.8).cgColor
        playbackSpeedButton.isHidden = true
        addSubview(playbackSpeedButton)
        
        waveView.onSeek = { [weak self] to in
            guard let self = self else { return }
            viewModel?.calMessage.avPlayerItem?.currentTime = to * (viewModel?.calMessage.avPlayerItem?.duration ?? 0)
            if audioVM.item?.messageId == viewModel?.calMessage.avPlayerItem?.messageId {
                audioVM.seek(to)
            }
        }
        fileNameHeightConstraint = fileNameLabel.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageAudioViewFileNameHeight)
        fileNameHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: MessageRowSizes.messageAudioViewProgressButtonSize),
            progressButton.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageAudioViewProgressButtonSize),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MessageRowSizes.messageAudioViewMargin),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: MessageRowSizes.messageAudioViewMargin),
            
            fileNameLabel.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: MessageRowSizes.messageAudioViewMargin * 2),
            fileNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MessageRowSizes.messageAudioViewMargin * 2),
            fileNameLabel.topAnchor.constraint(equalTo: progressButton.topAnchor),
            
            waveView.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: MessageRowSizes.messageAudioViewMargin * 2),
            waveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MessageRowSizes.messageAudioViewMargin * 2),
            waveView.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor),
            waveView.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageAudioViewFileNameHeight),
            
            fileSizeLabel.leadingAnchor.constraint(equalTo: waveView.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: waveView.bottomAnchor, constant: MessageRowSizes.messageAudioViewMargin),
            fileSizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            fileSizeLabel.widthAnchor.constraint(equalToConstant: MessageRowSizes.messageAudioViewFileNameWidth),
            
            timeLabel.leadingAnchor.constraint(equalTo: fileSizeLabel.trailingAnchor, constant: MessageRowSizes.messageAudioViewMargin),
            timeLabel.topAnchor.constraint(equalTo: fileSizeLabel.topAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor, constant: 0),
            timeLabel.bottomAnchor.constraint(equalTo: fileSizeLabel.bottomAnchor),
            
            playbackSpeedButton.widthAnchor.constraint(equalToConstant: MessageRowSizes.messageAudioViewPlaybackSpeedWidth),
            playbackSpeedButton.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageAudioViewPlaybackSpeedHeight),
            playbackSpeedButton.topAnchor.constraint(equalTo: fileSizeLabel.topAnchor, constant: -MessageRowSizes.messageAudioViewPlaybackSpeedTopMargin),
            playbackSpeedButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -MessageRowSizes.messageAudioViewMargin),
        ])
        
        if isMe {
            playbackSpeedButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MessageRowSizes.messageAudioViewMargin).isActive = true
        } else {
            playbackSpeedButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MessageRowSizes.messageAudioViewMargin).isActive = true
        }
    }
    
    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        updateProgress(viewModel: viewModel)
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileNameLabel.isHidden = viewModel.message.type == .voice || viewModel.message.type == .podSpaceVoice
        fileNameHeightConstraint?.constant = fileNameLabel.isHidden ? 0 : MessageRowSizes.messageAudioViewFileNameHeight
        waveView.setPlaybackProgress(Double(viewModel.calMessage.avPlayerItem?.progress ?? 0.0))
        waveView.setImage(to: viewModel.calMessage.avPlayerItem?.waveFormImage)
        timeLabel.text = viewModel.calMessage.avPlayerItem?.audioTimerString()
        
        /// If the user started the music/voice from the tabs inside the thread info.
        if audioVM.item?.uniqueId != viewModel.calMessage.avPlayerItem?.uniqueId, audioVM.item?.messageId == viewModel.calMessage.avPlayerItem?.messageId {
            unregisterObservers()
            viewModel.calMessage.avPlayerItem = audioVM.item
            waveView.setPlaybackProgress(Double(viewModel.calMessage.avPlayerItem?.progress ?? 0.0))
            registerObservers()
        } else {
            unregisterObservers()
            registerObservers()
        }
        Task { [weak self] in
            guard let self = self else { return }
            await updateArtwork()
            await setAudioDurationAndWaveform()
        }
    }
    
    @objc private func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
        if let viewModel = viewModel {
            updateProgress(viewModel: viewModel)
        }
    }
    
    @objc private func onPlaybackSpeedTapped(_ sender: UIGestureRecognizer) {
        playbackSpeed = playbackSpeed.increase()
        playbackSpeedButton.setTitle(playbackSpeed.string(), for: .normal)
        audioVM.setPlaybackSpeed(playbackSpeed.rawValue)
    }
    
    private func onPlayingStateChanged(_ isPlaying: Bool) {
        let image = isPlaying ? "pause.fill" : "play.fill"
        progressButton.animate(to: viewModel?.calMessage.avPlayerItem?.progress ?? 0.0, systemIconName: image)
        progressButton.showRotation(show: isPlaying)
        playbackSpeedButton.setTitle(playbackSpeed.string(), for: .normal)
        playbackSpeedButton.isHidden = !isPlaying
    }
    
    private func onTimeChanged(_ time: Double) {
        guard let item = viewModel?.calMessage.avPlayerItem else { return }
        waveView.setPlaybackProgress(item.progress)
        progressButton.setProgressVisibility(visible: !item.isFinished)
        progressButton.displayLinkAnimateTo(progress: item.isFinished ? 0.0 : item.progress)
        self.timeLabel.text = item.audioTimerString()
    }
    
    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.calMessage.avPlayerItem?.progress ?? viewModel.fileState.progress
        let icon = viewModel.fileState.iconState
        let canShowDownloadUpload = viewModel.fileState.state != .completed
        progressButton.animate(to: progress, systemIconName: canShowDownloadUpload ? icon : playingIcon)
        progressButton.setProgressVisibility(visible: canShowProgress)
       
        let isPlaying = viewModel.calMessage.avPlayerItem?.isPlaying == true
        let isDownloading = viewModel.fileState.state == .downloading
        progressButton.showRotation(show:isPlaying || isDownloading)
    }
    
    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isAudio { return }
        updateProgress(viewModel: viewModel)
        Task { [weak self] in
            guard let self = self else { return }
            await recalculate()
            await updateArtwork()
            registerObservers()
            await setAudioDurationAndWaveform()
        }
    }
    
    private func recalculate() async {
        guard let mainData = viewModel?.threadVM?.historyVM.getMainData() else { return }
        await viewModel?.recalculate(mainData: mainData)
    }
    
    private func updateArtwork() async {
        if let data = try? await viewModel?.calMessage.avPlayerItem?.artworkMetadata?.load(.dataValue), let image = UIImage(data: data) {
            progressButton.setArtwork(image)
        } else {
            progressButton.setArtwork(nil)
        }
    }
    
    public func uploadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isAudio { return }
        updateProgress(viewModel: viewModel)
        Task { [weak self] in
            guard let self = self else { return }
            await recalculate()
            await updateArtwork()
            registerObservers()
            await setAudioDurationAndWaveform()
        }
    }
    
    private var canShowProgress: Bool {
        if viewModel?.calMessage.avPlayerItem?.isFinished == true { return false }
        if viewModel?.calMessage.avPlayerItem?.progress ?? 0.0 > 0.0 { return true }
        return viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }
    
    func registerObservers() {
        guard let item = viewModel?.calMessage.avPlayerItem else { return }
        item.$currentTime.sink { [weak self] time in
            self?.onTimeChanged(time)
        }
        .store(in: &cancellableSet)
        
        item.$isPlaying.sink { [weak self] isPlaying in
            self?.onPlayingStateChanged(isPlaying)
        }
        .store(in: &cancellableSet)
        
        item.$isFinished.sink { [weak self] isFinished in
            if isFinished {
                self?.progressButton.setProgressVisibility(visible: false)
                self?.progressButton.displayLinkAnimateTo(progress: 0.0)
            }
        }
        .store(in: &cancellableSet)
    }
    
    private func unregisterObservers() {
        cancellableSet.forEach { cancellable in
            cancellable.cancel()
        }
        cancellableSet.removeAll()
    }
    
    var playingIcon: String {
        guard let item = viewModel?.calMessage.avPlayerItem else { return "play.fill" }
        return item.isPlaying ? "pause.fill" : "play.fill"
    }
    
    private func setAudioDurationAndWaveform() async {
        guard let audioURL = viewModel?.calMessage.avPlayerItem?.fileURL,
              let message = viewModel?.message else { return }
        timeLabel.text = viewModel?.calMessage.avPlayerItem?.audioTimerString()
        let image = await viewModel?.calMessage.avPlayerItem?.createWaveform()
        waveView.setImage(to: image)
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
