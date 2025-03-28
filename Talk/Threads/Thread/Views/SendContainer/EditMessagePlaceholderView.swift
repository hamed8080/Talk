//
//  EditMessagePlaceholderView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import ChatModels
import Combine

public final class EditMessagePlaceholderView: UIStackView {
    private let messageImageView = UIImageView()
    private let messageLabel = UILabel()
    private let nameLabel = UILabel()
    public weak var superViewStack: UIStackView?

    private weak var viewModel: ThreadViewModel?
    private var sendVM: SendContainerViewModel { viewModel?.sendContainerViewModel ?? .init() }
    private var cancellableSet = Set<AnyCancellable>()
    private var animator: FadeInOutAnimator?

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
        layoutMargins = .init(horizontal: 8, vertical: 8)
        isLayoutMarginsRelativeArrangement = true
        translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.uiiransansBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1
        nameLabel.accessibilityIdentifier = "nameLabelSEditMessagePlaceholderView"
        nameLabel.setContentHuggingPriority(.required, for: .vertical)

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2
        messageLabel.accessibilityIdentifier = "messageLabelEditMessagePlaceholderView"

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.alignment = .leading
        vStack.accessibilityIdentifier = "vStackEditMessagePlaceholderView"
        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(messageLabel)

        let staticEditImageView = UIImageButton(imagePadding: .init(all: 8))
        staticEditImageView.isUserInteractionEnabled = false
        staticEditImageView.imageView.image = UIImage(systemName: "pencil")
        staticEditImageView.translatesAutoresizingMaskIntoConstraints = false
        staticEditImageView.imageView.tintColor = Color.App.accentUIColor
        staticEditImageView.contentMode = .scaleAspectFit
        staticEditImageView.accessibilityIdentifier = "staticEditImageViewEditMessagePlaceholderView"

        messageImageView.layer.cornerRadius = 4
        messageImageView.layer.masksToBounds = true
        messageImageView.contentMode = .scaleAspectFit
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.accessibilityIdentifier = "messageImageViewEditMessagePlaceholderView"
        messageImageView.setIsHidden(true)

        let closeButton = CloseButtonView()
        closeButton.accessibilityIdentifier = "closeButtonEditMessagePlaceholderView"
        closeButton.action = { [weak self] in
            self?.close()
        }

        addArrangedSubview(staticEditImageView)
        addArrangedSubview(messageImageView)
        addArrangedSubview(vStack)
        addArrangedSubview(closeButton)
        messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        NSLayoutConstraint.activate([
            messageImageView.widthAnchor.constraint(equalToConstant: 36),
            messageImageView.heightAnchor.constraint(equalToConstant: 36),
            staticEditImageView.widthAnchor.constraint(equalToConstant: 36),
            staticEditImageView.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    public func registerObservers() {
        sendVM.modePublisher.sink { [weak self] newMode in
            self?.set(editMessage: newMode.editMessage)
        }
        .store(in: &cancellableSet)
    }
    
    private func set(editMessage: Message?) {
        animator?.cancelAnimation()
        if let editMessage = editMessage {
            animator = FadeInOutAnimator(view: self)
            if superview == nil {
                superViewStack?.insertArrangedSubview(self, at: 0)
            }
            animator?.startAnimation(show: true)
            setValues(editMessage: editMessage)
        } else {
            animator = FadeInOutAnimator(view: self)
            animator?.startAnimation(show: false)
        }
    }
    
    private func setValues(editMessage: Message) {
        let iconName = editMessage.iconName
        let isFileType = editMessage.isFileType == true
        let isImage = editMessage.isImage == true
        messageImageView.layer.cornerRadius = isImage ? 4 : 16
        messageLabel.text = editMessage.message ?? ""
        nameLabel.text = editMessage.participant?.name
        nameLabel.setIsHidden(editMessage.participant?.name == nil)

        if isImage, let uniqueId = editMessage.uniqueId {
            setImage(uniqueId)
        } else if isFileType, let iconName = iconName {
            messageImageView.image = UIImage(systemName: iconName)
            messageImageView.setIsHidden(false)
        } else {
            messageImageView.image = nil
            messageImageView.setIsHidden(true)
        }
    }

    private func close() {
        viewModel?.sendContainerViewModel.setEditMessage(message: nil)
        viewModel?.delegate?.openEditMode(nil) // close the UI and show normal send buttons
        viewModel?.scrollVM.disableExcessiveLoading()
        sendVM.clear()
    }
    
    private func setImage(_ uniqueId: String) {
        guard let fileURL = viewModel?.historyVM.sectionsHolder.sections.messageViewModel(for: uniqueId)?.calMessage.fileURL else { return }
        Task.detached {
            if let scaledImage = fileURL.imageScale(width: 36)?.image {
                await MainActor.run {
                    self.messageImageView.image = UIImage(cgImage: scaledImage)
                    self.messageImageView.setIsHidden(false)
                }
            }
        }
    }
}
