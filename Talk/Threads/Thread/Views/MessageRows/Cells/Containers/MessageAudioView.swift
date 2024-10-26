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

final class MessageAudioView: UIView {
    // Views
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let playerProgress = UIProgressView(progressViewStyle: .bar)
    private let timeLabel = UILabel()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.textPrimaryUIColor,
                                                      bgColor: Color.App.accentUIColor,
                                                      margin: 2
    )

    // Models
    private var cancellableSet = Set<AnyCancellable>()
    private weak var viewModel: MessageRowViewModel?
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }

    // Sizes
    private let margin: CGFloat = 6
    private let verticalSpacing: CGFloat = 4
    private let progressButtonSize: CGFloat = 36
    private let playerProgressHeight: CGFloat = 3
    private let minPlayerProgressWidth: CGFloat = 128

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

        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.accessibilityIdentifier = "fileNameLabelMessageAudioView"
        fileNameLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileNameLabel.isOpaque = true
        addSubview(fileNameLabel)

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageAudioView"
        fileSizeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileSizeLabel.isOpaque = true
        addSubview(fileSizeLabel)

        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor
        fileTypeLabel.numberOfLines = 1
        fileTypeLabel.setContentHuggingPriority(.required, for: .vertical)
        fileTypeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        fileTypeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        fileTypeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        fileTypeLabel.accessibilityIdentifier = "fileTypeLabelMessageAudioView"
        fileTypeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileTypeLabel.isOpaque = true
        addSubview(fileTypeLabel)

        playerProgress.translatesAutoresizingMaskIntoConstraints = false
        playerProgress.tintColor = Color.App.textPrimaryUIColor
        playerProgress.layer.cornerRadius = 1.5
        playerProgress.layer.masksToBounds = true
        playerProgress.trackTintColor = UIColor.gray.withAlphaComponent(0.3)
        playerProgress.accessibilityIdentifier = "playerProgressMessageAudioView"
        playerProgress.setContentHuggingPriority(.required, for: .vertical)
        playerProgress.setContentCompressionResistancePriority(.required, for: .vertical)
        playerProgress.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        playerProgress.isOpaque = true
        playerProgress.semanticContentAttribute = .forceLeftToRight
        addSubview(playerProgress)

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

        NSLayoutConstraint.activate([
            progressButton.widthAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.heightAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: margin),

            fileNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            fileNameLabel.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: margin),
            fileNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),

            fileSizeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor),

            fileTypeLabel.topAnchor.constraint(equalTo: fileSizeLabel.topAnchor),
            fileTypeLabel.leadingAnchor.constraint(equalTo: fileSizeLabel.trailingAnchor, constant: margin),
            fileTypeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),

            playerProgress.widthAnchor.constraint(greaterThanOrEqualToConstant: minPlayerProgressWidth),
            playerProgress.heightAnchor.constraint(equalToConstant: playerProgressHeight),
            playerProgress.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            playerProgress.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            playerProgress.topAnchor.constraint(equalTo: fileTypeLabel.bottomAnchor, constant: verticalSpacing),

            timeLabel.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: playerProgress.bottomAnchor, constant: verticalSpacing),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin)
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        updateProgress(viewModel: viewModel)

        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileTypeLabel.text = viewModel.calMessage.extName
        timeLabel.text = audioTimerString()
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
        if isSameFile {
            if audioVM.isPlaying {
                registerOnTap()
            }
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
            let normalized = progress.isNaN ? 0.0 : Float(progress)
            playerProgress.setProgress(normalized, animated: true)
            self.timeLabel.text = audioTimerString()
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
                self?.playerProgress.progress = 0.0
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
}
