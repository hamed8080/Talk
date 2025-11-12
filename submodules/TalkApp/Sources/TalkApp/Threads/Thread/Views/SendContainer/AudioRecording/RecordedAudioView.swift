//
//  RecordedAudioView.swift
//  Talk
//
//  Created by hamed on 7/21/24.
//

import Foundation
import TalkViewModels
import UIKit
import TalkUI
import Combine
import SwiftUI
import DSWaveformImage
import TalkModels
import AVFoundation
import Lottie

public final class RecordedAudioView: UIStackView {
    private let btnSend = UIImageButton(imagePadding: .init(all: 8))
    private let lblTimer = UILabel()
    private let waveView = AudioWaveFormView()
    private let btnTogglePlayer = UIButton(type: .system)
    private var cancellableSet = Set<AnyCancellable>()
    private weak var viewModel: ThreadViewModel?
    private var waveProgressView: LottieAnimationView?
    var onSendOrClose: (()-> Void)?
    public var fileURL: URL?
    private var item: AVAudioPlayerItem?
    private var audioRecoderVM: AudioRecordingViewModel? { viewModel?.audioRecoderVM }
    private var audioPlayerVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .horizontal
        spacing = 8
        alignment = .center
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        let image = UIImage(systemName: "chevron.right") ?? .init()
        btnSend.translatesAutoresizingMaskIntoConstraints = false
        btnSend.imageView.tintColor = Color.App.whiteUIColor
        btnSend.imageView.contentMode = .scaleAspectFit
        btnSend.imageView.image = image
        btnSend.backgroundColor = Color.App.accentUIColor!
        btnSend.accessibilityIdentifier = "btnSendRecordedAudioView"
        btnSend.action = { [weak self] in
            self?.onSendOrClose?()
            self?.viewModel?.historyVM.cancelTasks()
            let task: Task<Void, any Error> = Task { [weak self] in
                await self?.viewModel?.sendMessageViewModel.sendTextMessage()
            }
            self?.viewModel?.historyVM.setTask(task)
        }

        let btnDelete = UIButton(type: .system)
        btnDelete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        btnDelete.translatesAutoresizingMaskIntoConstraints = false
        let deleteImage = UIImage(named: "ic_delete")
        btnDelete.setImage(deleteImage, for: .normal)
        btnDelete.accessibilityIdentifier = "btnDeleteRecordedAudioView"
        btnDelete.tintColor = Color.App.textPrimaryUIColor

        lblTimer.textColor = Color.App.textPrimaryUIColor
        lblTimer.font = .fCaption2
        lblTimer.accessibilityIdentifier = "lblTimerRecordedAudioView"
        lblTimer.setContentHuggingPriority(.required, for: .horizontal)
        lblTimer.setContentCompressionResistancePriority(.required, for: .horizontal)

        waveView.translatesAutoresizingMaskIntoConstraints = false
        waveView.accessibilityIdentifier = "waveViewRecordedAudioView"
        waveView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        waveView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        btnTogglePlayer.translatesAutoresizingMaskIntoConstraints = false
        btnTogglePlayer.accessibilityIdentifier = "btnTogglePlayerRecordedAudioView"
        btnTogglePlayer.addTarget(self, action: #selector(onTogglePlayerTapped), for: .touchUpInside)

        addArrangedSubview(btnSend)
        addArrangedSubview(lblTimer)
        addArrangedSubview(waveView)
        addArrangedSubview(btnTogglePlayer)
        addArrangedSubview(btnDelete)

        NSLayoutConstraint.activate([
            waveView.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
            waveView.heightAnchor.constraint(equalToConstant: AudioRecordingContainerView.height),
            btnSend.heightAnchor.constraint(equalToConstant: AudioRecordingContainerView.height),
            btnSend.widthAnchor.constraint(equalToConstant: AudioRecordingContainerView.height),
            btnDelete.widthAnchor.constraint(equalToConstant: AudioRecordingContainerView.height),
            btnDelete.heightAnchor.constraint(equalToConstant: AudioRecordingContainerView.height),
            btnTogglePlayer.widthAnchor.constraint(equalToConstant: AudioRecordingContainerView.height),
            btnTogglePlayer.heightAnchor.constraint(equalToConstant: AudioRecordingContainerView.height),
        ])
        waveView.setTopConstant(value: -8)
    }

    func setup() throws {
        guard let fileURL = fileURL else { return }
        let item = createItemPlayer(fileURL: fileURL)
        self.item = item
        addProgressView()
        registerObservers(item: item)
        Task { [weak self] in
            guard let self = self else { return }
            let image = try await item.createWaveform(height: AudioRecordingContainerView.height - 4)
            self.waveView.alpha = 0
            self.waveView.setImage(to: image)
            UIView.animate(withDuration: 0.25) {
                self.waveView.alpha = 1
            }
            self.removeProgressView()
        }
    }

    private func registerObservers(item: AVAudioPlayerItem) {
        item.$currentTime.sink { [weak self] isPlaying in
            self?.lblTimer.text = item.audioTimerString()
            self?.waveView.setPlaybackProgress(item.progress)
        }
        .store(in: &cancellableSet)

        item.$isPlaying.sink { [weak self] isPlaying in
            let image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
            self?.btnTogglePlayer.setImage(image, for: .normal)
        }
        .store(in: &cancellableSet)
    }

    @objc private func deleteTapped(_ sender: UIButton) {
        fileURL = nil
        audioRecoderVM?.cancel()
        audioPlayerVM.close()
        onSendOrClose?()
        clear()
    }
    
    public func clear() {
        waveView.setImage(to: nil)
        removeProgressView()
    }
    
    private func addProgressView() {
        let waveProgressView = LottieAnimationView(talkName: "talk_logo_animation.json", color: Color.App.whiteUIColor ?? .white)
        waveProgressView.translatesAutoresizingMaskIntoConstraints = false
        self.waveProgressView = waveProgressView
        waveProgressView.tintColor = Color.App.accentUIColor ?? .white
        insertArrangedSubview(waveProgressView, at: 2)
        waveProgressView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        waveProgressView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        waveProgressView.isHidden = false
        waveProgressView.play()
    }
    
    private func removeProgressView() {
        waveProgressView?.isHidden = true
        waveProgressView?.stop()
        waveProgressView?.removeFromSuperview()
        waveProgressView = nil
    }
    
    @objc private func onTogglePlayerTapped(_ sender: UIButton) {
        if let item = item {
            try? audioPlayerVM.setup(item: item)
        }
        audioPlayerVM.toggle()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        btnSend.layer.cornerRadius = btnSend.bounds.width / 2
    }
    
    private func createItemPlayer(fileURL: URL) -> AVAudioPlayerItem {
        let asset = try? AVAsset(url: fileURL)
        let duration = Double(CMTimeGetSeconds(asset?.duration ?? CMTime()))
        let item = AVAudioPlayerItem(messageId: -2,
                                     duration: duration,
                                     fileURL: fileURL,
                                     ext: fileURL.fileExtension,
                                     title: fileURL.fileName,
                                     subtitle: "")
        return item
    }
    
    deinit {
        Task { @MainActor in
            if AppState.shared.objectsContainer.audioPlayerVM.item?.messageId == -2 {
                AppState.shared.objectsContainer.audioPlayerVM.pause()
                AppState.shared.objectsContainer.audioPlayerVM.close()
            }
        }
    }
}
