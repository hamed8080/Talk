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
    weak var stack: UIStackView?

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
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

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
        vStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        nameLabel.font = UIFont.normal(.body)
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1
        nameLabel.accessibilityIdentifier = "nameLabelPrivatelyMessagePlaceholderView"
        vStack.addArrangedSubview(nameLabel)

        messageLabel.font = UIFont.normal(.caption2)
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2
        messageLabel.textAlignment = Language.isRTL ? .right : .left
        vStack.addArrangedSubview(messageLabel)

        addArrangedSubview(vStack)

        let closeButton = CloseButtonView()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.accessibilityIdentifier = "closeButtonPrivatelyMessagePlaceholderView"
        closeButton.action = { [weak self] in
            self?.close()
        }
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            imageReply.widthAnchor.constraint(equalToConstant: 28),
            imageReply.heightAnchor.constraint(equalToConstant: 28),
            closeButton.widthAnchor.constraint(equalToConstant: 42),
            closeButton.heightAnchor.constraint(equalToConstant: 42),
        ])
    }

    public func set() {
        let show = AppState.shared.objectsContainer.navVM.navigationProperties.replyPrivately != nil
        if !show {
            removeFromSuperViewWithAnimation()
        } else if superview == nil {
            alpha = 0.0
            stack?.insertArrangedSubview(self, at: 0)
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
            }
        }
        let replyMessage = AppState.shared.objectsContainer.navVM.navigationProperties.replyPrivately
        nameLabel.text = replyMessage?.participant?.name
        nameLabel.setIsHidden(replyMessage?.participant?.name == nil)
        Task { [weak self] in
            guard let self = self else { return }
            let message = replyMessage?.fileMetaData?.name ?? replyMessage?.message ?? ""
            await MainActor.run {
                messageLabel.text = message
            }
        }
    }

    private func close() {
        viewModel?.scrollVM.disableExcessiveLoading()
        AppState.shared.objectsContainer.navVM.resetNavigationProperties()
        UIView.animate(withDuration: 0.3) {
            self.set()
        }
    }
}
