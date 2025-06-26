//
//  ForwardMessagesViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

public final class ForwardMessagePlaceholderView: UIStackView {
    private let staticForwardLabel = UILabel()
    private let messageLabel = UILabel()
    private weak var viewModel: ThreadViewModel?
    weak var stack: UIStackView?

    private var isSingleForward: Bool {
        return AppState.shared.appStateNavigationModel.forwardMessageRequest?.messageIds.count == 1
    }

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
        vStack.accessibilityIdentifier = "vStackForwardMessagePlaceholderView"

        staticForwardLabel.textColor = Color.App.accentUIColor
        staticForwardLabel.numberOfLines = 1
        staticForwardLabel.font = UIFont.fCaption
        staticForwardLabel.accessibilityIdentifier = "staticForwardLabelForwardMessagePlaceholderView"

        messageLabel.font = UIFont.fCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2
        messageLabel.accessibilityIdentifier = "messageLabelForwardMessagePlaceholderView"

        vStack.addArrangedSubview(staticForwardLabel)
        vStack.addArrangedSubview(messageLabel)

        let imageForward = UIImageButton(imagePadding: .init(all: 4))
        imageForward.translatesAutoresizingMaskIntoConstraints = false
        imageForward.imageView.image = UIImage(systemName: "arrow.turn.up.right")
        imageForward.imageView.tintColor = Color.App.accentUIColor
        imageForward.imageView.contentMode = .scaleAspectFit
        imageForward.accessibilityIdentifier = "imageForwardForwardMessagePlaceholderView"

        let closeButton = CloseButtonView()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.accessibilityIdentifier = "closeButtonForwardMessagePlaceholderView"
        closeButton.action = { [weak self] in
            self?.close()
        }

        let spacer = UIView(frame: .init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))
        spacer.accessibilityIdentifier = "spacerForwardMessagePlaceholderView"
        addArrangedSubview(imageForward)
        addArrangedSubview(vStack)
        addArrangedSubview(spacer)
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            imageForward.widthAnchor.constraint(equalToConstant: 28),
            imageForward.heightAnchor.constraint(equalToConstant: 28),
            closeButton.widthAnchor.constraint(equalToConstant: 42),
            closeButton.heightAnchor.constraint(equalToConstant: 42),
        ])
    }

    public func set() {
        let model = AppState.shared.appStateNavigationModel
        let show = model.forwardMessageRequest != nil
        if !show {
            removeFromSuperViewWithAnimation()
        } else if superview == nil {
            alpha = 0.0
            stack?.insertArrangedSubview(self, at: 0)
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
            }
        }
        if isSingleForward {
            staticForwardLabel.text = "Thread.forwardTheMessage".bundleLocalized()
            let message = model.forwardMessages?.first?.message ?? ""
            messageLabel.text = message
        } else {
            let localized = "Thread.forwardMessages".bundleLocalized()
            let localNumber = (model.forwardMessages?.count ?? 0).localNumber(locale: Language.preferredLocale) ?? ""
            let staticMessage = String(format: localized, localNumber)
            staticForwardLabel.text = staticMessage
            let splittedMessages = model.forwardMessages?.prefix(4).compactMap({$0.message?.prefix(20)}).joined(separator: ", ")
            messageLabel.text = splittedMessages
        }
    }

    private func close() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            AppState.shared.appStateNavigationModel = .init()
            viewModel?.selectedMessagesViewModel.clearSelection()
            viewModel?.sendContainerViewModel.clear()
            set()
        }
    }
}
