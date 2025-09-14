//
//  ThreadPinMessageView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import Chat
import ChatDTO
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

public final class ThreadPinMessageView: UIStackView {
    private let bar = UIView()
    private let pinImageView = UIImageView(frame: .zero)
    private let imageView = UIImageView(frame: .zero)
    private let textButton = UIButton(type: .system)
    private let unpinButton = UIImageButton(imagePadding: .init(all: 4))
    private weak var viewModel: ThreadPinMessageViewModel?
    weak var stack: UIStackView?

    public init(viewModel: ThreadPinMessageViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
        Task { [weak self] in
            guard let self = self else { return }
            viewModel?.downloadImageThumbnail()
            await viewModel?.calculate()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false

        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.accessibilityIdentifier = "barThreadPinMessageView"

        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.image = UIImage(systemName: "pin.fill")
        pinImageView.contentMode = .scaleAspectFit
        pinImageView.tintColor = Color.App.accentUIColor
        pinImageView.accessibilityIdentifier = "pinImageViewThreadPinMessageView"

        textButton.translatesAutoresizingMaskIntoConstraints = false
        textButton.titleLabel?.font = UIFont.fBody
        textButton.titleLabel?.numberOfLines = 1
        textButton.contentHorizontalAlignment = Language.isRTL ? .right : .left
        textButton.setTitleColor(Color.App.textPrimaryUIColor, for: .normal)
        textButton.setTitleColor(Color.App.textPrimaryUIColor?.withAlphaComponent(0.5), for: .highlighted)
        textButton.accessibilityIdentifier = "textButtonThreadPinMessageView"
        textButton.addTarget(self, action: #selector(onPinMessageTapped), for: .touchUpInside)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.accessibilityIdentifier = "imageViewThreadPinMessageView"

        unpinButton.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "xmark")
        unpinButton.imageView.image = image
        unpinButton.imageView.contentMode = .scaleAspectFit
        unpinButton.imageView.tintColor = Color.App.iconSecondaryUIColor
        unpinButton.accessibilityIdentifier = "unpinButtonThreadPinMessageView"
        unpinButton.action = { [weak self] in
            self?.onUnpinMessageTapped()
        }
        axis = .horizontal
        spacing = 8
        alignment = .center
        layoutMargins = .init(horizontal: 8)
        isLayoutMarginsRelativeArrangement = true
        show(show: viewModel?.hasPinMessage == true)

        addArrangedSubview(bar)
        addArrangedSubview(pinImageView)
        addArrangedSubview(imageView)
        addArrangedSubview(textButton)
        addArrangedSubview(unpinButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),
            bar.widthAnchor.constraint(equalToConstant: 3),
            bar.heightAnchor.constraint(equalToConstant: 24),
            pinImageView.widthAnchor.constraint(equalToConstant: 14),
            pinImageView.heightAnchor.constraint(equalToConstant: 14),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            unpinButton.widthAnchor.constraint(equalToConstant: 28),
            unpinButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    public func onUpdate() {
        set()
    }

    @objc func onPinMessageTapped(_ sender: UIButton) {
        viewModel?.moveToPinnedMessage()
    }

    @objc func onUnpinMessageTapped() {
        guard let viewModel = viewModel else { return }
        viewModel.unpinMessage(viewModel.message?.messageId ?? -1)
    }

    func set() {
        guard let viewModel = viewModel else { return }
        show(show: viewModel.hasPinMessage == true)
        if let image = viewModel.image {
            imageView.image = image
            imageView.layer.cornerRadius = 4
        } else if let icon = viewModel.icon {
            let image = UIImage(systemName: icon)
            imageView.image = image
            imageView.tintColor = Color.App.textSecondaryUIColor
            imageView.layer.cornerRadius = 0
        }
        textButton.setTitle(viewModel.title, for: .normal)
        imageView.setIsHidden(viewModel.image == nil && viewModel.icon == nil)
        unpinButton.setIsHidden(!viewModel.canUnpinMessage)
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
        }
    }
}
