//
//  ThreadsTopToolbarView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 10/14/25.
//

import Foundation
import TalkViewModels
import UIKit
import TalkUI
import SwiftUI
import Combine
import Chat

@MainActor
public class ThreadsTopToolbarView: UIView {
    /// Views
    private let plusButton = UIImageButton(imagePadding: .init(all: 12))
    private let logoImageView =  UIImageButton(imagePadding: .init(all: 16))
    private let connectionStatusLabel = UILabel()
    private let uploadsButton = UIImageButton(imagePadding: .init(all: 12))
    private let downloadsButton = UIImageButton(imagePadding: .init(all: 12))
    private let searchButton = UIImageButton(imagePadding: .init(all: 12))
    private let searchTextField = UITextField()
    private let filterUnreadMessagesButton = UIImageButton(imagePadding: .init(all: 12))
    private let player = ThreadNavigationPlayer(viewModel: nil)
    private var searchListVC: UIViewController? = nil
    
    /// Models
    private var cancellableSet = Set<AnyCancellable>()
    private var isInSearchMode: Bool = false
    private var isFilterNewMessages: Bool = false

    /// Constraints
    private var playerHeightConstraint: NSLayoutConstraint?
    private var serachTextFieldHeightConstraint: NSLayoutConstraint?
    private var filterUnreadHeightConstraint: NSLayoutConstraint?
    private var downloadsButtonWidthConstraint: NSLayoutConstraint?
    private var uploadsButtonWidthConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        configureViews()
        registerObservers()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityIdentifier = "effectViewThreadsTopToolbarView"
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.layer.cornerRadius = 22
        plusButton.layer.masksToBounds = true
        plusButton.imageView.layer.cornerRadius = 22
        plusButton.imageView.layer.masksToBounds = true
        plusButton.imageView.contentMode  = .scaleAspectFill
        plusButton.imageView.image = UIImage(systemName: "plus")
        plusButton.accessibilityIdentifier = "plusButtonThreadsTopToolbarView"
        plusButton.isUserInteractionEnabled = true
        plusButton.action = { [weak self] in
            self?.onPlusTapped()
        }
        addSubview(plusButton)
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.imageView.image = UIImage(named: Language.isRTL ? "talk_logo_text" : "talk_logo_text_en")
        logoImageView.imageView.contentMode  = .scaleAspectFill
        logoImageView.accessibilityIdentifier = "logoImageViewThreadsTopToolbarView"
        logoImageView.isUserInteractionEnabled = false
        addSubview(logoImageView)
        
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusLabel.text = ""
        connectionStatusLabel.font = UIFont.fFootnote
        connectionStatusLabel.textColor = Color.App.toolbarSecondaryTextUIColor
        connectionStatusLabel.textAlignment = Language.isRTL ? .right : .left
        connectionStatusLabel.accessibilityIdentifier = "connectionStatusLabelThreadsTopToolbarView"
        addSubview(connectionStatusLabel)
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.imageView.image = UIImage(systemName: "magnifyingglass")
        searchButton.imageView.tintColor = Color.App.accentUIColor
        searchButton.imageView.contentMode = .scaleAspectFit
        searchButton.accessibilityIdentifier = "searchButtonThreadsTopToolbarView"
        searchButton.action = { [weak self] in
            self?.onSearchTapped()
        }
        addSubview(searchButton)
        
        downloadsButton.translatesAutoresizingMaskIntoConstraints = false
        downloadsButton.imageView.image = UIImage(systemName: downloadIconNameCompatible)
        downloadsButton.imageView.tintColor = Color.App.accentUIColor
        downloadsButton.imageView.contentMode = .scaleAspectFit
        downloadsButton.accessibilityIdentifier = "downloadsButtonThreadsTopToolbarView"
        downloadsButton.isHidden = true
        downloadsButton.isUserInteractionEnabled = false
        downloadsButton.action = { [weak self] in
            self?.onDownloadsTapped()
        }
        addSubview(downloadsButton)
        
        uploadsButton.translatesAutoresizingMaskIntoConstraints = false
        uploadsButton.imageView.image = UIImage(systemName: uploadIconNameCompatible)
        uploadsButton.imageView.tintColor = Color.App.accentUIColor
        uploadsButton.imageView.contentMode = .scaleAspectFit
        uploadsButton.accessibilityIdentifier = "uploadsButtonThreadsTopToolbarView"
        uploadsButton.isHidden = true
        uploadsButton.isUserInteractionEnabled = false
        uploadsButton.action = { [weak self] in
            self?.onUploadsTapped()
        }
        addSubview(uploadsButton)
   
