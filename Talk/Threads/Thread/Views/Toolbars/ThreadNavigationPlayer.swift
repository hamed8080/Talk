//
//  ThreadNavigationPlayer.swift
//  Talk
//
//  Created by hamed on 6/18/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkModels
import SwiftUI
import TalkUI
import Combine

@MainActor
class ThreadNavigationPlayer: UIView {
    private let timerLabel = UILabel()
    private let titleLabel = UILabel()
    private let closeButton = UIImageButton(imagePadding: .init(all: 8))
    private let playButton = UIImageButton(imagePadding: .init(all: 8))
    private let progress = UIProgressView(progressViewStyle: .bar)
    private weak var viewModel: ThreadViewModel?
    private var cancellableSet = Set<AnyCancellable>()
    private var playerVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    weak var stack: UIStackView?

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        register()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.uiiransansCaption
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.accessibilityIdentifier = "titleLabelThreadNavigationPlayer"
        addSubview(titleLabel)

        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textColor = .gray
        timerLabel.font = .uiiransansCaption2
        timerLabel.accessibilityIdentifier = "timerLabelThreadNavigationPlayer"
        addSubview(timerLabel)

        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.transform = CGAffineTransform(scaleX: 1.0, y: 0.5)
        progress.tintColor = Color.App.accentUIColor
        progress.accessibilityIdentifier = "progressThreadNavigationPlayer"
        addSubview(progress)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = Color.App.accentUIColor
        closeButton.imageView.image = UIImage(systemName: "xmark")
        closeButton.imageView.tintColor = Color.App.textSecondaryUIColor
        closeButton.accessibilityIdentifier = "closeButtonThreadNavigationPlayer"
        closeButton.action = { [weak self] in
            self?.close()
        }
        addSubview(closeButton)
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.tintColor = Color.App.accentUIColor
        playButton.imageView.image = UIImage(systemName: "play.fill")
        playButton.imageView.tintColor = Color.App.accentUIColor
        playButton.accessibilityIdentifier = "playButtonThreadNavigationPlayer"
        playButton.action = { [weak self] in
            self?.toggle()
        }
        addSubview(playButton)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(taped))
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -2),
            titleLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            timerLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
            timerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            progress.leadingAnchor.constraint(equalTo: leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: trailingAnchor),
            progress.widthAnchor.constraint(equalTo: widthAnchor),
            progress.heightAnchor.constraint(equalToConstant: 1),
            progress.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
        ])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0.5
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        }
    }

    @objc private func taped(_ sender: UIGestureRecognizer) {
        Task {
            if let message = playerVM.message, let time = message.time, let id = message.id {
                await viewModel?.historyVM.moveToTime(time, id)
            }
        }
    }

    private func toggle() {
        playerVM.toggle()
    }

    private func close() {
        playerVM.close()
        setIsHidden(true)
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    public func register() {
        show(show: playerVM.isClosed != true)
        playerVM.$isPlaying.sink { [weak self] isPlaying in
            let image = isPlaying ? "pause.fill" : "play.fill"
            self?.playButton.imageView.image = UIImage(systemName: image)
        }
        .store(in: &cancellableSet)

        playerVM.$title.sink { [weak self] title in
            self?.titleLabel.text = title
            self?.animate()
        }
        .store(in: &cancellableSet)

        playerVM.$currentTime.sink { [weak self] currentTime in
            guard let self = self else { return }
            timerLabel.text = currentTime.timerString(locale: Language.preferredLocale) ?? ""
            let progress = Float(max(currentTime, 0.0) / playerVM.duration)
            self.progress.progress = progress.isNaN ? 0.0 : progress
            animate()
        }
        .store(in: &cancellableSet)

        playerVM.$isClosed.sink { [weak self] closed in
            self?.show(show: !closed)
        }
        .store(in: &cancellableSet)
    }

    private func animate() {
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    private func show(show: Bool) {
        if !show {
            removeFromSuperViewWithAnimation()
        } else if superview == nil {
            alpha = 0.0
            stack?.addArrangedSubview(self)
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
            }
        }
    }
}
