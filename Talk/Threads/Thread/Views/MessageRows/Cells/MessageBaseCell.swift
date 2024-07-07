//
//  MessageBaseCell.swift
//  Talk
//
//  Created by hamed on 6/6/24.
//

import Foundation
import TalkViewModels
import UIKit
import TalkModels
import SwiftUI

public class MessageBaseCell: UITableViewCell {
    weak var viewModel: MessageRowViewModel?
    private let container = UIView()
    private var avatar: AvatarView?
    private let radio = SelectMessageRadio()
    public private(set) var messageContainer: MessageContainerStackView!
    private var containerWidthConstraint: NSLayoutConstraint!
    private var messageContainerBottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let isMe = self is MyselfMessageCell
        self.messageContainer = .init(frame: contentView.bounds, isMe: isMe)
        configureView(isMe: isMe)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView(isMe: Bool) {
        selectionStyle = .none // Prevent iOS selection background color view added we use direct background color on content view instead of selectedBackgroundView or backgroundView
        contentView.isUserInteractionEnabled = true
        contentView.addSubview(container)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        container.accessibilityIdentifier = "containerMessageBaseCell"

        radio.translatesAutoresizingMaskIntoConstraints = false
        radio.accessibilityIdentifier = "radioMessageBaseCell"

        if self is PartnerMessageCell {
            avatar = AvatarView(frame: .zero)
        }

        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        messageContainer.accessibilityIdentifier = "messageContainerMessageBaseCell"
        container.addSubview(messageContainer)
        messageContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 1).isActive = true
        messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: ThreadViewModel.maxAllowedWidth).isActive = true
        messageContainerBottomConstraint = messageContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1)
        messageContainerBottomConstraint.identifier = "messageContainerBottomConstraintMessageBaseCell"
        messageContainerBottomConstraint.isActive = true

        // 53 for avatar/tail to make the container larger to be clickable, this view is invisible and we should see it on view debugger hierarchy
        containerWidthConstraint = container.widthAnchor.constraint(equalTo: messageContainer.widthAnchor, constant: isMe ? 0 : 53)
        containerWidthConstraint.isActive = true
        container.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true
        let isMe = self is MyselfMessageCell
        let isRTL = Language.isRTL
        if (isRTL && isMe) || (!isRTL && !isMe) {
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        } else {
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
        }
    }

    private func attachOrDetachRadio(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.state.isInSelectMode {
            radio.removeFromSuperview()
        } else if viewModel.calMessage.state.isInSelectMode, radio.superview == nil {
            container.addSubview(radio)
            radio.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            radio.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10).isActive = true
        }
        radio.set(selected: viewModel.calMessage.state.isSelected, viewModel: viewModel)
    }

    private func attachOrDetachAvatar(viewModel: MessageRowViewModel) {
        if let avatar = avatar, !viewModel.calMessage.state.isInSelectMode, viewModel.threadVM?.thread.group == true {
            avatar.updateSelectionMode()
            self.avatar?.translatesAutoresizingMaskIntoConstraints = false
            self.avatar?.accessibilityIdentifier = "avatarContainerMessageBaseCell"
            container.addSubview(avatar)
            if viewModel.calMessage.isMe {
                avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8).isActive = true
            } else {
                avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8).isActive = true
            }
            avatar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8).isActive = true
        } else if avatar?.superview != nil, viewModel.calMessage.state.isInSelectMode {
            avatar?.removeFromSuperview()
        }
        avatar?.set(viewModel)
    }

    private func attachOrDetachMessageContainer(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.state.isInSelectMode, let avatar = avatar, viewModel.threadVM?.thread.group == true {
            messageContainer.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8).isActive = true
        } else if viewModel.calMessage.state.isInSelectMode {
            messageContainer.leadingAnchor.constraint(equalTo: radio.trailingAnchor, constant: 0).isActive = true
        }
        messageContainer.set(viewModel)
        messageContainer.cell = self
        if viewModel.calMessage.isMe && !viewModel.calMessage.state.isInSelectMode {
            containerWidthConstraint.constant = 0
        } else {
            containerWidthConstraint.constant = 53
        }
    }

    public func setValues(viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        messageContainerBottomConstraint.constant = viewModel.calMessage.isLastMessageOfTheUser ? -6 : -1
        attachOrDetachAvatar(viewModel: viewModel)
        attachOrDetachRadio(viewModel: viewModel)
        attachOrDetachMessageContainer(viewModel: viewModel)
        setSelectedBackground()
    }

    func deselect() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self, let viewModel = viewModel else { return }
            viewModel.calMessage.state.isSelected = false
            radio.set(selected: false, viewModel: viewModel)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateSelectionView()
        }
    }

    func select() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self, let viewModel = viewModel else { return }
            viewModel.calMessage.state.isSelected = true
            radio.set(selected: true, viewModel: viewModel)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateSelectionView()
        }
    }

    func setInSelectionMode(_ isInSelectionMode: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            if let viewModel = viewModel {
                attachOrDetachAvatar(viewModel: viewModel)
                attachOrDetachRadio(viewModel: viewModel)
                attachOrDetachMessageContainer(viewModel: viewModel)
            }
            messageContainer.isUserInteractionEnabled = !isInSelectionMode
            if !isInSelectionMode {
                deselect()
            }
        }
    }

    private func setSelectedBackground() {
        guard let viewModel = viewModel else { return }
        if viewModel.calMessage.state.isHighlited || viewModel.calMessage.state.isSelected {
            let dark = traitCollection.userInterfaceStyle == .dark
            let selectedColor = dark ? Color.App.accentUIColor?.withAlphaComponent(0.4) : Color.App.dividerPrimaryUIColor?.withAlphaComponent(0.5)
            contentView.backgroundColor = selectedColor
        } else {
            contentView.backgroundColor = nil
        }
    }

    public func setImage(_ image: UIImage) {
        avatar?.setImage(image: image)
    }

    public func edited() {
        messageContainer.edited()
    }

    public func pinChanged() {
        messageContainer.pinChanged()
    }

    public func sent() {
        messageContainer.sent()
    }
    
    public func delivered() {
        messageContainer.delivered()
    }

    public func seen() {
        messageContainer.seen()
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        messageContainer.updateProgress(viewModel: viewModel)
    }

    public func updateThumbnail(viewModel: MessageRowViewModel) {
        messageContainer.updateThumbnail(viewModel: viewModel)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        messageContainer.downloadCompleted(viewModel: viewModel)
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        messageContainer.uploadCompleted(viewModel: viewModel)
    }

    public func setHighlight() {
        UIView.animate(withDuration: 0.2) {
            self.setSelectedBackground()
        }
    }

    public func reactionsUpdated(viewModel: MessageRowViewModel) {
        messageContainer.reactionsUpdated(viewModel: viewModel)
    }
}
