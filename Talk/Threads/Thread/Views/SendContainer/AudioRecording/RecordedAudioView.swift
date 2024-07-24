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

public final class RecordedAudioView: UIStackView {
    private let btnSend = UIImageButton(imagePadding: .init(all: 8))
    private let lblTimer = UILabel()
    private let waveImageView = UIImageView()
    private let btnTogglePlayer = UIButton(type: .system)
    private var cancellableSet = Set<AnyCancellable>()
    private weak var viewModel: ThreadViewModel?
    var onSendOrClose: (()-> Void)?
    private var audioRecoderVM: AudioRecordingViewModel? { viewModel?.audioRecoderVM }
    private var audioPlayerVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
        registerObservers()
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

        let image = UIImage(systemName: "arrow.up") ?? .init()
        btnSend.translatesAutoresizingMaskIntoConstraints = false
        btnSend.imageView.tintColor = Color.App.textPrimaryUIColor!
        btnSend.imageView.contentMode = .scaleAspectFit
        btnSend.imageView.image = image
        btnSend.backgroundColor = Color.App.accentUIColor!
        btnSend.accessibilityIdentifier = "btnSendRecordedAudioView"
        btnSend.action = { [weak self] in
            self?.onSendOrClose?()
            Task { [weak self] in
                await self?.viewModel?.sendMessageViewModel.sendTextMessage()
            }
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

        waveImageView.translatesAutoresizingMaskIntoConstraints = false
        waveImageView.accessibilityIdentifier = "waveImageViewRecordedAudioView"

        btnTogglePlayer.translatesAutoresizingMaskIntoConstraints = false
        btnTogglePlayer.accessibilityIdentifier = "btnTogglePlayerRecordedAudioView"

        addArrangedSubview(btnSend)
        addArrangedSubview(lblTimer)
        addArrangedSubview(waveImageView)
        addArrangedSubview(btnDelete)

        NSLayoutConstraint.activate([
            waveImageView.heightAnchor.constraint(equalToConstant: AudioRecordingView.height / 2),
            btnSend.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnSend.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnDelete.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnDelete.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnTogglePlayer.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnTogglePlayer.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
        ])
    }

    func setup() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                guard let url = audioPlayerVM.fileURL else { return }
                let waveformImageDrawer = WaveformImageDrawer()
                let image = try await waveformImageDrawer.waveformImage(
                    fromAudioAt: url,
                    with: .init(
                        size: .init(width: 250, height: AudioRecordingView.height),
                        style: .striped(
                            .init(
                                color: Color.App.accentUIColor ?? .white,
                                width: 3,
                                spacing: 2,
                                lineCap: .round
                            )
                        ),
                        shouldAntialias: true
                    ),
                    renderer: LinearWaveformRenderer()
                )
                await MainActor.run {
                    self.waveImageView.image = image
                }
            } catch {}
        }
    }

    private func registerObservers() {
        audioRecoderVM?.$timerString.sink { [weak self] timerString in
            self?.lblTimer.text = timerString
        }
        .store(in: &cancellableSet)

        audioPlayerVM.$isPlaying.sink { [weak self] isPlaying in
            let image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
            self?.btnTogglePlayer.setImage(image, for: .normal)
        }
        .store(in: &cancellableSet)
    }

    @objc private func deleteTapped(_ sender: UIButton) {
        audioRecoderVM?.cancel()
        audioPlayerVM.close()
        onSendOrClose?()
    }

    @objc private func onTogglePlayerTapped(_ sender: UIButton) {
        audioPlayerVM.toggle()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        btnSend.layer.cornerRadius = btnSend.bounds.width / 2
    }
}
