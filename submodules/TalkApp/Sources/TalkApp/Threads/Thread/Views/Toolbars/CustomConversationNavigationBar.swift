//
//  CustomConversationNavigationBar.swift
//  Talk
//
//  Created by hamed on 6/20/24.
//

import Foundation
import TalkViewModels
import UIKit
import TalkUI
import SwiftUI
import Combine
import Chat

public class CustomConversationNavigationBar: UIView {
    private weak var viewModel: ThreadViewModel?
    private let backButton = UIImageButton(imagePadding: .init(all: 6))
    private let fullScreenButton = UIImageButton(imagePadding: .init(all: 6))
    private let titlebutton = UIButton(type: .system)
    #if DEBUG
    private let revokeButton = UIButton(type: .system)
    #endif
    private let subtitleLabel = UILabel()
    private var threadImageButton = UIImageButton(imagePadding: .init(all: 0))
    private var threadTitleSupplementary = UILabel()
    private var centerYTitleConstraint: NSLayoutConstraint!
    private let gradientLayer = CAGradientLayer()
    private var cancellableSet: Set<AnyCancellable> = Set()
    private var imageLoader: ImageLoaderViewModel?

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        Task {
            await registerObservers()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        titlebutton.translatesAutoresizingMaskIntoConstraints = false
        titlebutton.setAttributedTitle(titleAttributedStirng, for: .normal)
        titlebutton.titleLabel?.font = UIFont.fBoldBody
        titlebutton.setTitleColor(Color.App.textPrimaryUIColor, for: .normal)
        titlebutton.accessibilityIdentifier = "titlebuttonCustomConversationNavigationBar"
        titlebutton.addTarget(self, action: #selector(navigateToDetailView), for: .touchUpInside)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = Color.App.textSecondaryUIColor
        subtitleLabel.font = UIFont.fFootnote
        subtitleLabel.accessibilityIdentifier = "subtitleLabelCustomConversationNavigationBar"

        let isSelfThread = viewModel?.thread.type == .selfThread
        if isSelfThread {
            threadImageButton = UIImageButton(imagePadding: .init(all: 8))
            threadImageButton.accessibilityIdentifier = "threadImageButtonCustomConversationNavigationBar"
            let startColor = UIColor(red: 255/255, green: 145/255, blue: 98/255, alpha: 1.0)
            let endColor = UIColor(red: 255/255, green: 90/255, blue: 113/255, alpha: 1.0)
            gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
            gradientLayer.startPoint = .init(x: 0, y: 0)
            gradientLayer.endPoint = .init(x: 1.0, y: 1.0)
            threadImageButton.imageView.image = UIImage(named: "bookmark")
            threadImageButton.imageView.tintColor = Color.App.textPrimaryUIColor
            threadImageButton.layer.addSublayer(gradientLayer)
            threadImageButton.bringSubviewToFront(threadImageButton.imageView)
            threadTitleSupplementary.accessibilityIdentifier = "threadTitleSupplementaryCustomConversationNavigationBar"
            threadTitleSupplementary.setIsHidden(true)
        }
        threadImageButton.translatesAutoresizingMaskIntoConstraints = false
        threadImageButton.layer.cornerRadius = 17
        threadImageButton.layer.masksToBounds = true
        threadImageButton.imageView.layer.cornerRadius = 8
        threadImageButton.imageView.layer.masksToBounds = true
        threadImageButton.imageView.contentMode  = .scaleAspectFill
        threadImageButton.accessibilityIdentifier = "threadImageButtonCustomConversationNavigationBar"
        threadImageButton.action = { [weak self] in
            self?.navigateToDetailView()
        }

        threadTitleSupplementary.translatesAutoresizingMaskIntoConstraints = false
        threadTitleSupplementary.font = UIFont.fCaption3
        threadTitleSupplementary.textColor = .white
        threadTitleSupplementary.accessibilityIdentifier = "threadTitleSupplementaryCustomConversationNavigationBar"

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.imageView.image = UIImage(systemName: "chevron.backward")
        backButton.imageView.tintColor = Color.App.accentUIColor
        backButton.imageView.contentMode = .scaleAspectFit
        backButton.accessibilityIdentifier = "backButtonCustomConversationNavigationBar"
        backButton.action = { [weak self] in
            (self?.viewModel?.delegate as? UIViewController)?.navigationController?.popViewController(animated: true)
        }

        fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullScreenButton.imageView.image = UIImage(systemName: "sidebar.leading")
        fullScreenButton.imageView.tintColor = Color.App.accentUIColor
        fullScreenButton.imageView.contentMode = .scaleAspectFit
        fullScreenButton.accessibilityIdentifier = "backButtonCustomConversationNavigationBar"
        fullScreenButton.action = {
            AppState.isInSlimMode = UIApplication.shared.windowMode().isInSlimMode
            NotificationCenter.closeSideBar.post(name: Notification.Name.closeSideBar, object: nil)
        }

        addSubview(backButton)
        addSubview(fullScreenButton)
        addSubview(threadImageButton)
        addSubview(threadTitleSupplementary)
        addSubview(titlebutton)
        addSubview(subtitleLabel)

        centerYTitleConstraint = titlebutton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
        centerYTitleConstraint.identifier = "centerYTitleConstraintCustomConversationNavigationBar"
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 46),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            backButton.widthAnchor.constraint(equalToConstant: 36),

            fullScreenButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            fullScreenButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            fullScreenButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            fullScreenButton.widthAnchor.constraint(equalToConstant: 36),

            threadImageButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            threadImageButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            threadImageButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            threadImageButton.widthAnchor.constraint(equalToConstant: 38),

            threadTitleSupplementary.centerXAnchor.constraint(equalTo: threadImageButton.centerXAnchor),
            threadTitleSupplementary.centerYAnchor.constraint(equalTo: threadImageButton.centerYAnchor),

            titlebutton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            titlebutton.trailingAnchor.constraint(equalTo: threadImageButton.leadingAnchor, constant: -4),
            centerYTitleConstraint,
            titlebutton.heightAnchor.constraint(equalToConstant: 16),

            subtitleLabel.centerXAnchor.constraint(equalTo: titlebutton.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titlebutton.bottomAnchor, constant: -4),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4),
        ])
        
