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
    /// Views
    private let backButton = UIImageButton(imagePadding: .init(all: 14))
    private let searchButton = UIImageButton(imagePadding: .init(all: 10))
    private let fullScreenButton = UIImageButton(imagePadding: .init(all: 6))
    private let titleLabel = UILabel()
    private let detailViewButton: UIView = UIView()
    #if DEBUG
    private let revokeButton = UIButton(type: .system)
    #endif
    private let subtitleLabel = UILabel()
    private var threadImageButton = UIImageButton(imagePadding: .init(all: 0))
    private var threadTitleSupplementary = UILabel()
    
    /// Models
    private weak var viewModel: ThreadViewModel?
    private var imageLoader: ImageLoaderViewModel?
    private var cancellableSet: Set<AnyCancellable> = Set()
    
    /// Constraints
    private var fullScreenButtonWidthConstraint: NSLayoutConstraint?
    private var centerYTitleConstraint: NSLayoutConstraint!
    private var detailViewButtonLeadingConstraint: NSLayoutConstraint?

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        Task { [weak self] in
            guard let self = self else { return }
            await registerObservers()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = false
        
        detailViewButton.translatesAutoresizingMaskIntoConstraints = false
        detailViewButton.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(navigateToDetailView))
        detailViewButton.addGestureRecognizer(gesture)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.attributedText = titleAttributedStirng
        titleLabel.font = UIFont.bold(.body)
        titleLabel.textColor = Color.App.whiteUIColor
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.accessibilityIdentifier = "titleLabelCustomConversationNavigationBar"
        detailViewButton.addSubview(titleLabel)
        
        let isLight = traitCollection.userInterfaceStyle == .light
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = Color.App.whiteUIColor?.withAlphaComponent(isLight ? 0.9 : 1.0)
        subtitleLabel.font = UIFont.normal(.footnote)
        subtitleLabel.textAlignment = Language.isRTL ? .right : .left
        subtitleLabel.accessibilityIdentifier = "subtitleLabelCustomConversationNavigationBar"
        detailViewButton.addSubview(subtitleLabel)

        let isSelfThread = viewModel?.thread.type == .selfThread
        if isSelfThread {
            threadImageButton.imageView.image = UIImage(named: "self_thread")
            threadImageButton.imageView.tintColor = Color.App.textPrimaryUIColor
            threadTitleSupplementary.isHidden = true
        }
        threadImageButton.translatesAutoresizingMaskIntoConstraints = false
        threadImageButton.layer.cornerRadius = 22
        threadImageButton.layer.masksToBounds = true
        threadImageButton.imageView.layer.cornerRadius = 22
        threadImageButton.imageView.layer.masksToBounds = true
        threadImageButton.imageView.contentMode  = .scaleAspectFill
        threadImageButton.accessibilityIdentifier = "threadImageButtonCustomConversationNavigationBar"
        threadImageButton.isUserInteractionEnabled = false
        detailViewButton.addSubview(threadImageButton)

        threadTitleSupplementary.translatesAutoresizingMaskIntoConstraints = false
        threadTitleSupplementary.font = UIFont.bold(.subheadline)
        threadTitleSupplementary.textColor = .white
        threadTitleSupplementary.accessibilityIdentifier = "threadTitleSupplementaryCustomConversationNavigationBar"
        detailViewButton.addSubview(threadTitleSupplementary)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.imageView.image = UIImage(systemName: "chevron.backward")
        backButton.imageView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        backButton.imageView.tintColor = Color.App.toolbarButtonUIColor
        backButton.imageView.contentMode = .scaleAspectFit
        backButton.accessibilityIdentifier = "backButtonCustomConversationNavigationBar"
        backButton.action = { [weak self] in
            AppState.shared.objectsContainer.threadsVM.deselectActiveThread()
            AppState.shared.objectsContainer.navVM.popCurrentViewController(id: self?.viewModel?.thread.id ?? 0)
        }
        
        let isSimulated = viewModel?.id == LocalId.emptyThread.rawValue
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.imageView.image = UIImage(systemName: "magnifyingglass")
        searchButton.imageView.tintColor = Color.App.toolbarButtonUIColor
        searchButton.imageView.contentMode = .scaleAspectFit
        searchButton.accessibilityIdentifier = "searchButtonCustomConversationNavigationBar"
        searchButton.isHidden = isSimulated
        searchButton.isUserInteractionEnabled = !isSimulated
        searchButton.action = { [weak self] in
            self?.onSearchTapped()
        }

        let showFullScreenButton = traitCollection.horizontalSizeClass == .regular && traitCollection.userInterfaceIdiom == .pad
        fullScreenButton.setIsHidden(!showFullScreenButton)
        fullScreenButton.isUserInteractionEnabled = showFullScreenButton
        fullScreenButton.setIsHidden(!showFullScreenButton)
        fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullScreenButton.imageView.image = UIImage(systemName: "sidebar.leading")
        fullScreenButton.imageView.tintColor = Color.App.toolbarButtonUIColor
        fullScreenButton.imageView.contentMode = .scaleAspectFit
        fullScreenButton.accessibilityIdentifier = "fullScreenButtonCustomConversationNavigationBar"
        fullScreenButton.action = {
            let currentState = AppState.isInSlimMode == false
            let vc = AppState.shared.objectsContainer.threadsVM.delegate as? UIViewController
            let secondaryOnly = vc?.splitViewController?.displayMode == .secondaryOnly
            if secondaryOnly {
                vc?.splitViewController?.show(.primary)
            } else {
                vc?.splitViewController?.hide(.primary)
            }
            AppState.isInSlimMode = UIApplication.shared.windowMode().isInSlimMode
            NotificationCenter.closeSideBar.post(name: Notification.Name.closeSideBar, object: nil)
        }

        addSubview(backButton)
        addSubview(fullScreenButton)
        addSubview(detailViewButton)
        addSubview(searchButton)
        
        /// If the image is not accessible anymore, at least we can show the splitted text and background.
        Task {
            await setSplitedText()
        }

        centerYTitleConstraint = titleLabel.centerYAnchor.constraint(equalTo: detailViewButton.centerYAnchor, constant: 0)
        centerYTitleConstraint.identifier = "centerYTitleConstraintCustomConversationNavigationBar"
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 64),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            backButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            fullScreenButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 0),
            fullScreenButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            fullScreenButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            detailViewButton.topAnchor.constraint(equalTo: topAnchor),
            detailViewButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            detailViewButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: 0),

            threadImageButton.topAnchor.constraint(equalTo: detailViewButton.topAnchor, constant: 4),
            threadImageButton.bottomAnchor.constraint(equalTo: detailViewButton.bottomAnchor, constant: -4),
            threadImageButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth + 8),
            threadImageButton.leadingAnchor.constraint(equalTo: detailViewButton.leadingAnchor),

            threadTitleSupplementary.centerXAnchor.constraint(equalTo: threadImageButton.centerXAnchor),
            threadTitleSupplementary.centerYAnchor.constraint(equalTo: threadImageButton.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: threadImageButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: detailViewButton.trailingAnchor, constant: -4),
            centerYTitleConstraint,
            titleLabel.heightAnchor.constraint(equalToConstant: 16),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: -4),
            subtitleLabel.bottomAnchor.constraint(equalTo: detailViewButton.bottomAnchor, constant: 4),
            
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            searchButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            searchButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            searchButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
        ])
        
        fullScreenButtonWidthConstraint = fullScreenButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth)
        fullScreenButtonWidthConstraint?.isActive = showFullScreenButton
        fullScreenButtonWidthConstraint?.constant = 42
        
        detailViewButtonLeadingConstraint = detailViewButton.leadingAnchor.constraint(equalTo: showFullScreenButton ? fullScreenButton.trailingAnchor : backButton.trailingAnchor, constant: 2)
        detailViewButtonLeadingConstraint?.isActive = true
        detailViewButtonLeadingConstraint?.constant = showFullScreenButton ? 8 : 2
        
        if !showFullScreenButton {
            fullScreenButton.removeFromSuperview()
        }
        
