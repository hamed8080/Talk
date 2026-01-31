//
//  ThreadDetailStaticTopView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/27/25.
//

import UIKit
import TalkViewModels
import Combine
import SwiftUI

public class ThreadDetailStaticTopView: UIStackView {
    /// Views
    private let topSection: DetailInfoTopSectionView
    private let cellPhoneNumberView = DetailTopSectionRowView(key: "Settings.phoneNumber", value: "")
    private let userNameView = DetailTopSectionRowView(key: "Settings.userName", value: "")
    private let publicLinkView = DetailTopSectionRowView(key: "Thread.inviteLink", value: "")
    private let descriptionView = DetailTopSectionRowView(key: "", value: "")
    private let buttonsRowView: DetailTopSectionButtonsRowView
    private let firstSeparator = DetailViewDivider()
    private let secondSeparator = DetailViewDivider()
    
    /// Models
    weak var viewModel: ThreadDetailViewModel?
    private var cancellableSet: Set<AnyCancellable> = Set()
    private var participantVM: ParticipantDetailViewModel? { viewModel?.participantDetailViewModel }
    
    init(viewModel: ThreadDetailViewModel?) {
        self.viewModel = viewModel
        self.topSection = DetailInfoTopSectionView(viewModel: viewModel)
        self.buttonsRowView = DetailTopSectionButtonsRowView(viewModel: viewModel)
        super.init(frame: .zero)
        configureViews()
        register()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder≈:) has not been implemented")
    }
    
    private func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        axis = .vertical
        spacing = 16
        alignment = .center
        distribution = .fill
        
        /// Top thread image view and description and participants count
        addArrangedSubview(topSection)
        
        appenORUpdateUI()
        
        buttonsRowView.viewModel = viewModel
        addArrangedSubview(buttonsRowView)
        addArrangedSubview(secondSeparator)
        
        NSLayoutConstraint.activate([
            topSection.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            firstSeparator.heightAnchor.constraint(equalToConstant: 10),
            firstSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            firstSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            secondSeparator.heightAnchor.constraint(equalToConstant: 10),
            secondSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            secondSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    public func register() {
        let value = viewModel?.participantDetailViewModel?.cellPhoneNumber.validateString
        viewModel?.participantDetailViewModel?.objectWillChange.sink { [weak self] _ in
            self?.appenORUpdateUI()
        }
        .store(in: &cancellableSet)
        
        viewModel?.objectWillChange.sink { [weak self] _ in
            self?.appenORUpdateUI()
        }
        .store(in: &cancellableSet)
    }
    
    private func appenORUpdateUI() {
        appendOrUpdateCellPhoneNumber()
        appendOrUpdateUserName()
        appendOrUpdatePublicLink()
        appendOrUpdateDescription()
        appendOrUpdateSeparator()
    }
    
    /// Append or update
    public func appendOrUpdateCellPhoneNumber() {
        if cellPhoneNumberView.superview == nil {
            let separator = TableViewControllerDevider()
            addArrangedSubview(cellPhoneNumberView)
            addSubview(separator)
            separator.isHidden = viewModel?.thread?.group == true
            NSLayoutConstraint.activate([
                cellPhoneNumberView.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.bottomAnchor.constraint(equalTo: cellPhoneNumberView.bottomAnchor, constant: 8),
                separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }
        
        let value = participantVM?.cellPhoneNumber
        cellPhoneNumberView.setValue(value ?? "")
        cellPhoneNumberView.onTap = { [weak self] in
            let newValue = self?.participantVM?.cellPhoneNumber
            self?.onPhoneNumberTapped(phoneNumber: newValue ?? "")
        }
        cellPhoneNumberView.isHidden = value == nil
    }
    
    /// Append or update
    public func appendOrUpdateUserName() {
        if userNameView.superview == nil {
            let separator = TableViewControllerDevider()
            addArrangedSubview(userNameView)
            addSubview(separator)
            separator.isHidden = viewModel?.thread?.group == true
            NSLayoutConstraint.activate([
                userNameView.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.bottomAnchor.constraint(equalTo: userNameView.bottomAnchor, constant: 8),
                separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }
        
        let value = viewModel?.participantDetailViewModel?.userName
        userNameView.setValue(value ?? "")
        userNameView.onTap = { [weak self] in
            let newValue = self?.viewModel?.participantDetailViewModel?.userName
            self?.onUserNameTapped(userName: newValue ?? "")
        }
        userNameView.isHidden = value == nil
    }
    
    /// Append or update
    public func appendOrUpdatePublicLink() {
        if publicLinkView.superview == nil {
            addArrangedSubview(publicLinkView)
            NSLayoutConstraint.activate([
                publicLinkView.leadingAnchor.constraint(equalTo: leadingAnchor)
            ])
        }
        
        let value = viewModel?.joinLink
        publicLinkView.setValue(value ?? "")
        publicLinkView.onTap = { [weak self] in
            self?.onPublicLinkTapped(joinLink: self?.viewModel?.joinLink ?? "")
        }
        let isPrivate = viewModel?.thread?.type?.isPrivate == true
        publicLinkView.isHidden = isPrivate || value == nil
    }
    
    /// Append or update
    public func appendOrUpdateDescription() {
        if descriptionView.superview == nil {
            addArrangedSubview(descriptionView)
            NSLayoutConstraint.activate([
                descriptionView.leadingAnchor.constraint(equalTo: leadingAnchor)
            ])
        }
        
        let tuple: (key: String, value: String)? = viewModel?.descriptionString()
        descriptionView.setValue(tuple?.value ?? "")
        descriptionView.setKey(tuple?.key.bundleLocalized() ?? "")
    }
    
    /// Append or update
    public func appendOrUpdateButtonsRow() {
        if buttonsRowView.superview == nil {
            addArrangedSubview(buttonsRowView)
            NSLayoutConstraint.activate([
                buttonsRowView.leadingAnchor.constraint(equalTo: leadingAnchor)
            ])
        }
    }
    
    /// Append or update
    public func appendOrUpdateSeparator() {
        if firstSeparator.superview == nil {
            addArrangedSubview(firstSeparator)
        }
    }
}

/// Actions
extension ThreadDetailStaticTopView {
    private func onPhoneNumberTapped(phoneNumber: String) {
        copyAndToast(phoneNumber, "General.copied", "phone")
    }
    
    private func onUserNameTapped(userName: String) {
        copyAndToast(userName, "Settings.userNameCopied", "person")
    }
    
    private func onPublicLinkTapped(joinLink: String) {
        copyAndToast(joinLink, "General.copied", "doc.on.doc")
    }
    
    private func copyAndToast(_ value: String, _ messageTitle: String, _ iconName: String) {
        UIPasteboard.general.string = value
        let imageView = UIImageView(image: UIImage(systemName: iconName))
        AppState.shared.objectsContainer.appOverlayVM.toast(
            leadingView: imageView,
            message: messageTitle,
            messageColor: Color.App.textPrimaryUIColor!
        )
    }
}
