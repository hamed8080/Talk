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
public class ThreadsTopToolbarView: UIStackView {
    /// Views
    private let plusButton = UIImageButton(imagePadding: .init(all: 12))
    private let logoImageView =  UIImageButton(imagePadding: .init(top: 12, left: 12, bottom: 12, right: -14))
    private let connectionStatusLabel = UILabel()
    private let uploadsButton = UIImageButton(imagePadding: .init(all: 12))
    private let downloadsButton = UIImageButton(imagePadding: .init(all: 12))
    private let searchButton = UIImageButton(imagePadding: .init(all: 12))
    private let searchTextField = UITextField()
    private let filterUnreadMessagesButton = UIImageButton(imagePadding: .init(all: 12))
    private let player = ThreadNavigationPlayer(viewModel: nil)
    private let topRowStack = UIStackView()
    private let searchRowStack = UIStackView()
    
    /// Models
    private var cancellableSet = Set<AnyCancellable>()
    private var isInSearchMode: Bool = false
    private var isFilterNewMessages: Bool = false
    var onSearchChanged: (@Sendable (Bool) -> Void)?

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
        axis = .vertical
        spacing = 0
        
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
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.imageView.image = UIImage(named: Language.isRTL ? "talk_logo_text" : "talk_logo_text_en")
        logoImageView.imageView.contentMode  = .scaleAspectFit
        logoImageView.accessibilityIdentifier = "logoImageViewThreadsTopToolbarView"
        logoImageView.isUserInteractionEnabled = false
        
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusLabel.text = ""
        connectionStatusLabel.font = UIFont.fFootnote
        connectionStatusLabel.textColor = Color.App.toolbarSecondaryTextUIColor
        connectionStatusLabel.textAlignment = Language.isRTL ? .right : .left
        connectionStatusLabel.accessibilityIdentifier = "connectionStatusLabelThreadsTopToolbarView"
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.imageView.image = UIImage(systemName: "magnifyingglass")
        searchButton.imageView.tintColor = Color.App.accentUIColor
        searchButton.imageView.contentMode = .scaleAspectFit
        searchButton.accessibilityIdentifier = "searchButtonThreadsTopToolbarView"
        searchButton.action = { [weak self] in
            self?.onSearchTapped()
        }
        
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
        
        topRowStack.axis = .horizontal
        topRowStack.alignment = .center
        topRowStack.distribution = .fill
        topRowStack.spacing = 4
        topRowStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        topRowStack.addArrangedSubview(plusButton)
        topRowStack.addArrangedSubview(logoImageView)
        topRowStack.addArrangedSubview(connectionStatusLabel)
        topRowStack.addArrangedSubview(uploadsButton)
        topRowStack.addArrangedSubview(downloadsButton)
        topRowStack.addArrangedSubview(searchButton)
   
        filterUnreadMessagesButton.translatesAutoresizingMaskIntoConstraints = false
        filterUnreadMessagesButton.imageView.image = UIImage(systemName: "envelope.badge")
        filterUnreadMessagesButton.imageView.tintColor = Color.App.toolbarSecondaryTextUIColor
        filterUnreadMessagesButton.imageView.contentMode = .scaleAspectFit
        filterUnreadMessagesButton.accessibilityIdentifier = "filterUnreadMessagesButtonThreadsTopToolbarView"
        filterUnreadMessagesButton.action = { [weak self] in
            self?.onFilterMessagesTapped()
        }
        
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.delegate = self
        searchTextField.placeholder = "General.searchHere".bundleLocalized()
        searchTextField.layer.backgroundColor = Color.App.bgSendInputUIColor?.withAlphaComponent(0.8).cgColor
        searchTextField.layer.cornerRadius = 16
        searchTextField.layer.masksToBounds = true
        searchTextField.font = UIFont.fBody
        searchTextField.textAlignment = Language.isRTL ? .right : .left
        searchTextField.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        searchTextField.leftViewMode = .always
        searchTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        searchTextField.rightViewMode = .always
        
        searchRowStack.translatesAutoresizingMaskIntoConstraints = false
        searchRowStack.axis = .horizontal
        searchRowStack.distribution = .fill
        searchRowStack.alignment = .center
        searchRowStack.layoutMargins = .init(top: 8, left: 0, bottom: 8, right: 8)
        searchRowStack.isLayoutMarginsRelativeArrangement = true
        searchRowStack.addArrangedSubview(filterUnreadMessagesButton)
        searchRowStack.addArrangedSubview(searchTextField)
        
        player.translatesAutoresizingMaskIntoConstraints = false
       
        addArrangedSubview(topRowStack)
        addArrangedSubview(searchRowStack)
        addArrangedSubview(player)

        NSLayoutConstraint.activate([
            
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            
            plusButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            plusButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            logoImageView.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth - 10),
            logoImageView.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth - 10),
            
            connectionStatusLabel.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            searchButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            searchButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            downloadsButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            downloadsButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            uploadsButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            uploadsButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            searchTextField.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            
            filterUnreadMessagesButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            filterUnreadMessagesButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
        ])
        
        player.isHidden = true
        searchRowStack.isHidden = true
    }

    private func registerObservers() {
        AppState.shared.$connectionStatus.sink { [weak self] newState in
            self?.onConnectionStatusChanged(newState)
        }
        .store(in: &cancellableSet)
        
        AppState.shared.objectsContainer.downloadsManager.$elements.sink { [weak self] newValue in
            guard let self = self else { return }
            downloadsButton.isHidden = newValue.isEmpty
            downloadsButton.isUserInteractionEnabled = !newValue.isEmpty
        }
        .store(in: &cancellableSet)
        
        AppState.shared.objectsContainer.uploadsManager.$elements.sink { [weak self] newValue in
            guard let self = self else { return }
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
        searchRowStack.isHidden = !isInSearchMode
        searchTextField.isHidden = !isInSearchMode
        searchTextField.isUserInteractionEnabled = isInSearchMode
        isInSearchMode ? searchTextField.becomeFirstResponder() : searchTextField.resignFirstResponder()
        filterUnreadMessagesButton.isUserInteractionEnabled = isInSearchMode
        filterUnreadMessagesButton.isHidden = !isInSearchMode
        onSearchChanged?(isInSearchMode)
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
        let shouldShow = item != nil
        player.isHidden = !shouldShow
        player.isUserInteractionEnabled = shouldShow
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