#if DEBUG
        revokeButton.translatesAutoresizingMaskIntoConstraints = false
        revokeButton.setTitle("revoke", for: .normal)
        revokeButton.titleLabel?.font = UIFont.bold(.body)
        revokeButton.setTitleColor(Color.App.whiteUIColor, for: .normal)
        revokeButton.accessibilityIdentifier = "titlebuttonCustomConversationNavigationBar"
        revokeButton.addTarget(self, action: #selector(revokeButtonTapped), for: .touchUpInside)
        addSubview(revokeButton)
        NSLayoutConstraint.activate([
            revokeButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -8),
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
            AppState.shared.objectsContainer.navVM.setParticipantToCreateThread(viewModel.participant)
        }
        
        let detailViewModel = ThreadDetailViewModel()
        detailViewModel.setup(threadVM: viewModel)
        let detailVC = UIHostingController(rootView: DetailViewWrapper(detailViewModel: detailViewModel).injectAllObjects())
        let navigationController = (viewModel.delegate as? ThreadViewController)?.navigationController
        
        AppState.shared.objectsContainer.navVM.appendThreadDetailUIKit(vc: detailVC,
                                                                       navigationController: navigationController,
                                                                       conversationId: viewModel.id,
                                                                       detailViewModel: detailViewModel)
    }

    public func updateTitleTo(_ title: String?) {
        UIView.animate(withDuration: 0.2) {
            self.titleLabel.attributedText = self.titleAttributedStirng
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
//        
//        if let iconName = smt?.eventImage, smt != .isTyping {
//            let imageAttachment = NSTextAttachment()
//            imageAttachment.image = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate).withTintColor(Color.App.accentUIColor ?? .orange)
//            imageAttachment.bounds = CGRect(x: 0, y: -6, width: 18, height: 18)
//            let imageString = NSAttributedString(attachment: imageAttachment)
//            attributedString.append(imageString)
//        }
//        
        attributedString.append(NSAttributedString(string: "\(text ?? "")")) // Space
        
        return attributedString
    }

    public func updateSubtitleTo(_ subtitle: String?, _ smt: SMT?) {
        let hide = subtitle == nil
        subtitleLabel.setIsHidden(hide)
        self.subtitleLabel.attributedText = subtilteAttributedStirng(text: subtitle, smt: smt)
        let isLight = traitCollection.userInterfaceStyle == .light
        subtitleLabel.textColor = smt != nil ? Color.App.accentUIColor : Color.App.whiteUIColor?.withAlphaComponent(isLight ? 0.9 : 1.0)
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
        Task { [weak self] in
            guard let self = self else { return }
            await fetchImageOnUpdateInfo()
        }
    }

    public func fetchImageOnUpdateInfo() async {
        guard let link = await getImageLink() else { return }
        if let imageViewModel = cachedImageLoaderVM {
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
        if let link = link {
            if imageLoader != nil {
                await fetchImageOnUpdateInfo()
            } else {
                createImageLoaderAndListen(link: link)
            }
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

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let showFullScreenButton = traitCollection.horizontalSizeClass == .regular && traitCollection.userInterfaceIdiom == .pad
        fullScreenButton.setIsHidden(!showFullScreenButton)
        fullScreenButtonWidthConstraint?.constant = showFullScreenButton ? 42 : 0
        fullScreenButton.isUserInteractionEnabled = showFullScreenButton
        detailViewButtonLeadingConstraint?.constant = showFullScreenButton ? 8 : 2
    }

    private func hideImageUserNameSplitedLable(isHidden: Bool) {
        threadTitleSupplementary.setIsHidden(isHidden)
    }

    @objc private func revokeButtonTapped() {
        Task { @ChatGlobalActor in
            await ChatManager.activeInstance?.setToken(newToken: "revoked_token", reCreateObject: false)
        }
    }
    
    private func onSearchTapped() {
        if viewModel?.id != nil, viewModel?.historyVM.sections.isEmpty == false, let viewModel = viewModel {
            let rootView = ThreadSearchMessages(threadVM: viewModel)
                .injectAllObjects()
                .environmentObject(viewModel.searchedMessagesViewModel)
            
            let vc = UIHostingController(rootView: rootView)
            vc.modalPresentationStyle = .fullScreen
            (viewModel.delegate as? UIViewController)?.present(vc, animated: true)
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if touches.first?.view == detailViewButton {
            detailViewButton.alpha = 0.5
            detailViewButton.transform = CGAffineTransform.identity.scaledBy(x: 0.98, y: 0.98)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if touches.first?.view == detailViewButton {
            detailViewButton.alpha = 1.0
            detailViewButton.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if touches.first?.view == detailViewButton {
            detailViewButton.alpha = 1.0
            detailViewButton.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if touches.first?.view == detailViewButton {
            detailViewButton.alpha = 1.0
            detailViewButton.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }
    }
    
    private var cachedImageLoaderVM: ImageLoaderViewModel? {
        let threads = AppState.shared.objectsContainer.navVM.allThreads
        return threads.first(where: { $0.id == self.viewModel?.thread.id })?.imageLoader as? ImageLoaderViewModel
    }
    
    /// When click on an avatar in the thread history for a contact that we have never had any conversation.
    private func createImageLoaderAndListen(link: String) {
        let config = ImageLoaderConfig(url: link,
                                       size: .MEDIUM,
                                       metaData: viewModel?.thread.metadata,
                                       userName: String.splitedCharacter(viewModel?.thread.title ?? ""),
                                       forceToDownloadFromServer: true)
        imageLoader = ImageLoaderViewModel(config: config)
        imageLoader?.onImage = { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.updateImageTo(image)
            }
        }
        imageLoader?.fetch()
    }
}
