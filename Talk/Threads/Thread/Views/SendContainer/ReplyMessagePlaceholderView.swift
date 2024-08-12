//
//  ReplyMessagePlaceholderView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

public final class ReplyMessagePlaceholderView: UIStackView {
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

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .leading
        vStack.accessibilityIdentifier = "vStackReplyMessagePlaceholderView"

        nameLabel.font = UIFont.uiiransansBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1
        nameLabel.accessibilityIdentifier = "nameLabelReplyMessagePlaceholderView"

        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2
        messageLabel.accessibilityIdentifier = "messageLabelReplyMessagePlaceholderView"

        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(messageLabel)

        let imageReply = UIImageButton(imagePadding: .init(all: 4))
        imageReply.translatesAutoresizingMaskIntoConstraints = false
        imageReply.imageView.image = UIImage(systemName: "arrow.turn.up.left")
        imageReply.imageView.tintColor = Color.App.accentUIColor
        imageReply.imageView.contentMode = .scaleAspectFit
        imageReply.accessibilityIdentifier = "imageReplyReplyMessagePlaceholderView"

        let closeButton = CloseButtonView()
        closeButton.accessibilityIdentifier = "closeButtonReplyMessagePlaceholderView"
        closeButton.action = { [weak self] in
            self?.close()
        }

        addArrangedSubview(imageReply)
        addArrangedSubview(vStack)
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            imageReply.widthAnchor.constraint(equalToConstant: 28),
            imageReply.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    public func set(stack: UIStackView) {
        let replyMessage = viewModel?.replyMessage
        let showReply = replyMessage != nil
        alpha = showReply ? 0.0 : 1.0
        if showReply {
            stack.insertArrangedSubview(self, at: 0)
        }
        UIView.animate(withDuration: 0.2) {
            self.alpha = showReply ? 1.0 : 0.0
            self.setIsHidden(!showReply)
        } completion: { completed in
            if completed, !showReply {
                self.removeFromSuperview()
            }
        }

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
        viewModel?.replyMessage = nil
        viewModel?.selectedMessagesViewModel.clearSelection()
        viewModel?.delegate?.openReplyMode(nil) // close the UI
    }
}
