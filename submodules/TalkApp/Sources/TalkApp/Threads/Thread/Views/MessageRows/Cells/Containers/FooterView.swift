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
    private let editedLabel = UILabel()
    private let statusImage = UIImageView()
    private let reactionView: FooterReactionsCountView

    // Models
    private static let staticEditString = "Messages.Footer.edited".bundleLocalized()
    private var statusImageWidthConstriant: NSLayoutConstraint?
    private var shapeLayer = CAShapeLayer()
    private var rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
    private var viewModel: MessageRowViewModel?

    // Constraints
    private var heightConstraint: NSLayoutConstraint!

    init(frame: CGRect, isMe: Bool) {
        self.reactionView = .init(frame: frame, isMe: isMe)
        super.init(frame: frame)
        configureView(isMe: isMe)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        spacing = MessageRowSizes.messageFooterViewStackSpacing
        axis = .horizontal
        alignment = .bottom
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        isOpaque = true

        reactionView.translatesAutoresizingMaskIntoConstraints = false

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
            statusImageWidthConstriant = statusImage.widthAnchor.constraint(equalToConstant: MessageRowSizes.messageFooterViewNormalStatusWidth)
            statusImageWidthConstriant?.isActive = true
            statusImageWidthConstriant?.identifier = "statusImageWidthConstriantFooterView"
            statusImage.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageFooterViewStatusHeight).isActive = true
        }

        timelabel.translatesAutoresizingMaskIntoConstraints = false
        timelabel.font = UIFont.fBoldCaption2
        timelabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.5)
        timelabel.accessibilityIdentifier = "timelabelFooterView"
        timelabel.isOpaque = true
        timelabel.setContentCompressionResistancePriority(.required + 1, for: .horizontal)
        timelabel.setContentHuggingPriority(.required, for: .horizontal)
        addArrangedSubview(timelabel)

        editedLabel.translatesAutoresizingMaskIntoConstraints = false
        editedLabel.font = UIFont.fCaption2
        editedLabel.textColor = Color.App.textSecondaryUIColor
        editedLabel.text = FooterView.staticEditString
        editedLabel.accessibilityIdentifier = "editedLabelFooterView"
        editedLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        editedLabel.setContentHuggingPriority(.required, for: .horizontal)
        editedLabel.isOpaque = true

        heightConstraint = heightAnchor.constraint(equalToConstant: MessageRowSizes.messageFooterViewHeightWithReaction)
        NSLayoutConstraint.activate([
            heightConstraint,
            timelabel.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageFooterViewStatusHeight),
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
        attachOrDetachReactions(viewModel: viewModel, animation: false)
    }

    private func setStatusImageOrUploadingAnimation(viewModel: MessageRowViewModel) {
        // Prevent crash if we don't check is me it will crash, due to the fact that only isMe has message status
        if viewModel.calMessage.isMe {
            let statusTuple = viewModel.message.uiFooterStatus
            statusImage.image = statusTuple.image
            statusImage.tintColor = statusTuple.fgColor
            statusImageWidthConstriant?.constant = viewModel.message.seen == true ? MessageRowSizes.messageFooterViewSeenWidth : MessageRowSizes.messageFooterViewNormalStatusWidth

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
            pinImage.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageFooterViewStatusHeight).isActive = true
            pinImage.widthAnchor.constraint(equalToConstant: MessageRowSizes.messageFooterViewPinWidth).isActive = true
        } else if !isPin {
            pinImage.removeFromSuperview()
        }
    }

    private func attachOrdetachEditLabel(isEdited: Bool) {
        if isEdited, pinImage.superview == nil {
            addArrangedSubview(editedLabel)
            editedLabel.heightAnchor.constraint(equalToConstant: MessageRowSizes.messageFooterViewStatusHeight).isActive = true
        } else if !isEdited {
            editedLabel.removeFromSuperview()
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
        statusImageWidthConstriant?.constant = MessageRowSizes.messageFooterViewNormalStatusWidth
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
        statusImageWidthConstriant?.constant = MessageRowSizes.messageFooterViewSeenWidth
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

    private func attachOrDetachReactions(viewModel: MessageRowViewModel, animation: Bool) {
        let isEmpty = viewModel.reactionsModel.rows.isEmpty
        let edited = viewModel.message.edited == true
        let attached = reactionView.superview == nil
        if isEmpty || (edited && attached) {
            reactionView.removeFromSuperview()// reset
        }
        
        if !isEmpty {
            /// We don't attach the footer to prevent height conflict with not reaction time
            addArrangedSubview(reactionView)
            fadeAnimateReactions(animation)
            reactionView.set(viewModel)
        }
        heightConstraint.constant = isEmpty ? MessageRowSizes.messageFooterViewHeightWithoutReaction : MessageRowSizes.messageFooterViewHeightWithReaction
    }

    // Prevent animation in reuse call method, yet has animation when updateReaction called
    private func fadeAnimateReactions(_ animation: Bool) {
        if !animation { return }
        reactionView.alpha = 0.0
        UIView.animate(withDuration: 0.2, delay: 0.2) {
            self.reactionView.alpha = 1.0
        }
    }

    public func reactionsUpdated(viewModel: MessageRowViewModel){
        attachOrDetachReactions(viewModel: viewModel, animation: true)
    }
    
    public func reactionDeleted(_ reaction: Reaction) {
        reactionView.reactionDeleted(reaction)
        heightConstraint.constant = viewModel?.reactionsModel.rows.isEmpty == true ? MessageRowSizes.messageFooterViewHeightWithoutReaction : MessageRowSizes.messageFooterViewHeightWithReaction
    }
    
    public func reactionAdded(_ reaction: Reaction) {
        if reactionView.superview == nil {
            addArrangedSubview(reactionView)
            reactionView.alpha = 1.0
            if let viewModel = viewModel {
                reactionView.set(viewModel)
            }
        } else {
            reactionView.reactionAdded(reaction)
        }
        heightConstraint.constant = viewModel?.reactionsModel.rows.isEmpty == true ? MessageRowSizes.messageFooterViewHeightWithoutReaction : MessageRowSizes.messageFooterViewHeightWithReaction
    }
    
    public func reactionReplaced(_ reaction: Reaction) {
        reactionView.reactionReplaced(reaction)
        heightConstraint.constant = viewModel?.reactionsModel.rows.isEmpty == true ? MessageRowSizes.messageFooterViewHeightWithoutReaction : MessageRowSizes.messageFooterViewHeightWithReaction
    }
}
