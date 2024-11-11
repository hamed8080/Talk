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

    // Models
    private var cancellableSet = Set<AnyCancellable>()
    private weak var viewModel: MessageRowViewModel?
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    private let prerenderImage = UIImage(named: "waveform")

    // Sizes
    private let margin: CGFloat = 6
    private let verticalSpacing: CGFloat = 4
    private let progressButtonSize: CGFloat = 36
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

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageAudioView"
        fileSizeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileSizeLabel.isOpaque = true
        addSubview(fileSizeLabel)
        
        waveImageView.translatesAutoresizingMaskIntoConstraints = false
        waveImageView.isUserInteractionEnabled = true
        waveImageView.accessibilityIdentifier = "waveImageViewMessageAudioView"
        waveImageView.layer.opacity = 0.2
        addSubview(waveImageView)
        
        playbackWaveformImageView.translatesAutoresizingMaskIntoConstraints = false
        playbackWaveformImageView.isUserInteractionEnabled = true
        playbackWaveformImageView.accessibilityIdentifier = "playbackWaveformImageViewMessageAudioView"
        playbackWaveformImageView.tintColor = Color.App.textPrimaryUIColor
        playbackWaveformImageView.layer.mask = maskLayer
        addSubview(playbackWaveformImageView)
        bringSubviewToFront(playbackWaveformImageView)

        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.heightAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            
            waveImageView.widthAnchor.constraint(equalToConstant: 164),
            waveImageView.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: margin),
            waveImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            waveImageView.topAnchor.constraint(equalTo: progressButton.topAnchor),
            waveImageView.heightAnchor.constraint(equalToConstant: 36),
            
            playbackWaveformImageView.widthAnchor.constraint(equalTo: waveImageView.widthAnchor),
            playbackWaveformImageView.heightAnchor.constraint(equalTo: waveImageView.heightAnchor),
            playbackWaveformImageView.leadingAnchor.constraint(equalTo: waveImageView.leadingAnchor),
            playbackWaveformImageView.topAnchor.constraint(equalTo: waveImageView.topAnchor),
            
            fileSizeLabel.leadingAnchor.constraint(equalTo: waveImageView.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: waveImageView.bottomAnchor),
            fileSizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
        ])
        registerOnTap()
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

    func registerOnTap() {
        audioVM.$currentTime.sink { [weak self] newValue in
            guard let self = self, isSameFile else { return }
            let progress = min(audioVM.currentTime / audioVM.duration, 1.0)
            updateProgressWaveform(progress)
        }
        .store(in: &cancellableSet)

        audioVM.$isPlaying.sink { [weak self] isPlaying in
            guard let self = self, isSameFile else { return }
            let image = isPlaying ? "pause.fill" : "play.fill"
            progressButton.animate(to: 1.0, systemIconName: image)
            progressButton.setProgressVisibility(visible: false)
        }
        .store(in: &cancellableSet)

        audioVM.$isClosed.sink { [weak self] closed in
            if closed, self?.isSameFile == true {
//                self?.playerProgress.progress = 0.0
            }
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
                    size: .init(width: 164, height: 36),
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
        if let convertedURL = message?.convertedFileURL, FileManager.default.fileExists(atPath: convertedURL.path()) {
            return convertedURL
        } else {
            if let fileURL = viewModel?.calMessage.fileURL {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("WaveformGenerator.wav")
                try? FileManager.default.copyItem(at: fileURL, to: tempURL)
                return tempURL
            } else {
                return nil
            }
        }
    }
    
    private func updateProgressWaveform(_ progress: Double) {
        let fullRect = playbackWaveformImageView.bounds
        let newWidth = Double(fullRect.size.width) * progress
        let newBounds = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(fullRect.size.height))
        let path = CGPath(rect: newBounds, transform: nil)
        animateMaskLayer(newPath: path)
    }
    
    private func animateMaskLayer(newPath: CGPath) {
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
