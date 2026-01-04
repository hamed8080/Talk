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
import Combine

class DetailInfoTopSectionView: UIView {
    /// Views
    private let avatar = UIImageView(frame: .zero)
    private let avatarInitialLabel = UILabel()
    private let titleLabel = UILabel()
    private let participantCountLabel = UILabel()
    private let lastSeenLabel = UILabel()
    private let approvedIcon = UIImageView(image: UIImage(named: "ic_approved"))
    private let selfThreadImageView = SelfThreadIconView(imageSize: 64, iconSize: 28)
    private let downloadingAvatarProgress = UIActivityIndicatorView()
    
    /// Models
    public weak var viewModel: ThreadDetailViewModel?
    private var cancellableSet: Set<AnyCancellable> = Set()
    
    init(viewModel: ThreadDetailViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        register()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func configureViews() {
        setContentCompressionResistancePriority(.required, for: .vertical)
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        backgroundColor = Color.App.bgSecondaryUIColor
        
        let isGroup = viewModel?.thread?.group == true
        let stack = isGroup ? groupStackStyle() : p2pStackStyle()
        addSubview(stack)
        
        /// Avatar or user name abbrevation
        avatar.accessibilityIdentifier = "DetailInfoTopSectionView.avatar"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 24
        avatar.layer.masksToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.isUserInteractionEnabled = true
        avatar.setContentCompressionResistancePriority(.required, for: .vertical)
        let avatarGesture = UITapGestureRecognizer(target: self, action: #selector(onAvatarTapped))
        avatar.addGestureRecognizer(avatarGesture)
        
        downloadingAvatarProgress.translatesAutoresizingMaskIntoConstraints = false
        downloadingAvatarProgress.isHidden = true
        downloadingAvatarProgress.isUserInteractionEnabled = false
        downloadingAvatarProgress.stopAnimating()
        addSubview(downloadingAvatarProgress)
        
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
        titleLabel.font = UIFont.bold(.body)
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        lastSeenLabel.translatesAutoresizingMaskIntoConstraints = false
        lastSeenLabel.font = UIFont.bold(.caption3)
        lastSeenLabel.textColor = Color.App.accentUIColor
        lastSeenLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        participantCountLabel.translatesAutoresizingMaskIntoConstraints = false
        participantCountLabel.font = UIFont.normal(.caption3)
        participantCountLabel.textColor = Color.App.textSecondaryUIColor
        participantCountLabel.textAlignment = Language.isRTL ? .right : .left
        
        approvedIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(approvedIcon)
        
        bringSubviewToFront(downloadingAvatarProgress)
    
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            avatar.widthAnchor.constraint(equalToConstant: 64),
            avatar.heightAnchor.constraint(equalToConstant: 64),
            
            downloadingAvatarProgress.widthAnchor.constraint(equalTo: avatar.widthAnchor),
            downloadingAvatarProgress.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            downloadingAvatarProgress.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            downloadingAvatarProgress.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            
            selfThreadImageView.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            selfThreadImageView.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            
            avatarInitialLabel.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            avatarInitialLabel.trailingAnchor.constraint(equalTo: avatar.trailingAnchor),
            avatarInitialLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            
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
        let isGroup = thread?.group == true
        
        titleLabel.text = threadName
        
        let showLastSeen = lastSeenString != nil && !isGroup
        lastSeenLabel.text = lastSeenString
        lastSeenLabel.isHidden = !showLastSeen
        if !showLastSeen {
            lastSeenLabel.frame.size.height = 0.0
        }
        
        participantCountLabel.text = countString
        participantCountLabel.isHidden = countString == nil
        if countString == nil {          
            participantCountLabel.frame.size.height = 0.0
        }
        
        if isSelfThread || !isGroup {
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
    
    private func groupStackStyle() -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 8
        stack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        stack.axis = .horizontal
        
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.distribution = .fillEqually
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        stack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(participantCountLabel)
        
        stack.addArrangedSubview(avatar)
        stack.addArrangedSubview(vStack)
        
        return stack
    }
    
    private func p2pStackStyle() -> UIStackView {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.alignment = .center
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        vStack.addArrangedSubview(avatar)
        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(lastSeenLabel)
        
        return vStack
    }
    
    private var lastSeenString: String? {
        guard
            let notSeenString = viewModel?.participantDetailViewModel?.notSeenString
        else { return nil }
        let localized = "Contacts.lastVisited".bundleLocalized()
        let formatted = String(format: localized, notSeenString)
        return formatted
    }

    private var countString: String? {
        guard
            let count = viewModel?.thread?.participantCount,
            let localCountString = count.localNumber(locale: Language.preferredLocale)
        else { return nil }
        let label = "Thread.Toolbar.participants".bundleLocalized()
        return "\(localCountString ?? "") \(label)"
    }
    
    private func register() {
        viewModel?.$showDownloading
            .sink { [weak self] showDownloading in
                guard let self = self else { return }
                downloadingAvatarProgress.isHidden = !showDownloading
                if showDownloading {
                    downloadingAvatarProgress.startAnimating()
                } else {
                    downloadingAvatarProgress.stopAnimating()
                }
            }
            .store(in: &cancellableSet)
        
        viewModel?.objectWillChange
            .sink { [weak self] _ in
                self?.setValues()
            }
            .store(in: &cancellableSet)
    }
    
    @objc private func onAvatarTapped() {
        viewModel?.onTapAvatarAction()
    }
}
