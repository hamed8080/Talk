//
//  ConversationCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import SwiftUI
import Chat
import TalkUI

class ConversationCell: UITableViewCell {
    private var conversation: CalculatedConversation?
    weak var delegate: UIThreadsViewControllerDelegate?
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let radio = SelectMessageRadio()
    private let timeLabel = UILabel(frame: .zero)
    private let avatar = UIImageView(frame: .zero)
    private let statusImageView = UIImageView(frame: .zero)
    private let avatarInitialLable = UILabel()
    private let pinImageView = UIImageView(image: UIImage(named: "ic_pin"))
    private let muteImageView = UIImageView(image: UIImage(systemName: "bell.slash.fill"))
    private let unreadCountLabel = UnreadCountAnimateableUILabel()
    private let closedImageView = UIImageView(image: UIImage(systemName: "lock"))
    private let mentionLable = UILabel(frame: .zero)
    private var radioIsHidden = true
    private let barView = UIView()
    
    // MARK: Constraints
    private var statusWidthConstraint = NSLayoutConstraint()
    private var statusHeightConstraint = NSLayoutConstraint()
    private var timeLabelWidthConstraint = NSLayoutConstraint()
    private var unreadCountLabelWidthConstraint = NSLayoutConstraint()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = 0.3
        addGestureRecognizer(longGesture)
        
        barView.backgroundColor = Color.App.accentUIColor
        barView.translatesAutoresizingMaskIntoConstraints = false
        barView.alpha = 0.0
        contentView.addSubview(barView)
        
        /// Title of the conversation.
        titleLabel.font = UIFont.fBoldSubheadline
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.accessibilityIdentifier = "ConversationCell.titleLable"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        /// Last message of the thread or drafted message or event of the thread label.
        subtitleLabel.font = UIFont.fBody
        subtitleLabel.textColor = Color.App.textSecondaryUIColor
        subtitleLabel.accessibilityIdentifier = "ConversationCell.titleLable"
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textAlignment = Language.isRTL ? .right : .left
        subtitleLabel.numberOfLines = 1
        contentView.addSubview(subtitleLabel)
        
        /// Selection radio
        radio.accessibilityIdentifier = "ConversationCell.radio"
        radio.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(radio)
        
        /// Avatar or user name abbrevation
        avatar.accessibilityIdentifier = "ConversationCell.avatar"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 24
        avatar.layer.masksToBounds = true
        avatar.contentMode = .scaleAspectFill
        contentView.addSubview(avatar)
        
        /// User initial over the avatar image if the image is nil.
        avatarInitialLable.accessibilityIdentifier = "ConversationCell.avatarInitialLable"
        avatarInitialLable.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLable.layer.cornerRadius = 22
        avatarInitialLable.layer.masksToBounds = true
        avatarInitialLable.textAlignment = .center
        avatarInitialLable.font = UIFont.fBoldSubheadline
        contentView.addSubview(avatarInitialLable)
        
        /// Status of a message either sent/seen or none.
        statusImageView.accessibilityIdentifier = "ConversationCell.statusImageView"
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusWidthConstraint = statusImageView.widthAnchor.constraint(equalToConstant: 24)
        statusHeightConstraint = statusImageView.heightAnchor.constraint(equalToConstant: 24)
        contentView.addSubview(statusImageView)
        
        /// Time of the last message of the conversation.
        timeLabel.accessibilityIdentifier = "ConversationCell.timeLabel"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.fBoldCaption2
        timeLabel.numberOfLines = 1
        timeLabelWidthConstraint = timeLabel.widthAnchor.constraint(equalToConstant: 64)
        contentView.addSubview(timeLabel)
        
        /// Pin image view.
        pinImageView.accessibilityIdentifier = "ConversationCell.pinImageView"
        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.contentMode = .scaleAspectFit
        
        /// Unread count label.
        unreadCountLabel.accessibilityIdentifier = "ConversationCell.unreadCountLabel"
        unreadCountLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadCountLabel.label.font = UIFont.fBoldBody
        unreadCountLabel.label.numberOfLines = 1
        unreadCountLabelWidthConstraint = unreadCountLabel.widthAnchor.constraint(equalToConstant: 0)
        unreadCountLabel.layer.masksToBounds = true
        unreadCountLabel.label.textAlignment = .center
        
        /// Mute image view.
        muteImageView.accessibilityIdentifier = "ConversationCell.muteImageView"
        muteImageView.translatesAutoresizingMaskIntoConstraints = false
        muteImageView.contentMode = .scaleAspectFit
        muteImageView.tintColor = Color.App.iconSecondaryUIColor
        
