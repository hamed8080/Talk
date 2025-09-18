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
import MediaPlayer

@MainActor
class ThreadNavigationPlayer: UIView {
    private let timerLabel = UILabel()
    private let titleLabel = UILabel()
    private let closeButton = UIImageButton(imagePadding: .init(all: 8))
    private let playButton = UIImageButton(imagePadding: .init(all: 8))
    private let progress = UIProgressView(progressViewStyle: .bar)
    private weak var viewModel: ThreadViewModel?
    private var cancellableSet = Set<AnyCancellable>()
    private var swapPlayerCancellable: AnyCancellable?
    private var playerVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    weak var stack: UIStackView?

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        registerSwapAudioNotification()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.fCaption
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.accessibilityIdentifier = "titleLabelThreadNavigationPlayer"
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        addSubview(titleLabel)

        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textColor = .gray
        timerLabel.font = .fCaption2
        timerLabel.accessibilityIdentifier = "timerLabelThreadNavigationPlayer"
        addSubview(timerLabel)

        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.transform = CGAffineTransform(scaleX: 1.0, y: 0.5)
        progress.tintColor = Color.App.accentUIColor
        progress.accessibilityIdentifier = "progressThreadNavigationPlayer"
        addSubview(progress)

        // Get the system-preferred font for a text style
        let font = UIFont.preferredFont(forTextStyle: .body)

        // Create a symbol configuration based on the font
        let config = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .bold)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = Color.App.accentUIColor
        closeButton.imageView.image = UIImage(systemName: "xmark", withConfiguration: config)
        closeButton.imageView.contentMode = .scaleAspectFit
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
            playButton.widthAnchor.constraint(equalToConstant: 32),
            
            titleLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: timerLabel.leadingAnchor, constant: -4),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            
            timerLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
            timerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            /// This prevents it from getting so small and the title wobbles a lot.
            timerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
            
            progress.leadingAnchor.constraint(equalTo: leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: trailingAnchor),
            progress.widthAnchor.constraint(equalTo: widthAnchor),
            progress.heightAnchor.constraint(equalToConstant: 1),
            progress.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
        ])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        
        // Replace `ignoredView` with the actual UIView you want to ignore touches on
        if playButton.bounds.contains(touch.location(in: playButton)) {
            return // Ignore the touch if it's inside the ignoredView
        }
        
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
        let task: Task<Void, any Error> = Task { [weak self] in
            guard let self = self, let message = playerVM.message, let time = message.time, let id = message.id else { return }
            if viewModel != nil {
                await viewModel?.historyVM.moveToTime(time, id)
            } else {
                /// Open thread and move to the message directly if we are outside of the thread and player is still plying
                let threadId = message.conversation?.id ?? -1
                AppState.shared.openThreadAndMoveToMessage(conversationId: threadId, messageId: id, messageTime: time)
            }
        }
        viewModel?.historyVM.setTask(task)
    }

    private func toggle() {
        playerVM.toggle()
    }

    private func close() {
        removeFromSuperViewWithAnimation(withAimation: false)
        playerVM.pause()
        playerVM.item = nil
        NotificationCenter.default.post(name: NSNotification.Name("CLOSE_PLAYER"), object: nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    private func registerSwapAudioNotification() {
        swapPlayerCancellable = NotificationCenter.default.publisher(for: Notification.Name("SWAP_PLAYER")).sink { [weak self] notif in
            self?.unregister()
            self?.register()
        }
    }
    
    public func register() {
        guard let item = playerVM.item else {
            show(show: false)
            return
        }
        titleLabel.text = item.title
        show(show: !item.isFinished)
        
        item.$isPlaying.sink { [weak self] isPlaying in
            let image = isPlaying ? "pause.fill" : "play.fill"
            self?.playButton.imageView.image = UIImage(systemName: image)
        }
        .store(in: &cancellableSet)

        item.$currentTime.sink { [weak self] currentTime in
            guard let self = self else { return }
            timerLabel.text = currentTime.timerString(locale: Language.preferredLocale) ?? ""
            let progress = Float(max(currentTime, 0.0) / item.duration)
            self.progress.progress = progress.isNaN ? 0.0 : progress
            animate()
        }
        .store(in: &cancellableSet)

        item.$isFinished.sink { [weak self] closed in
            self?.show(show: !closed)
        }
        .store(in: &cancellableSet)
    }
    
    public func unregister() {
        cancellableSet.forEach { cancellable in
            cancellable.cancel()
        }
        cancellableSet.removeAll()
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
            (stack as? TopThreadToolbar)?.sort()
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
            }
        } else if alpha == 0.0 {
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
            }
        }
    }
}

struct NavigationPlayerWrapper: UIViewRepresentable {
    @Environment(\.layoutDirection) var layoutDirection

    func makeUIView(context: Context) -> UIView {
        let playerView = ThreadNavigationPlayer(viewModel: nil)
        playerView.semanticContentAttribute = layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        playerView.register()
       
        /// A wrapper to fix the width and content semantic of a view
        let wrapper = UIView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(playerView)
        
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: wrapper.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