#if DEBUG
        revokeButton.translatesAutoresizingMaskIntoConstraints = false
        revokeButton.setTitle("revoke", for: .normal)
        revokeButton.titleLabel?.font = UIFont.fBoldBody
        revokeButton.setTitleColor(Color.App.textPrimaryUIColor, for: .normal)
        revokeButton.accessibilityIdentifier = "titlebuttonCustomConversationNavigationBar"
        revokeButton.addTarget(self, action: #selector(revokeButtonTapped), for: .touchUpInside)
        addSubview(revokeButton)
        NSLayoutConstraint.activate([
            revokeButton.trailingAnchor.constraint(equalTo: threadImageButton.leadingAnchor, constant: 4),
            revokeButton.widthAnchor.constraint(equalToConstant: 64),
            revokeButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            revokeButton.topAnchor.constraint(equalTo: topAnchor),
        ])
#endif
    }

    @objc private func navigateToDetailView() {
        guard let viewModel = viewModel else { return }
        
        /// Reattch the participant info if we are inside a simulated thread.
        /// Note: After leaving the thread info with a participant where we didn't have any chat,
        /// the userToCreateThread will be deleted by back button, so we have to reattach this.
        if viewModel.id == LocalId.emptyThread.rawValue {
            AppState.shared.appStateNavigationModel.userToCreateThread = viewModel.participant
        }
        AppState.shared.objectsContainer.navVM.appendThreadDetail(threadViewModel: viewModel)
    }

    public func updateTitleTo(_ title: String?) {
        UIView.animate(withDuration: 0.2) {
            self.titlebutton.setAttributedTitle(self.titleAttributedStirng, for: .normal)
        }
        updateThreadImage()
    }
    
    private var titleAttributedStirng: NSAttributedString {
        let title = viewModel?.thread.titleRTLString ?? ""
        let replacedEmoji = title.stringToScalarEmoji()
        let replacedDoubleQuotation = replacedEmoji.strinDoubleQuotation()
        
        let attributedString = NSMutableAttributedString(string: replacedDoubleQuotation)
        if viewModel?.thread.isTalk == true {
            attributedString.append(NSAttributedString(string: " ")) // Space
            
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(named: "ic_approved")
            imageAttachment.bounds = CGRect(x: 0, y: -6, width: 18, height: 18)
            let imageString = NSAttributedString(attachment: imageAttachment)
            attributedString.append(imageString)
        }
        return attributedString
    }
    
    private func subtilteAttributedStirng(text: String?, smt: SMT?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "")
        
        if let iconName = smt?.eventImage, smt != .isTyping {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate).withTintColor(Color.App.accentUIColor ?? .orange)
            imageAttachment.bounds = CGRect(x: 0, y: -6, width: 18, height: 18)
            let imageString = NSAttributedString(attachment: imageAttachment)
            attributedString.append(imageString)
        }
        
        attributedString.append(NSAttributedString(string: " \(text ?? "")")) // Space
        
        return attributedString
    }

    public func updateSubtitleTo(_ subtitle: String?, _ smt: SMT?) {
        let hide = subtitle == nil
        subtitleLabel.setIsHidden(hide)
        self.subtitleLabel.attributedText = subtilteAttributedStirng(text: subtitle, smt: smt)
        subtitleLabel.textColor = smt != nil ? Color.App.accentUIColor : Color.App.textSecondaryUIColor
        self.centerYTitleConstraint.constant = hide ? 0 : -8
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    public func updateImageTo(_ image: UIImage?) {
        UIView.transition(with: threadImageButton.imageView, duration: 0.2, options: .transitionCrossDissolve) { [weak self] in
            guard let self = self else { return }
            threadImageButton.imageView.image = image
            let isEmpty = image == nil || image?.size.width ?? 0 == 0
            if isEmpty {
                Task { [weak self] in
                    await self?.setSplitedText()
                    let isImageReady = self?.imageLoader?.isImageReady == true
                    self?.hideImageUserNameSplitedLable(isHidden: isImageReady)
                }
            } else {
                hideImageUserNameSplitedLable(isHidden: true)
            }
        }
    }

    public func refetchImageOnUpdateInfo() {
        Task {
            await fetchImageOnUpdateInfo()
        }
    }

    public func fetchImageOnUpdateInfo() async {
        guard let link = await getImageLink() else { return }
        if let imageViewModel = viewModel?.threadsViewModel?.avatars(for: link, metaData: nil, userName: nil) {
            self.imageLoader = imageViewModel

            // Set first time opening the thread image from cahced version inside avatarVMS
            let image = imageViewModel.image
            updateImageTo(image)

            // Observe for new changes
            self.imageLoader?.$image.sink { [weak self] newImage in
                guard let self = self else { return }
                updateImageTo(newImage)
            }
            .store(in: &cancellableSet)

            if !imageViewModel.isImageReady {
                imageViewModel.fetch()
            }
        }
    }

    private func setSplitedText() async {
        let splitedText = String.splitedCharacter(self.viewModel?.thread.title ?? "")
        let bg = String.getMaterialColorByCharCode(str: self.viewModel?.thread.computedTitle ?? "")
        await MainActor.run {
            self.threadImageButton.layer.backgroundColor = bg.cgColor
            self.threadTitleSupplementary.text = splitedText
        }
    }
    
    private func registerObservers() async {
        // Initial image from avatarVMS inside the thread
        let link = await getImageLink()
        if let link = link, let _ = viewModel?.threadsViewModel?.avatars(for: link, metaData: nil, userName: nil) {
            await fetchImageOnUpdateInfo()
        } else {
            await setSplitedText()
        }
    }
    
    @AppBackgroundActor
    private func getImageLink() async -> String? {
        let copiedThread = await viewModel?.thread
        let image = await viewModel?.thread.image ?? copiedThread?.metaData?.file?.link
        let httpsImage = image?.replacingOccurrences(of: "http://", with: "https://")
        return httpsImage
    }

    private func updateThreadImage() {
        let newImage = viewModel?.thread.image
        if let newImage = newImage, imageLoader?.config.url != newImage {
            imageLoader?.updateCondig(config: .init(url: newImage))
            imageLoader?.fetch()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = threadImageButton.bounds
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let showFullScreenButton = traitCollection.horizontalSizeClass == .regular && traitCollection.userInterfaceIdiom == .pad
        fullScreenButton.setIsHidden(!showFullScreenButton)
    }

    private func hideImageUserNameSplitedLable(isHidden: Bool) {
        threadTitleSupplementary.setIsHidden(isHidden)
    }

    @objc private func revokeButtonTapped() {
        Task { @ChatGlobalActor in
            await ChatManager.activeInstance?.setToken(newToken: "revoked_token", reCreateObject: false)
        }
    }
}
