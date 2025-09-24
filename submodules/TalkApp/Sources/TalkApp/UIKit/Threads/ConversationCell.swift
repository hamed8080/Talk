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

class ConversationCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let radio = SelectMessageRadio()
    private let timeLabel = UILabel(frame: .zero)
    private let avatar = UIImageView(frame: .zero)
    private let statusImageView = UIImageView(frame: .zero)
    private let avatarInitialLable = UILabel()
    private let pinImageView = UIImageView(image: UIImage(named: "ic_pin"))
    private let muteImageView = UIImageView(image: UIImage(systemName: "bell.slash.fill"))
    private let unreadCountLabel = UILabel(frame: .zero)
    private let closedImageView = UIImageView(image: UIImage(systemName: "lock"))
    private var radioIsHidden = true
    
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
        unreadCountLabel.font = UIFont.fBoldBody
        unreadCountLabel.numberOfLines = 1
        unreadCountLabelWidthConstraint = unreadCountLabel.widthAnchor.constraint(equalToConstant: 16)
        unreadCountLabel.layer.masksToBounds = true
        unreadCountLabel.textAlignment = .center
        
        /// Mute image view.
        muteImageView.accessibilityIdentifier = "ConversationCell.muteImageView"
        muteImageView.translatesAutoresizingMaskIntoConstraints = false
        muteImageView.contentMode = .scaleAspectFit
        
        /// Closed thread image view.
        closedImageView.accessibilityIdentifier = "ConversationCell.closedImageView"
        closedImageView.translatesAutoresizingMaskIntoConstraints = false
        closedImageView.contentMode = .scaleAspectFit
        closedImageView.tintColor = Color.App.textSecondaryUIColor
        closedImageView.isHidden = true
        
        let secondRowTrailingStack = UIStackView(
            arrangedSubviews: [
                pinImageView,
                unreadCountLabel,
                muteImageView,
                closedImageView
            ]
        )
        
        secondRowTrailingStack.translatesAutoresizingMaskIntoConstraints = false
        secondRowTrailingStack.accessibilityIdentifier = "ConversationCell.secondRowTrailingStack"
        secondRowTrailingStack.axis = .horizontal
        secondRowTrailingStack.spacing = 4
        secondRowTrailingStack.alignment = .center
        contentView.addSubview(secondRowTrailingStack)
        
        NSLayoutConstraint.activate([
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
            
            secondRowTrailingStack.centerYAnchor.constraint(equalTo: subtitleLabel.centerYAnchor),
            secondRowTrailingStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
        
        radio.isHidden = radioIsHidden
        if radioIsHidden {
            radio.removeFromSuperview()
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        }
    }
    
    public func setConversation(conversation: CalculatedConversation, viewModel: ThreadsViewModel) {
        titleLabel.attributedText = conversation.titleRTLString
        subtitleLabel.attributedText = conversation.fiftyFirstCharacter
        if let addOrRemoveParticipant = conversation.addRemoveParticipant {
            subtitleLabel.attributedText = NSAttributedString(string: addOrRemoveParticipant) 
        }
        
        if let image = conversation.iconStatus {
            statusImageView.image = image
            let isSeen = image != MessageHistoryStatics.sentImage
            statusImageView.tintColor = isSeen ? Color.App.whiteUIColor : conversation.iconStatusColor ?? .black
            statusWidthConstraint.constant = isSeen ? 24 : 12
            statusHeightConstraint.constant = isSeen ? 24 : 12
        } else {
            statusWidthConstraint.constant = 0
        }
        avatarInitialLable.text = String.splitedCharacter(conversation.computedTitle)
        if conversation.type == .selfThread {
            avatar.image = UIImage(named: "self_thread")
            avatarInitialLable.isHidden = true
        } else if let vm = viewModel.imageLoader(for: conversation.id ?? -1) {
            avatar.image = vm.image
            avatarInitialLable.isHidden = vm.isImageReady
        } else {
            avatarInitialLable.isHidden = false
            avatar.backgroundColor = conversation.materialBackground
        }
        
        timeLabel.text = conversation.timeString
        timeLabel.textColor = conversation.isSelected ? Color.App.textPrimaryUIColor : Color.App.iconSecondaryUIColor
        timeLabelWidthConstraint.constant = timeLabel.sizeThatFits(.init(width: 64, height: 24)).width
        
        pinImageView.isHidden = !(conversation.pin == true && conversation.hasSpaceToShowPin)
        muteImageView.isHidden = conversation.mute == false || conversation.mute == nil
        
        unreadCountLabel.text = conversation.unreadCountString
        unreadCountLabelWidthConstraint.constant = conversation.unreadCountString.isEmpty ? 0 : unreadCountLabel.sizeThatFits(.init(width: 128, height: 24)).width + 18
        unreadCountLabel.textColor = conversation.mute == true ? Color.App.whiteUIColor : Color.App.textPrimaryUIColor
        unreadCountLabel.backgroundColor = conversation.mute == true ? Color.App.iconSecondaryUIColor : Color.App.accentUIColor
        unreadCountLabel.layer.cornerRadius = conversation.isCircleUnreadCount ? 12 : 10
        
        closedImageView.isHidden = !(conversation.closed == true)
        
        contentView.backgroundColor = conversation.isSelected ? Color.App.bgChatSelectedUIColor :
        conversation.pin == true ? Color.App.bgSecondaryUIColor :
        Color.App.bgPrimaryUIColor
    }
    
    public func setImage(_ image: UIImage?) {
        avatar.image = image
        avatarInitialLable.isHidden = image != nil
    }
    
    private func appendSelectedBar() {
        let isSelected = false
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let barView = UIView()
        barView.translatesAutoresizingMaskIntoConstraints = false
        barView.backgroundColor = isSelected && isIpad ? Color.App.accentUIColor : .clear
        
        NSLayoutConstraint.activate([
            barView.widthAnchor.constraint(equalToConstant: 4),
            barView.topAnchor.constraint(equalTo: contentView.topAnchor),
            barView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            barView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        contentView.addSubview(barView)
    }
    
    override func prepareForReuse() {
        avatarInitialLable.text = ""
        avatar.image = nil
        avatar.backgroundColor = nil
        statusImageView.image = nil
        closedImageView.isHidden = true
        muteImageView.isHidden = true
        pinImageView.isHidden = true
        contentView.backgroundColor = nil
    }
}