        /// Closed thread image view.
        closedImageView.accessibilityIdentifier = "ConversationCell.closedImageView"
        closedImageView.translatesAutoresizingMaskIntoConstraints = false
        closedImageView.contentMode = .scaleAspectFit
        closedImageView.tintColor = Color.App.textSecondaryUIColor
        closedImageView.isHidden = true
        
        /// Mention sign label.
        mentionLable.accessibilityIdentifier = "ConversationCell.mentionLable"
        mentionLable.text = "@"
        mentionLable.textAlignment = .center
        mentionLable.translatesAutoresizingMaskIntoConstraints = false
        mentionLable.isHidden = true
        mentionLable.layer.cornerRadius = 12
        mentionLable.layer.masksToBounds = true
        mentionLable.textColor = .white
        mentionLable.backgroundColor = Color.App.accentUIColor
        
        let secondRowTrailingStack = UIStackView(
            arrangedSubviews: [
                pinImageView,
                unreadCountLabel,
                muteImageView,
                closedImageView,
                mentionLable,
            ]
        )
        
        secondRowTrailingStack.translatesAutoresizingMaskIntoConstraints = false
        secondRowTrailingStack.accessibilityIdentifier = "ConversationCell.secondRowTrailingStack"
        secondRowTrailingStack.axis = .horizontal
        secondRowTrailingStack.spacing = 4
        secondRowTrailingStack.alignment = .center
        contentView.addSubview(secondRowTrailingStack)
        
        NSLayoutConstraint.activate([
            barView.widthAnchor.constraint(equalToConstant: 4),
            barView.topAnchor.constraint(equalTo: contentView.topAnchor),
            barView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            barView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            radio.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radio.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 58),
            avatar.heightAnchor.constraint(equalToConstant: 58),
            
            avatarInitialLable.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarInitialLable.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarInitialLable.widthAnchor.constraint(equalToConstant: 52),
            avatarInitialLable.heightAnchor.constraint(equalToConstant: 52),
            
            titleLabel.bottomAnchor.constraint(equalTo: avatar.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: statusImageView.leadingAnchor, constant: -8),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: 0),
            subtitleLabel.trailingAnchor.constraint(equalTo: secondRowTrailingStack.leadingAnchor, constant: -8),
            
            statusImageView.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            statusWidthConstraint,
            statusHeightConstraint,
            statusImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            timeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            timeLabel.heightAnchor.constraint(equalToConstant: 16),
            timeLabelWidthConstraint,
            
            pinImageView.widthAnchor.constraint(equalToConstant: 16),
            pinImageView.heightAnchor.constraint(equalToConstant: 16),
            
            unreadCountLabelWidthConstraint,
            unreadCountLabel.heightAnchor.constraint(equalToConstant: 24),
            
            muteImageView.widthAnchor.constraint(equalToConstant: 16),
            muteImageView.heightAnchor.constraint(equalToConstant: 16),
            
            closedImageView.widthAnchor.constraint(equalToConstant: 16),
            closedImageView.heightAnchor.constraint(equalToConstant: 16),
            
            mentionLable.widthAnchor.constraint(equalToConstant: 24),
            mentionLable.heightAnchor.constraint(equalToConstant: 24),
            
            secondRowTrailingStack.centerYAnchor.constraint(equalTo: subtitleLabel.centerYAnchor),
            secondRowTrailingStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
        
