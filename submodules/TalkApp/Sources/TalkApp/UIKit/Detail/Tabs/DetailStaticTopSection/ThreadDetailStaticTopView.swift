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
    private let cellPhoneNumberView = DetailTopSectionRowView(key: "Participant.Search.Type.cellphoneNumber", value: "")
    private let descriptionView: DetailTopSectionRowView
    private let userNameView = DetailTopSectionRowView(key: "Settings.userName", value: "")
    
    /// Models
    weak var viewModel: ThreadDetailViewModel?
    private var cancellableSet: Set<AnyCancellable> = Set()
    private var participantVM: ParticipantDetailViewModel? { viewModel?.participantDetailViewModel }
    
    init(viewModel: ThreadDetailViewModel?) {
        self.viewModel = viewModel
        self.topSection = DetailInfoTopSectionView(viewModel: viewModel)
        
        let tuple: (key: String, value: String)? = viewModel?.descriptionString()
        self.descriptionView = DetailTopSectionRowView(key: tuple?.key ?? "", value: tuple?.value ?? "")
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
        alignment = .top
        distribution = .fill
        
        /// Top thread image view and description and participants count
        addArrangedSubview(topSection)
    
        appendOrUpdateCellPhoneNumber()
        appendOrUpdateUserName()
        
        addArrangedSubview(descriptionView)
    }
    
    public func register() {
        let value = viewModel?.participantDetailViewModel?.cellPhoneNumber.validateString
        viewModel?.participantDetailViewModel?.objectWillChange.sink { [weak self] _ in
            self?.updateUI()
        }
        .store(in: &cancellableSet)
        
        viewModel?.objectWillChange.sink { [weak self] _ in
            self?.updateUI()
        }
        .store(in: &cancellableSet)
    }
    
    private func updateUI() {
        appendOrUpdateCellPhoneNumber()
        appendOrUpdateUserName()
    }
    
    /// Append or update
    public func appendOrUpdateCellPhoneNumber() {
        if cellPhoneNumberView.superview == nil {
            addArrangedSubview(cellPhoneNumberView)
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
            addArrangedSubview(userNameView)
        }
        
        let value = viewModel?.participantDetailViewModel?.userName
        userNameView.setValue(value ?? "")
        userNameView.onTap = { [weak self] in
            let newValue = self?.viewModel?.participantDetailViewModel?.userName
            self?.onUserNameTapped(userName: newValue ?? "")
        }
        userNameView.isHidden = value == nil
    }
}

/// Actions
extension ThreadDetailStaticTopView {
    private func onPhoneNumberTapped(phoneNumber: String) {
        UIPasteboard.general.string = phoneNumber
        let imageView = UIImageView(image: UIImage(systemName: "phone"))
        AppState.shared.objectsContainer.appOverlayVM.toast(
            leadingView: imageView,
            message: "General.copied",
            messageColor: Color.App.textPrimaryUIColor!
        )
    }
    
    private func onUserNameTapped(userName: String) {
        UIPasteboard.general.string = userName
        let imageView = UIImageView(image: UIImage(systemName: "person"))
        let key = "Settings.userNameCopied".bundleLocalized()
        AppState.shared.objectsContainer.appOverlayVM.toast(
            leadingView: imageView,
            message: key,
            messageColor: Color.App.textPrimaryUIColor!
        )
    }
}
