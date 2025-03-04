//
//  MessageVideoView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import AVKit
import Chat

@MainActor
final class MessageVideoView: UIView, @preconcurrency AVPlayerViewControllerDelegate {
    // Views
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let playOverlayView = UIView()
    private let playIcon: UIImageView = UIImageView()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.whiteUIColor,
                                                      lineWidth: 1.5,
                                                      iconSize: .init(width: 12, height: 12),
                                                      margin: 2
    )

    // Models
    private var playerVC: AVPlayerViewController?
    private var videoPlayerVM: VideoPlayerViewModel?
    private weak var viewModel: MessageRowViewModel?
    private var message: HistoryMessageType? { viewModel?.message }
    private static let playIcon: UIImage = UIImage(systemName: "play.fill")!

    // Constraints
    private var fileNameLabelTrailingConstarint: NSLayoutConstraint!

    // Sizes
    private let margin: CGFloat = 4
    private let minWidth: CGFloat = 320
    private let height: CGFloat = 196
    private let playIconSize: CGFloat = 36
    private let progressButtonSize: CGFloat = 24
    private let verticalSpacing: CGFloat = 2

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
        layer.masksToBounds = true
        backgroundColor = UIColor.black
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.fBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageVideoView"
        addSubview(fileSizeLabel)

        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.font = UIFont.fBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.accessibilityIdentifier = "fileNameLabelMessageVideoView"
        addSubview(fileNameLabel)

        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.font = UIFont.fBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor
        fileTypeLabel.accessibilityIdentifier = "fileTypeLabelMessageVideoView"
        addSubview(fileTypeLabel)

        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playIcon.setIsHidden(true)
        playIcon.contentMode = .scaleAspectFit
        playIcon.image = MessageVideoView.playIcon
        playIcon.tintColor = Color.App.whiteUIColor
        playIcon.accessibilityIdentifier = "playIconMessageVideoView"
        addSubview(playIcon)

        playOverlayView.translatesAutoresizingMaskIntoConstraints = false
        playOverlayView.backgroundColor = .clear
        playOverlayView.accessibilityIdentifier = "playOverlayViewMessageVideoView"
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onTap))
        playOverlayView.addGestureRecognizer(tapGesture)
        addSubview(playOverlayView)

        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.accessibilityIdentifier = "progressButtonMessageVideoView"
        addSubview(progressButton)
        let widthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth)
        widthConstraint.priority = .defaultHigh

        fileNameLabelTrailingConstarint = fileNameLabel.trailingAnchor.constraint(equalTo: progressButton.leadingAnchor, constant: -margin)

        bringSubviewToFront(playOverlayView)
        
        NSLayoutConstraint.activate([
            widthConstraint,
            heightAnchor.constraint(equalToConstant: height),

            fileNameLabelTrailingConstarint,
            fileNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            fileNameLabel.centerYAnchor.constraint(equalTo: progressButton.centerYAnchor),

            progressButton.widthAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.heightAnchor.constraint(equalToConstant: progressButtonSize),
            progressButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: margin),

            fileTypeLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor),
            fileTypeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: verticalSpacing),
            fileSizeLabel.trailingAnchor.constraint(equalTo: fileTypeLabel.leadingAnchor, constant: -margin),
            fileSizeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: verticalSpacing),

            playOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playOverlayView.topAnchor.constraint(equalTo: topAnchor),
            playOverlayView.heightAnchor.constraint(equalTo: heightAnchor),

            playIcon.widthAnchor.constraint(equalToConstant: playIconSize),
            playIcon.heightAnchor.constraint(equalToConstant: playIconSize),
            playIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        if let url = viewModel.calMessage.fileURL {
            prepareUIForPlayback(url: url)
        } else {
            prepareUIForDownload()
        }
        updateProgress(viewModel: viewModel)
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileTypeLabel.text = viewModel.calMessage.extName

        // To stick to the leading if we downloaded/uploaded
        fileNameLabelTrailingConstarint.constant = canShowProgress ? -margin : progressButtonSize
    }

    func updateWidthConstarints() {
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: margin),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -margin)
        ])
    }

    private func prepareUIForPlayback(url: URL) {
        showDownloadProgress(show: false)
        playIcon.setIsHidden(false)
        Task {
            await makeViewModel(url: url, message: message)
            if let player = videoPlayerVM?.player {
                setVideo(player: player)
            }
        }
    }

    private func prepareUIForDownload() {
        playIcon.setIsHidden(true)
        showDownloadProgress(show: true)
    }

    private func showDownloadProgress(show: Bool) {
        progressButton.setIsHidden(!show)
        progressButton.setProgressVisibility(visible: show)
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.fileState.progress
        progressButton.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        progressButton.setProgressVisibility(visible: canShowProgress)
    }

    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true || viewModel?.fileState.state == .undefined
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isVideo { return }
        bringSubviewToFront(progressButton)
        updateProgress(viewModel: viewModel)
        fileNameLabelTrailingConstarint.constant = progressButtonSize
        if let fileURL = viewModel.calMessage.fileURL {
            prepareUIForPlayback(url: fileURL)
        }
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isVideo { return }
        updateProgress(viewModel: viewModel)
        if let fileURL = viewModel.calMessage.fileURL {
            prepareUIForPlayback(url: fileURL)
        }
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        if viewModel?.calMessage.fileURL != nil {
            videoPlayerVM?.toggle()
            enterFullScreen(animated: true)
        } else {
            // Download file
            viewModel?.onTap()
        }
    }

    @MainActor
    private func setVideo(player: AVPlayer) {
        if playerVC == nil {
            playerVC = AVPlayerViewController()
        }
        playerVC?.player = player
        playerVC?.showsPlaybackControls = false
        playerVC?.allowsVideoFrameAnalysis = false
        playerVC?.entersFullScreenWhenPlaybackBegins = true
        playerVC?.delegate = self
        addPlayerViewToView()
        
        
        /// Add auto play if is enabled in the setting, default is true with mute audio
        if viewModel?.threadVM?.model.isAutoPlayVideoEnabled == true {
            playerVC?.player?.isMuted = true
            playIcon.setIsHidden(true)
            playerVC?.player?.play()
        } else {
            playIcon.setIsHidden(false)
        }
    }

    private func addPlayerViewToView() {
        let rootVC = viewModel?.threadVM?.delegate as? UIViewController
        if let rootVC = rootVC, let playerVC = playerVC, let view = playerVC.view {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(view, at: 0)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            rootVC.addChild(playerVC)
            playerVC.didMove(toParent: rootVC)
        }
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
        playerVC?.showsPlaybackControls = true
    }
    
    public func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        playerVC?.showsPlaybackControls = false
    }

    func enterFullScreen(animated: Bool) {
        playerVC?.player?.isMuted = false
        playerVC?.perform(NSSelectorFromString("enterFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }

    func exitFullScreen(animated: Bool) {
        playerVC?.perform(NSSelectorFromString("exitFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }

    private func makeViewModel(url: URL, message: HistoryMessageType?) async {
        let metadata = await metadata(message: message)
        if url.absoluteString == videoPlayerVM?.fileURL.absoluteString ?? "" { return }
        self.videoPlayerVM = VideoPlayerViewModel(fileURL: url,
                             ext: metadata?.file?.mimeType?.ext,
                             title: metadata?.name,
                             subtitle: metadata?.file?.originalName ?? "")
    }
    
    @AppBackgroundActor
    private func metadata(message: HistoryMessageType?) async -> FileMetaData? {
        message?.fileMetaData
    }
}