        radio.isHidden = radioIsHidden
        if radioIsHidden {
            radio.removeFromSuperview()
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        }
    }
    
    public func setConversation(conversation: CalculatedConversation) {
        self.conversation = conversation
        titleLabel.attributedText = conversation.titleRTLString
        subtitleLabel.attributedText = conversation.subtitleAttributedString
        
        if let image = conversation.iconStatus {
            statusImageView.image = image
            let isSeen = image != MessageHistoryStatics.sentImage
            statusImageView.tintColor = isSeen ? Color.App.whiteUIColor : conversation.iconStatusColor ?? .black
            statusWidthConstraint.constant = isSeen ? 24 : 12
            statusHeightConstraint.constant = isSeen ? 24 : 12
        } else {
            statusImageView.image = nil
            statusWidthConstraint.constant = 0
        }
        
        let vm = conversation.imageLoader as? ImageLoaderViewModel
        let readyOrSelfThread = vm?.isImageReady == true || conversation.type == .selfThread
        avatarInitialLable.isHidden = readyOrSelfThread
        avatarInitialLable.text = readyOrSelfThread ? nil : conversation.splitedTitle
        avatar.backgroundColor = readyOrSelfThread ? nil : conversation.materialBackground
        avatar.image = conversation.type == .selfThread ? UIImage(named: "self_thread") : readyOrSelfThread ? vm?.image : nil
        
        timeLabel.text = conversation.timeString
        timeLabel.textColor = conversation.isSelected ? Color.App.textPrimaryUIColor : Color.App.iconSecondaryUIColor
        timeLabelWidthConstraint.constant = timeLabel.sizeThatFits(.init(width: 64, height: 24)).width
        
        pinImageView.isHidden = !(conversation.pin == true && conversation.hasSpaceToShowPin)
        muteImageView.isHidden = conversation.mute == false || conversation.mute == nil
        
        unreadCountLabel.label.text = conversation.unreadCountString
        unreadCountLabelWidthConstraint.constant = conversation.unreadCountString.isEmpty ? 0 : conversation.isCircleUnreadCount ? 24 : unreadCountLabel.label.sizeThatFits(.init(width: 128, height: 24)).width + 24
        unreadCountLabel.label.textColor = conversation.mute == true ? Color.App.whiteUIColor : Color.App.textPrimaryUIColor
        unreadCountLabel.backgroundColor = conversation.mute == true ? Color.App.iconSecondaryUIColor : Color.App.accentUIColor
        unreadCountLabel.layer.cornerRadius = conversation.isCircleUnreadCount ? 12 : 10
        
        closedImageView.isHidden = !(conversation.closed == true)
        
        barView.alpha = conversation.isSelected ? 1.0 : 0.0
        
        mentionLable.isHidden = !(conversation.mentioned == true)
        
        contentView.backgroundColor = conversation.isSelected ? Color.App.bgChatSelectedUIColor : conversation.pin == true ? Color.App.bgSecondaryUIColor : Color.App.bgPrimaryUIColor
    }
    
    public func setImage(_ image: UIImage?) {
        avatar.image = image
        avatarInitialLable.isHidden = image != nil
    }
    
    func selectionChanged(conversation: CalculatedConversation) {
        barView.alpha = conversation.isSelected ? 1.0 : 0.0
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.contentView.backgroundColor =
            conversation.isSelected ? Color.App.bgChatSelectedUIColor :
            conversation.pin == true ? Color.App.bgSecondaryUIColor : Color.App.bgPrimaryUIColor
        }
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.barView.alpha = conversation.isSelected ? 1.0 : 0.0
        }
        
        timeLabel.textColor = conversation.isSelected ? Color.App.textPrimaryUIColor : Color.App.iconSecondaryUIColor
    }
    
    func unreadCountChanged(conversation: CalculatedConversation) {
        unreadCountLabel.label.addFlipAnimation(text: conversation.unreadCountString)
        unreadCountLabelWidthConstraint.constant = conversation.unreadCountString.isEmpty ? 0 : unreadCountLabel.label.sizeThatFits(.init(width: 128, height: 24)).width + 24
        unreadCountLabel.layer.cornerRadius = conversation.isCircleUnreadCount ? 12 : 10
    }
    
    func setEvent(_ smt: SMT?, _ conversation: CalculatedConversation) {
        if let smt = smt {
            Task { [weak self] in
                guard let self = self else { return }
                if smt == .isTyping {
                    let string = smt.stringEvent?.bundleLocalized().replacingOccurrences(of: "...", with: "") ?? ""
                    var step = 0
                    for i in 1...9 {
                        let repeated = String(Array(repeating: ".", count: step))
                        subtitleLabel.attributedText = NSAttributedString(string: "\(string)\(repeated)", attributes: [.foregroundColor: Color.App.accentUIColor])
                        try await Task.sleep(for: .seconds(0.5))
                        step = step + 1
                        if step > 3 {
                            step = 0
                        }
                    }
                    
                    /// Reset subtitle back to normal after tree times showing animation.
                    subtitleLabel.attributedText = conversation.subtitleAttributedString
                }
            }
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setTouches(isBegan: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setTouches(isBegan: false)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setTouches(isBegan: false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        setTouches(isBegan: false)
    }
    
    private func setTouches(isBegan: Bool) {
        let scale = isBegan ? 0.98 : 1.0
        let selectedColor = Color.App.bgChatSelectedUIColor
        let pinColor = Color.App.bgSecondaryUIColor
        let normalColor = Color.App.bgPrimaryUIColor
        let touchColor = selectedColor?.withAlphaComponent(0.3)
        
        let isSelected = conversation?.isSelected == true
        let isPin = conversation?.pin == true
        
        let bg = isBegan ? touchColor : isSelected ? selectedColor : isPin ? pinColor : normalColor
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.contentView.backgroundColor = bg
        }
    }
    
    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        guard
            sender.state == .began,
            let indexPath = delegate?.indexPath(for: self),
                let conversation = delegate?.dataSourceItem(for: indexPath)
        else { return }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        delegate?.showContextMenu(
            indexPath,
            contentView: ThreadRowContextMenuUIKit(conversation: conversation, image: avatar.image, container: delegate?.contextMenuContainer)
        )
    }
}
