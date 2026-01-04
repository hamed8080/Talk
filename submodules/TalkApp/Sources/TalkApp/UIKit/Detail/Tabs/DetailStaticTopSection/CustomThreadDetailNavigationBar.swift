//
//  CustomThreadDetailNavigationBar.swift
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

public class CustomThreadDetailNavigationBar: UIView {
    /// Views
    private let backButton = UIImageButton(imagePadding: .init(all: 14))
    private let titleLabel = UILabel()
    private let editGroupOrContactButton = UIImageButton(imagePadding: .init(all: 10))
    
    /// Models
    private weak var viewModel: ThreadDetailViewModel?
    private var cancellableSet: Set<AnyCancellable> = Set()

    init(viewModel: ThreadDetailViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        register()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = toolbarTitle()
        titleLabel.font = UIFont.bold(.body)
        titleLabel.textColor = Color.App.whiteUIColor
        titleLabel.textAlignment = .center
        titleLabel.accessibilityIdentifier = "CustomThreadDetailNavigationBar.titleLabel"
        addSubview(titleLabel)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.imageView.image = UIImage(systemName: "chevron.backward")
        backButton.imageView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        backButton.imageView.tintColor = Color.App.toolbarButtonUIColor
        backButton.imageView.contentMode = .scaleAspectFit
        backButton.accessibilityIdentifier = "CustomThreadDetailNavigationBar.backButton"
        backButton.action = { [weak self] in
            self?.viewModel?.dismissByBackButton()
        }
        addSubview(backButton)
        
        editGroupOrContactButton.translatesAutoresizingMaskIntoConstraints = false
        editGroupOrContactButton.imageView.image = UIImage(named: "ic_edit_empty")
        editGroupOrContactButton.imageView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        editGroupOrContactButton.imageView.tintColor = Color.App.toolbarButtonUIColor
        editGroupOrContactButton.imageView.contentMode = .scaleAspectFit
        editGroupOrContactButton.accessibilityIdentifier = "CustomThreadDetailNavigationBar.editGroupOrContactButton"
        editGroupOrContactButton.action = { [weak self] in
            self?.onEditGroupOrContactTapped()
        }
        addSubview(editGroupOrContactButton)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 64),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            backButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: editGroupOrContactButton.leadingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 16),
            
            editGroupOrContactButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            editGroupOrContactButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            editGroupOrContactButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
        ])
        
        setEditContactOrCovnersationVisibility()
    }
    
    private func toolbarTitle() -> String {
        let type = viewModel?.thread?.type
        let isChannel = type?.isChannelType == true
        let isGroup = type == .channelGroup || type == .ownerGroup || type == .publicGroup || viewModel?.thread?.group == true && !isChannel
        let typeKey = isGroup ? "Thread.group" : isChannel ? "Thread.channel" : "General.contact"
        return "\("General.info".bundleLocalized()) \(typeKey.bundleLocalized())"
    }
    
    private func register() {
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
        setEditContactOrCovnersationVisibility()
    }
    
    private func setEditContactOrCovnersationVisibility() {
        let showConversationButton = viewModel?.canShowEditConversationButton() == true
        let showEditContactButton = viewModel?.participantDetailViewModel != nil
        editGroupOrContactButton.isHidden = !(showEditContactButton || showConversationButton)
    }
}

/// Actions
extension CustomThreadDetailNavigationBar {
    private func onEditGroupOrContactTapped() {
        guard let viewModel = viewModel else { return }
        if viewModel.canShowEditConversationButton() {
            onEditConversationTapped()
        } else if let viewModel = viewModel.participantDetailViewModel {
            onEditContactTapped()
        }
    }
    
    private func onEditConversationTapped() {
        guard
            let viewModel = viewModel,
            let editConversationVM = viewModel.editConversationViewModel
        else { return }
        AppState.shared.objectsContainer.navVM.pushToLinkId(id: "DetailEditConversation-\(viewModel.thread?.id ?? 0)" )
        let view = EditGroup(threadVM: viewModel.threadVM)
            .environmentObject(editConversationVM)
            .navigationBarBackButtonHidden(true)
            .onDisappear {
                AppState.shared.objectsContainer.navVM.popLinkId(id: "DetailEditConversation-\(viewModel.thread?.id ?? 0)")
            }
        AppState.shared.objectsContainer.navVM.wrapAndPush(view: view)
    }
    
    private func onEditContactTapped() {
        guard
            let viewModel = viewModel,
            let participantVM = viewModel.participantDetailViewModel
        else { return }
        AppState.shared.objectsContainer.navVM.pushToLinkId(id: "EditContact-\(participantVM.partnerContact?.id ?? 0)")
        let view = EditContactInParticipantDetailView()
            .environmentObject(viewModel)
            .environmentObject(participantVM)
            .background(Color.App.bgSecondary)
            .navigationBarBackButtonHidden(true)
            .onDisappear {
                AppState.shared.objectsContainer.navVM.popLinkId(id: "EditContact-\(participantVM.partnerContact?.id ?? 0)")
            }
        AppState.shared.objectsContainer.navVM.wrapAndPush(view: view)
    }
}
