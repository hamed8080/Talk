//
//  FooterView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import UIKit

final class FooterView: UIStackView {
    // Views
    private let pinImage = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let timelabel = UILabel()
    private static let editImage = UIImage(named: "ic_edit_no_tail")
    private let editedImageView = UIImageView()
    private let statusImage = UIImageView()

    // Models
    private static let staticEditString = "Messages.Footer.edited".bundleLocalized()
    private var shapeLayer = CAShapeLayer()
    private var rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
    private var viewModel: MessageRowViewModel?

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        spacing = ConstantSizes.messageFooterViewStackSpacing
        axis = .horizontal
        alignment = .center
        distribution = .fill
        layoutMargins = .init(horizontal: 8, vertical: 0)
        isLayoutMarginsRelativeArrangement = true
        semanticContentAttribute = Language.isRTL || isMe ? .forceRightToLeft : .forceLeftToRight
        isOpaque = true

        pinImage.translatesAutoresizingMaskIntoConstraints = false
        pinImage.tintColor = Color.App.accentUIColor
        pinImage.contentMode = .scaleAspectFit
        pinImage.accessibilityIdentifier = "pinImageFooterView"
        pinImage.setContentHuggingPriority(.required, for: .vertical)
        pinImage.setContentHuggingPriority(.required, for: .horizontal)
        pinImage.setContentCompressionResistancePriority(.required, for: .horizontal)
        pinImage.isOpaque = true

        if isMe {
            statusImage.translatesAutoresizingMaskIntoConstraints = false
            statusImage.contentMode = .scaleAspectFit
            statusImage.accessibilityIdentifier = "statusImageFooterView"
            addArrangedSubview(statusImage)
            statusImage.widthAnchor.constraint(equalToConstant: ConstantSizes.messageFooterViewStatusWidth).isActive = true
            statusImage.heightAnchor.constraint(equalToConstant: ConstantSizes.messageFooterItemHeight).isActive = true
        }

        timelabel.translatesAutoresizingMaskIntoConstraints = false
        timelabel.font = UIFont.bold(.caption2)
        timelabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.5)
        timelabel.accessibilityIdentifier = "timelabelFooterView"
        timelabel.isOpaque = true
        timelabel.textAlignment = .right
        timelabel.setContentCompressionResistancePriority(.required + 1, for: .horizontal)
        timelabel.setContentHuggingPriority(.required, for: .horizontal)
        addArrangedSubview(timelabel)

        editedImageView.image = FooterView.editImage
        editedImageView.translatesAutoresizingMaskIntoConstraints = false
        editedImageView.accessibilityIdentifier = "editedImageViewFooterView"
        editedImageView.isOpaque = true
        editedImageView.contentMode = .scaleAspectFit
        editedImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        editedImageView.tintColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.5)
        editedImageView.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ConstantSizes.messageFooterViewHeightWithReaction),
            timelabel.heightAnchor.constraint(equalToConstant: ConstantSizes.messageFooterItemHeight),
            timelabel.widthAnchor.constraint(greaterThanOrEqualToConstant: ConstantSizes.messageFooterViewTimeLabelWidth)
        ])
    }
    
    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let message = viewModel.message
        setStatusImageOrUploadingAnimation(viewModel: viewModel)
        timelabel.text = viewModel.calMessage.timeString
        attachOrdetachEditLabel(isEdited: viewModel.message.edited == true)
        let isPin = message.id != nil && message.id == viewModel.threadVM?.thread.pinMessage?.id
        attachOrdetachPinImage(isPin: isPin)
    }

    private func setStatusImageOrUploadingAnimation(viewModel: MessageRowViewModel) {
        // Prevent crash if we don't check is me it will crash, due to the fact that only isMe has message status
        if viewModel.calMessage.isMe {
            let statusTuple = viewModel.message.uiFooterStatus
            statusImage.image = statusTuple.image
            statusImage.tintColor = statusTuple.fgColor

            if viewModel.message is UploadProtocol, viewModel.fileState.isUploading {
                startSendingAnimation()
            } else {
                stopSendingAnimation()
            }
        }
    }

    private func attachOrdetachPinImage(isPin: Bool) {
        if isPin, pinImage.superview == nil {
            insertArrangedSubview(pinImage, at: 0)
            pinImage.heightAnchor.constraint(equalToConstant: ConstantSizes.messageFooterItemHeight).isActive = true
            pinImage.widthAnchor.constraint(equalToConstant: ConstantSizes.messageFooterViewPinWidth).isActive = true
        } else if !isPin {
            pinImage.removeFromSuperview()
        }
    }

    private func attachOrdetachEditLabel(isEdited: Bool) {
        if isEdited, pinImage.superview == nil {
            addArrangedSubview(editedImageView)
            editedImageView.heightAnchor.constraint(equalToConstant: ConstantSizes.messageFooterItemHeight).isActive = true
            editedImageView.widthAnchor.constraint(equalToConstant: ConstantSizes.messageFooterViewEditImageWidth).isActive = true
        } else if !isEdited {
            editedImageView.removeFromSuperview()
        }
    }

    public func edited() {
        attachOrdetachEditLabel(isEdited: true)
    }

    public func pinChanged(isPin: Bool) {
        attachOrdetachPinImage(isPin: isPin)
        UIView.animate(withDuration: 0.2) {
            self.pinImage.alpha = isPin ? 1.0 : 0.0
            self.pinImage.setIsHidden(!isPin)
        }
    }

    public func sent(image: UIImage?) {
        self.statusImage.setIsHidden(false)
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
        UIView.transition(with: statusImage, duration: 0.2, options: .transitionCrossDissolve) {
            self.statusImage.image = image
        }
    }

    public func delivered(image: UIImage?) {
        self.statusImage.setIsHidden(false)
        UIView.transition(with: statusImage, duration: 0.2, options: .transitionCrossDissolve) {
            self.statusImage.image = image
        }
    }

    public func seen(image: UIImage?) {
        statusImage.setIsHidden(false)
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
        UIView.transition(with: statusImage, duration: 0.2, options: .transitionCrossDissolve) {
            self.statusImage.image = image
        }
    }

    private func startSendingAnimation() {
        rotateAnimation.repeatCount = .greatestFiniteMagnitude
        rotateAnimation.isCumulative = true
        rotateAnimation.toValue = 2 * CGFloat.pi
        rotateAnimation.duration = 1.5
        rotateAnimation.fillMode = .forwards

        statusImage.layer.add(rotateAnimation, forKey: "rotationAnimation")
    }

    private func stopSendingAnimation() {
        statusImage.layer.removeAllAnimations()
    }
}
