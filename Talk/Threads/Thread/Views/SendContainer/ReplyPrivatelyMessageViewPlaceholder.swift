//
//  ReplyPrivatelyMessageViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI

public final class ReplyPrivatelyMessagePlaceholderView: UIStackView {
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private weak var viewModel: ThreadViewModel?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 2)
        isLayoutMarginsRelativeArrangement = true
        alignment = .center

        let imageReply = UIImageButton(imagePadding: .init(all: 4))
        imageReply.translatesAutoresizingMaskIntoConstraints = false
        imageReply.imageView.image = UIImage(systemName: "arrow.turn.up.left")
        imageReply.imageView.contentMode = .scaleAspectFit
        imageReply.imageView.tintColor = Color.App.accentUIColor
        imageReply.accessibilityIdentifier = "imageReplyReplyPrivatelyMessagePlaceholderView"
        addArrangedSubview(imageReply)

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .leading
        vStack.accessibilityIdentifier = "vStackReplyPrivatelyMessagePlaceholderView"

        nameLabel.font = UIFont.uiiransansBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1
        nameLabel.accessibilityIdentifier = "nameLabelPrivatelyMessagePlaceholderView"
        vStack.addArrangedSubview(nameLabel)

        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2
        vStack.addArrangedSubview(messageLabel)

        addArrangedSubview(vStack)

        let closeButton = CloseButtonView()
        closeButton.accessibilityIdentifier = "closeButtonPrivatelyMessagePlaceholderView"
        closeButton.action = { [weak self] in
            self?.close()
        }
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            imageReply.widthAnchor.constraint(equalToConstant: 28),
            imageReply.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    public func set() {
        let hasReplyPrivately = AppState.shared.appStateNavigationModel.replyPrivately != nil
        setIsHidden(!hasReplyPrivately)
        let replyMessage = AppState.shared.appStateNavigationModel.replyPrivately
        nameLabel.text = replyMessage?.participant?.name
        nameLabel.setIsHidden(replyMessage?.participant?.name == nil)
        Task {
            let message = replyMessage?.message ?? replyMessage?.fileMetaData?.name ?? ""
            await MainActor.run {
                messageLabel.text = message
            }
        }
    }

    private func close() {
        viewModel?.scrollVM.disableExcessiveLoading()
        AppState.shared.appStateNavigationModel = .init()
        UIView.animate(withDuration: 0.3) {
            self.set()
        }
    }
}