        filterUnreadMessagesButton.translatesAutoresizingMaskIntoConstraints = false
        filterUnreadMessagesButton.imageView.image = UIImage(systemName: "envelope.badge")
        filterUnreadMessagesButton.imageView.tintColor = Color.App.toolbarSecondaryTextUIColor
        filterUnreadMessagesButton.imageView.contentMode = .scaleAspectFit
        filterUnreadMessagesButton.accessibilityIdentifier = "filterUnreadMessagesButtonThreadsTopToolbarView"
        filterUnreadMessagesButton.action = { [weak self] in
            self?.onFilterMessagesTapped()
        }
        addSubview(filterUnreadMessagesButton)
        
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.delegate = self
        searchTextField.placeholder = "General.searchHere".bundleLocalized()
        searchTextField.layer.backgroundColor = Color.App.bgSendInputUIColor?.withAlphaComponent(0.8).cgColor
        searchTextField.layer.cornerRadius = 12
        searchTextField.layer.masksToBounds = true
        searchTextField.font = UIFont.fBody
        searchTextField.textAlignment = Language.isRTL ? .right : .left
        searchTextField.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        searchTextField.leftViewMode = .always
        searchTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        searchTextField.rightViewMode = .always
        addSubview(searchTextField)
        
        player.translatesAutoresizingMaskIntoConstraints = false
        addSubview(player)

        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: player.bottomAnchor),
            
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4),
            
            plusButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            plusButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            plusButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            plusButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            logoImageView.leadingAnchor.constraint(equalTo: plusButton.trailingAnchor, constant: -16),
            logoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            logoImageView.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth - 4),
            logoImageView.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth - 4),
            
            connectionStatusLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 4),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: uploadsButton.leadingAnchor, constant: -4),
            connectionStatusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            connectionStatusLabel.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            searchButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            searchButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            searchButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            downloadsButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -4),
            downloadsButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            downloadsButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            uploadsButton.trailingAnchor.constraint(equalTo: downloadsButton.leadingAnchor, constant: -4),
            uploadsButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            uploadsButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            filterUnreadMessagesButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            filterUnreadMessagesButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor, constant: 0),
            filterUnreadMessagesButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: filterUnreadMessagesButton.leadingAnchor, constant: -8),
            searchTextField.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: 0),
            
            player.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            player.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            player.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 0),
        ])
        
        downloadsButtonWidthConstraint = downloadsButton.widthAnchor.constraint(equalToConstant: 0)
        downloadsButtonWidthConstraint?.isActive = true
        
        uploadsButtonWidthConstraint = uploadsButton.widthAnchor.constraint(equalToConstant: 0)
        uploadsButtonWidthConstraint?.isActive = true
        
        playerHeightConstraint = player.heightAnchor.constraint(equalToConstant: 0)
        playerHeightConstraint?.isActive = true
        player.isHidden = true
        
        serachTextFieldHeightConstraint = searchTextField.heightAnchor.constraint(equalToConstant: 0)
        serachTextFieldHeightConstraint?.isActive = true
        searchTextField.isHidden = true
        
        filterUnreadHeightConstraint = filterUnreadMessagesButton.heightAnchor.constraint(equalToConstant: 0)
        filterUnreadHeightConstraint?.isActive = true
        filterUnreadMessagesButton.isHidden = true
    }
    
    private func configureUISearchListView(show: Bool) {
        if show {
            let obj = AppState.shared.objectsContainer!
            let rootView = ThreadSearchView()
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .environmentObject(obj.searchVM)
                .environmentObject(obj.contactsVM)
                .environmentObject(obj.threadsVM)
            let searchListVC = UIHostingController(rootView: rootView)
            searchListVC.view.translatesAutoresizingMaskIntoConstraints = false
            searchListVC.view.backgroundColor = Color.App.bgPrimaryUIColor
            self.searchListVC = searchListVC
            addSubview(searchListVC.view)
            
            let height = (obj.threadsVM.delegate as? UIViewController)?.view.frame.height ?? 0
            
            NSLayoutConstraint.activate([
                searchListVC.view.topAnchor.constraint(equalTo: searchTextField.bottomAnchor),
                searchListVC.view.heightAnchor.constraint(equalToConstant: height),
                searchListVC.view.widthAnchor.constraint(equalTo: widthAnchor),
                searchListVC.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            ])
        } else {
            self.searchListVC?.view.removeFromSuperview()
            self.searchListVC = nil
        }
    }

    private func registerObservers() {
        AppState.shared.$connectionStatus.sink { [weak self] newState in
            self?.onConnectionStatusChanged(newState)
        }
        .store(in: &cancellableSet)
        
        AppState.shared.objectsContainer.downloadsManager.$elements.sink { [weak self] newValue in
            guard let self = self else { return }
            downloadsButtonWidthConstraint?.constant = newValue.isEmpty ? 0 : ToolbarButtonItem.buttonWidth
            downloadsButton.isHidden = newValue.isEmpty
            downloadsButton.isUserInteractionEnabled = !newValue.isEmpty
        }
        .store(in: &cancellableSet)
        
        AppState.shared.objectsContainer.uploadsManager.$elements.sink { [weak self] newValue in
            guard let self = self else { return }
            uploadsButtonWidthConstraint?.constant = newValue.isEmpty ? 0 : ToolbarButtonItem.buttonWidth
            uploadsButton.isHidden = newValue.isEmpty
            uploadsButton.isUserInteractionEnabled = !newValue.isEmpty
        }
        .store(in: &cancellableSet)
        
        NotificationCenter.default.publisher(for: Notification.Name("SWAP_PLAYER")).sink { [weak self] notif in
            self?.onPlayerItemChanged(notif.object as? AVAudioPlayerItem)
        }
        .store(in: &cancellableSet)
        
        NotificationCenter.default.publisher(for: Notification.Name("CLOSE_PLAYER")).sink { [weak self] notif in
            self?.onPlayerItemChanged(nil)
        }
        .store(in: &cancellableSet)
    }
    
    private func onConnectionStatusChanged(_ newState: ConnectionStatus) {
        if newState == .unauthorized {
            connectionStatusLabel.text = ConnectionStatus.connecting.stringValue.bundleLocalized()
        } else if newState != .connected {
            connectionStatusLabel.text = newState.stringValue.bundleLocalized()
        } else if newState == .connected {
            connectionStatusLabel.text = ""
        }
    }
    
    private func onSearchTapped() {
        isInSearchMode.toggle()
        searchButton.imageView.image = UIImage(systemName: isInSearchMode ? "xmark" : "magnifyingglass")
        serachTextFieldHeightConstraint?.constant = isInSearchMode ? ToolbarButtonItem.buttonWidth - 12 : 0
        searchTextField.isHidden = !isInSearchMode
        searchTextField.isUserInteractionEnabled = isInSearchMode
        isInSearchMode ? searchTextField.becomeFirstResponder() : searchTextField.resignFirstResponder()
        filterUnreadMessagesButton.isUserInteractionEnabled = isInSearchMode
        filterUnreadMessagesButton.isHidden = !isInSearchMode
        filterUnreadHeightConstraint?.constant = isInSearchMode ? ToolbarButtonItem.buttonWidth : 0
        configureUISearchListView(show: isInSearchMode)
    }
    
    private func onSearchTextChanged(newValue: String) {
        AppState.shared.objectsContainer.contactsVM.searchContactString = newValue
        AppState.shared.objectsContainer.searchVM.searchText = newValue
    }
    
    private func onFilterMessagesTapped() {
        isFilterNewMessages.toggle()
        filterUnreadMessagesButton.imageView.tintColor = isFilterNewMessages ? Color.App.accentUIColor: Color.App.toolbarSecondaryTextUIColor
        AppState.shared.objectsContainer.searchVM.showUnreadConversations = isFilterNewMessages
    }
    
    private func onDownloadsTapped() {
        AppState.shared.objectsContainer.navVM.wrapAndPush(view: DownloadsManagerListView())
    }
    
    private func onUploadsTapped() {
        AppState.shared.objectsContainer.navVM.wrapAndPush(view: UploadsManagerListView())
    }
    
    private func onPlusTapped() {
        guard let obj = AppState.shared.objectsContainer else { return }
        obj.conversationBuilderVM.clear()
        obj.searchVM.searchText = ""
        obj.contactsVM.searchContactString = ""
        NotificationCenter.cancelSearch.post(name: .cancelSearch, object: true)
        
        let rootView = StartThreadContactPickerView()
            .environmentObject(obj.conversationBuilderVM)
            .environmentObject(obj.contactsVM)
            .onDisappear {
                obj.conversationBuilderVM.clear()
            }
        let vc = UIHostingController(rootView: rootView)
        vc.modalPresentationStyle = .formSheet
        (obj.threadsVM.delegate as? UIViewController)?.present(vc, animated: true)
    }
    
    private func onPlayerItemChanged(_ item: AVAudioPlayerItem?) {
        playerHeightConstraint?.constant = item == nil ? 0 : ToolbarButtonItem.buttonWidth
        player.isHidden = item == nil
        player.isUserInteractionEnabled = item != nil
    }
}

extension ThreadsTopToolbarView: UITextFieldDelegate {
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        onSearchTextChanged(newValue: textField.text ?? "")
    }
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        onSearchTextChanged(newValue: newText)
        return true
    }
}

extension ThreadsTopToolbarView {
    private var downloadIconNameCompatible: String {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.down.circle.dotted"
        }
        return "arrow.down.circle"
    }
    
    private var uploadIconNameCompatible: String {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.up.circle.dotted"
        }
        return "arrow.up.circle"
    }
}
