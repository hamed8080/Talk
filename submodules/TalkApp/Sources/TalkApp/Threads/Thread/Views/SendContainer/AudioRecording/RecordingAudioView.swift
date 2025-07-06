//
//  RecordingAudioView.swift
//  Talk
//
//  Created by hamed on 7/21/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkUI
import Combine
import SwiftUI
import AVFoundation

@MainActor
public final class RecordingAudioView: UIStackView {
    private let btnMic = UIImageButton(imagePadding: .init(all: 8))
    private let dotRecordingIndicator = UIImageView()
    private let lblTimer = UILabel()
    private weak var viewModel: AudioRecordingViewModel?
    private var dotTimer: Timer?
    private var cancellableSet = Set<AnyCancellable>()
    var onSubmitRecord: (()-> Void)?

    public init(viewModel: AudioRecordingViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .horizontal
        spacing = 12
        alignment = .center
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        btnMic.translatesAutoresizingMaskIntoConstraints = false
        let micImage = UIImage(systemName: "mic.fill")!
        btnMic.imageView.image = micImage
        btnMic.imageView.tintColor = Color.App.textPrimaryUIColor!
        btnMic.imageView.contentMode = .scaleAspectFit
        btnMic.backgroundColor = Color.App.accentUIColor!
        btnMic.accessibilityIdentifier = "btnMicRecordingAudioView"
        btnMic.setContentHuggingPriority(.required, for: .horizontal)
        btnMic.action = { [weak self] in
            self?.micTapped()
        }

        let lblStaticRecording = UILabel()
        lblStaticRecording.text = "Thread.isVoiceRecording".bundleLocalized()
        lblStaticRecording.font = .fCaption
        lblStaticRecording.textColor = Color.App.textSecondaryUIColor
        lblStaticRecording.accessibilityIdentifier = "lblStaticRecordingRecordingAudioView"
        lblStaticRecording.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        lblTimer.font = .fBody
        lblTimer.textColor = Color.App.textPrimaryUIColor
        lblTimer.accessibilityIdentifier = "lblTimerRecordingAudioView"
        lblTimer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        viewModel?.$timerString.sink { [weak self] newValue in
            UIView.animate(withDuration: 0.2) {
                self?.lblTimer.text = newValue
            }
        }
        .store(in: &cancellableSet)

        dotRecordingIndicator.image = UIImage(systemName: "circle.fill")
        dotRecordingIndicator.tintColor = Color.App.redUIColor
        dotRecordingIndicator.translatesAutoresizingMaskIntoConstraints = false
        dotRecordingIndicator.accessibilityIdentifier = "dotRecordingIndicatorRecordingAudioView"
        dotRecordingIndicator.setContentHuggingPriority(.required, for: .horizontal)
        dotRecordingIndicator.setContentHuggingPriority(.required, for: .vertical)

        addArrangedSubview(btnMic)
        addArrangedSubview(lblStaticRecording)
        addArrangedSubview(lblTimer)
        addArrangedSubview(dotRecordingIndicator)

        NSLayoutConstraint.activate([
            dotRecordingIndicator.widthAnchor.constraint(equalToConstant: 8),
            dotRecordingIndicator.heightAnchor.constraint(equalToConstant: 8),
            btnMic.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnMic.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
        ])
    }

    private func micTapped() {
        viewModel?.stop()
        if let fileURL = viewModel?.recordingOutputPath {
            let playerVM = AppState.shared.objectsContainer.audioPlayerVM
            let asset = try? AVAsset(url: fileURL)
            let duration = Double(CMTimeGetSeconds(asset?.duration ?? CMTime()))
            let item = AVAudioPlayerItem(messageId: -2,
                                         duration: duration,
                                         fileURL: fileURL,
                                         ext: fileURL.fileExtension,
                                         title: fileURL.fileName,
                                         subtitle: "")
            try? playerVM.setup(item: item)
            onSubmitRecord?()
        }
        stopAnimation()
    }

    func startCircleAnimation() {
        dotTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.onAnimationCycle()
            }
        }
    }
    
    private func onAnimationCycle() {
        UIView.animate(withDuration: 1.0) {
            let alpha = self.dotRecordingIndicator.alpha
            self.dotRecordingIndicator.alpha = alpha == 1.0 ? 0.2 : 1.0
        }
    }

    private func stopAnimation() {
        dotTimer?.invalidate()
        dotTimer = nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        btnMic.layer.cornerRadius = btnMic.bounds.width / 2
    }
}
