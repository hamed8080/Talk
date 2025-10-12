//
//  ContactCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import TalkUI

class ContactsTableViewHeader: UIView {
    weak var viewController: UIViewController?
    private let stack = UIStackView()
    private var cancellable: AnyCancellable?
    private let loadingView = UILoadingView()
    private let loadingContainer = UIView()
    
    init() {
        super.init(frame: .zero)
        configureView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        loadingContainer.translatesAutoresizingMaskIntoConstraints = false
        loadingContainer.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        let btnCreateGroup = make("person.2", "Contacts.createGroup", #selector(onCreateGroup))
        let btnCreateChannel = make("megaphone", "Contacts.createChannel", #selector(onCreateChannel))
        let btnCreateContact = make("person.badge.plus", "Contacts.addContact", #selector(onCreateContact))

        stack.addArrangedSubviews([btnCreateGroup, btnCreateChannel, btnCreateContact, loadingContainer])
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            loadingContainer.widthAnchor.constraint(equalTo: widthAnchor),
            loadingContainer.heightAnchor.constraint(equalToConstant: 36),
            
            loadingView.widthAnchor.constraint(equalToConstant: 36),
            loadingView.heightAnchor.constraint(equalToConstant: 36),
            loadingView.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }
    
    private func make(_ image: String, _ title: String, _ selector: Selector?) -> UIView {
        let imageView = UIImageView(image: UIImage(systemName: image))
        imageView.tintColor = Color.App.accentUIColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        
        let label = UILabel()
        label.text = title.bundleLocalized()
        label.textColor = Color.App.accentUIColor
        label.font = UIFont.fBoldBody
        label.translatesAutoresizingMaskIntoConstraints = false
    
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let gesture = UITapGestureRecognizer(target: self, action: selector)
        stack.addGestureRecognizer(gesture)
        
        NSLayoutConstraint.activate([
            stack.heightAnchor.constraint(equalToConstant: 24),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            label.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return stack
    }
    
    @objc private func onCreateGroup() {
        showBuilder(type:.privateGroup)
    }
    
    @objc private func onCreateChannel() {
        showBuilder(type: .privateChannel)
    }
    
    @objc private func onCreateContact() {
        let viewModel = AppState.shared.objectsContainer.contactsVM
        if #available(iOS 16.4, *) {
            let nilDarkMode = AppSettingsModel.restore().isDarkModeEnabled == nil
            let isDarkModeStorage = AppSettingsModel.restore().isDarkModeEnabled == true
            let systemDarModeIsEnabled = traitCollection.userInterfaceStyle == .dark
            let isDarkMode = nilDarkMode ? systemDarModeIsEnabled : isDarkModeStorage
            
            let rootView = AddOrEditContactView()
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .environmentObject(viewModel)
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
                .preferredColorScheme(isDarkMode ? .dark : .light)
            var sheetVC = UIHostingController(rootView: rootView)
            sheetVC.modalPresentationStyle = .formSheet
            sheetVC.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            self.viewController?.present(sheetVC, animated: true)
        }
    }
    
    private func showBuilder(type: StrictThreadTypeCreation = .p2p) {
        let builderVM = AppState.shared.objectsContainer.conversationBuilderVM
        
        builderVM.dismiss = false
        
        let nilDarkMode = AppSettingsModel.restore().isDarkModeEnabled == nil
        let isDarkModeStorage = AppSettingsModel.restore().isDarkModeEnabled == true
        let systemDarModeIsEnabled = traitCollection.userInterfaceStyle == .dark
        let isDarkMode = nilDarkMode ? systemDarModeIsEnabled : isDarkModeStorage
        
        let viewModel = AppState.shared.objectsContainer.contactsVM
        let rootView = ConversationBuilder()
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
            .environmentObject(viewModel)
            .environmentObject(builderVM)
            .environment(\.colorScheme, isDarkMode ? .dark : .light)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                builderVM.show(type: type)
            }
            .onDisappear {
                builderVM.clear()
            }
        
        var sheetVC = UIHostingController(rootView: rootView)
        sheetVC.modalPresentationStyle = .formSheet
        sheetVC.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        self.viewController?.present(sheetVC, animated: true)
        
        cancellable = builderVM.$dismiss.sink { dismiss in
            if dismiss {
                sheetVC.dismiss(animated: true)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = touches.first?.view, view != stack, view != self {
            view.layer.opacity = 0.6
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = touches.first?.view {
            view.layer.opacity = 1.0
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = touches.first?.view {
            view.layer.opacity = 1.0
        }
    }
    
    public func removeLoading() {
        loadingView.animate(false)
        loadingContainer.removeFromSuperview()
    }
    
    public func startLoading() {
        loadingView.animate(true)
    }
}
