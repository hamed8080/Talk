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
import DSWaveformImage

final class MessageAudioView: UIView {
    // Views
    private let fileSizeLabel = UILabel()
    private let timeLabel = UILabel()
    private let waveImageView = UIImageView()
    private let playbackWaveformImageView = UIImageView()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.textPrimaryUIColor,
                                                      bgColor: Color.App.accentUIColor,
                                                      margin: 2
    )
    private let maskLayer = CAShapeLayer()
    private let playbackSpeedButton = UIButton(type: .system)
    

    // Models
    private var cancellableSet = Set<AnyCancellable>()
    private weak var viewModel: MessageRowViewModel?
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    private let prerenderImage = UIImage(named: "waveform")
    private var playbackSpeed: PlaybackSpeed = .one
    private var isSeeking: Bool = false
    private var seekTimer: Timer? = nil

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
        
        waveImageView.translatesAutoresizingMaskIntoConstraints = false
        waveImageView.isUserInteractionEnabled = true
        waveImageView.accessibilityIdentifier = "waveImageViewMessageAudioView"
        waveImageView.layer.opacity = 0.2
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onDragOverWaveform))
        gesture.maximumNumberOfTouches = 1
        waveImageView.addGestureRecognizer(gesture)
        addSubview(waveImageView)
        
        playbackWaveformImageView.translatesAutoresizingMaskIntoConstraints = false
        playbackWaveformImageView.isUserInteractionEnabled = false
        playbackWaveformImageView.accessibilityIdentifier = "playbackWaveformImageViewMessageAudioView"
        playbackWaveformImageView.tintColor = Color.App.textPrimaryUIColor
        playbackWaveformImageView.layer.mask = maskLayer
        addSubview(playbackWaveformImageView)
        bringSubviewToFront(playbackWaveformImageView)
        
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.uiiransansBoldCaption
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textSecondaryUIColor?.withAlphaComponent(0.7)
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageAudioView"
        fileSizeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileSizeLabel.isOpaque = true
        addSubview(fileSizeLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = Color.App.textPrimaryUIColor
        timeLabel.font = UIFont.uiiransansBoldCaption
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
        playbackSpeedButton.titleLabel?.font = UIFont.uiiransansBoldSubheadline
        playbackSpeedButton.setTitle("", for: .normal)
        playbackSpeedButton.addTarget(self, action: #selector(onPlaybackSpeedTapped), for: .touchUpInside)
        playbackSpeedButton.layer.backgroundColor = Color.App.bgSecondaryUIColor?.withAlphaComponent(0.8).cgColor
        playbackSpeedButton.isHidden = true
        addSubview(playbackSpeedButton)

        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.heightAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            
            waveImageView.widthAnchor.constraint(equalToConstant: 246),
            waveImageView.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: margin * 2),
            waveImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin * 2),
            waveImageView.topAnchor.constraint(equalTo: progressButton.topAnchor),
            waveImageView.heightAnchor.constraint(equalToConstant: 42),
            
            playbackWaveformImageView.widthAnchor.constraint(equalTo: waveImageView.widthAnchor),
            playbackWaveformImageView.heightAnchor.constraint(equalTo: waveImageView.heightAnchor),
            playbackWaveformImageView.leadingAnchor.constraint(equalTo: waveImageView.leadingAnchor),
            playbackWaveformImageView.topAnchor.constraint(equalTo: waveImageView.topAnchor),
            
            fileSizeLabel.leadingAnchor.constraint(equalTo: waveImageView.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: waveImageView.bottomAnchor, constant: margin),
            fileSizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            timeLabel.leadingAnchor.constraint(equalTo: fileSizeLabel.trailingAnchor, constant: margin),
            timeLabel.topAnchor.constraint(equalTo: fileSizeLabel.topAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            timeLabel.bottomAnchor.constraint(equalTo: fileSizeLabel.bottomAnchor),
            
            playbackSpeedButton.widthAnchor.constraint(equalToConstant: 52),
            playbackSpeedButton.heightAnchor.constraint(equalToConstant: 28),
            playbackSpeedButton.topAnchor.constraint(equalTo: fileSizeLabel.topAnchor, constant: -4),
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
        updateProgress(viewModel: viewModel)
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        waveImageView.image = prerenderImage
        startGenerateWaveformTask()
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
    
    @objc private func onDragOverWaveform(_ sender: UIPanGestureRecognizer) {
        let to: Double = sender.location(in: sender.view).x / waveImageView.frame.size.width
        let path = createPath(to)

        seekTimer?.invalidate()
        seekTimer = nil
        isSeeking = true
        
        maskLayer.path = path
        audioVM.seek(to)
        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.isSeeking = false
        }
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
        if !isSeeking {
            updateProgressWaveform(progress)
        } else {
            print("was seeking")
        }
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
        updateProgress(viewModel: viewModel)
        startGenerateWaveformTask()
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        updateProgress(viewModel: viewModel)
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
            print("currentTime: \(self?.audioVM.currentTime ?? 0) time:\(time)")
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
        isSameFile ? "\(audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? "") / \(audioVM.duration.timerString(locale: Language.preferredLocale) ?? "")" : " " // We use space to prevent the text collapse
    }

    var playingIcon: String {
        if !isSameFile { return "play.fill" }
        return audioVM.isPlaying ? "pause.fill" : "play.fill"
    }
    
    private func startGenerateWaveformTask() {
        Task.detached { [weak self] in
            await self?.generateWaveform()
        }
    }
    
    private func generateWaveform() async {
        guard let url = fileURLOrConvertedURL() else { return }
        let waveformImageDrawer = WaveformImageDrawer()
        do {
            let image = try await waveformImageDrawer.waveformImage(
                fromAudioAt: url,
                with: .init(
                    size: .init(width: 164, height: 42),
                    style: .striped(
                        .init(
                            color: UIColor.gray,
                            width: 2,
                            spacing: 4,
                            lineCap: .round
                        )
                    ),
                    shouldAntialias: true
                ),
                renderer: LinearWaveformRenderer()
            )
            await MainActor.run {
                self.waveImageView.image = image
                self.playbackWaveformImageView.image = image.withTintColor(.black, renderingMode: .alwaysTemplate)
            }
        } catch {
            print("error in generating the waveform error: \(error)")
        }
    }
    
    private func fileURLOrConvertedURL() -> URL? {
        convertedAudioURL() ?? tempAudioURL()
    }
    
    private func convertedAudioURL() -> URL? {
        if  let convertedURL = message?.convertedFileURL, FileManager.default.fileExists(atPath: convertedURL.path()) {
            return convertedURL
        }
        return nil
    }
    
    private func tempAudioURL() -> URL? {
        if let fileURL = viewModel?.calMessage.fileURL {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("WaveformGenerator.wav")
            try? FileManager.default.copyItem(at: fileURL, to: tempURL)
            return tempURL
        }
        return nil
    }
    
    private func createPath(_ progress: Double) -> CGPath {
        let fullRect = playbackWaveformImageView.bounds
        let newWidth = Double(fullRect.size.width) * progress
        let newBounds = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(fullRect.size.height))
        return CGPath(rect: newBounds, transform: nil)
    }
    
    private func updateProgressWaveform(_ progress: Double) {
        animateMaskLayer(newPath: createPath(progress))
    }
    
    private func animateMaskLayer(newPath: CGPath) {
        
        // Remove any previous animation to avoid stacking issues
        maskLayer.removeAnimation(forKey: "pathAnimation")
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = maskLayer.path
        animation.toValue = newPath
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        // Add the animation to the mask layer directly
        maskLayer.add(animation, forKey: "pathAnimation")
        maskLayer.path = newPath
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
