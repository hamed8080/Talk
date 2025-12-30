//
//  DetailInfoTopSectionView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/28/25.
//

import UIKit
import SwiftUI
import TalkFont
import TalkUI

class DetailInfoTopSectionView: UIView {
    /// Views
    private let avatar = UIImageView(frame: .zero)
    private let avatarInitialLabel = UILabel()
    private let titleLabel = UILabel()
    private let participantCountLabel = UILabel()
    private let lastSeenLabel = UILabel()
    private let approvedIcon = UIImageView(image: UIImage(named: "ic_approved"))
    private let selfThreadImageView = SelfThreadIconView(imageSize: 64, iconSize: 28)
    
    /// Models
    public weak var viewModel: ThreadDetailViewModel?
    
    init(viewModel: ThreadDetailViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        /// Avatar or user name abbrevation
        avatar.accessibilityIdentifier = "DetailInfoTopSectionView.avatar"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 24
        avatar.layer.masksToBounds = true
        avatar.contentMode = .scaleAspectFill
        addSubview(avatar)
        
        /// User initial over the avatar image if the image is nil.
        avatarInitialLabel.accessibilityIdentifier = "DetailInfoTopSectionView.avatarInitialLabel"
        avatarInitialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLabel.layer.cornerRadius = 22
        avatarInitialLabel.layer.masksToBounds = true
        avatarInitialLabel.textAlignment = .center
        avatarInitialLabel.font = UIFont.bold(.subheadline)
        avatarInitialLabel.textColor = Color.App.whiteUIColor
        addSubview(avatarInitialLabel)
        
        selfThreadImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selfThreadImageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.normal(.body)
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        addSubview(titleLabel)
        
        lastSeenLabel.translatesAutoresizingMaskIntoConstraints = false
        lastSeenLabel.font = UIFont.normal(.caption3)
        addSubview(lastSeenLabel)
        
        participantCountLabel.translatesAutoresizingMaskIntoConstraints = false
        participantCountLabel.font = UIFont.normal(.caption3)
        participantCountLabel.textColor = Color.App.textSecondaryUIColor
        participantCountLabel.textAlignment = Language.isRTL ? .right : .left
        addSubview(participantCountLabel)
        
        approvedIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(approvedIcon)
    
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 72),
            
            avatar.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            avatar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 64),
            avatar.heightAnchor.constraint(equalToConstant: 64),
            
            selfThreadImageView.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            selfThreadImageView.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            
            avatarInitialLabel.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            avatarInitialLabel.trailingAnchor.constraint(equalTo: avatar.trailingAnchor),
            avatarInitialLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor, constant: -14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            participantCountLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
            participantCountLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor, constant: 14),
            
            approvedIcon.widthAnchor.constraint(equalToConstant: 16),
            approvedIcon.heightAnchor.constraint(equalToConstant: 16),
            approvedIcon.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            approvedIcon.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 0)
        ])
        
        setValues()
    }
    
    public func setValues() {
        
        let thread = viewModel?.threadVM?.thread
        let titleString = thread?.titleRTLString.stringToScalarEmoji()
        let contactName = viewModel?.participantDetailViewModel?.participant.contactName
        let threadName = contactName ?? titleString
        let isSelfThread = thread?.type == .selfThread
        let lastSeenString = lastSeenString
        let countString = countString
        let title = thread?.computedTitle
        let materialBackground = String.getMaterialColorByCharCode(str: title ?? "")
        let splitedTitle = String.splitedCharacter(title ?? "")
        let vm = viewModel?.avatarVM
        let readyOrSelfThread = vm?.isImageReady == true || isSelfThread
        
        
        titleLabel.text = threadName
        
        lastSeenLabel.text = lastSeenString
        if lastSeenString == nil {
            lastSeenLabel.isHidden = true
            lastSeenLabel.frame.size.height = 0.0
        }
        
        participantCountLabel.text = countString
        if countString == nil {
            participantCountLabel.isHidden = true
            participantCountLabel.frame.size.height = 0.0
        }
        
        if isSelfThread {
            participantCountLabel.isHidden = true
        }
        
        if !isSelfThread {
            selfThreadImageView.isHidden = true
            selfThreadImageView.frame.size.height = 0.0
        }
        
        avatarInitialLabel.isHidden = readyOrSelfThread
        avatarInitialLabel.text = readyOrSelfThread ? nil : splitedTitle
        avatar.backgroundColor = readyOrSelfThread ? nil : materialBackground
        avatar.image = isSelfThread ? UIImage(named: "self_thread") : readyOrSelfThread ? vm?.image : nil
        
        approvedIcon.isHidden = thread?.isTalk ?? false == false
    }

    private var lastSeenString: String? {
        if viewModel?.thread?.group == true { return nil }
        if let notSeenString = viewModel?.participantDetailViewModel?.notSeenString {
            let localized = "Contacts.lastVisited".bundleLocalized()
            let formatted = String(format: localized, notSeenString)
            lastSeenLabel.text = formatted
        }
        return nil
    }

    private var countString: String? {
        guard
            let count = viewModel?.thread?.participantCount,
            let localCountString = count.localNumber(locale: Language.preferredLocale)
        else { return nil }
        let label = "Thread.Toolbar.participants".bundleLocalized()
        return "\(localCountString ?? "") \(label)"
    }
}
