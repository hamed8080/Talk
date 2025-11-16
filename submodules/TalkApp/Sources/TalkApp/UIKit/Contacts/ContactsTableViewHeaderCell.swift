//
//  ContactsTableViewHeaderCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import TalkUI
import Lottie

class ContactsTableViewHeaderCell: UITableViewCell {
    weak var viewController: UIViewController?
    private let stack = UIStackView()
    private var cancellable: AnyCancellable?
    private let loadingView = LottieAnimationView(talkName: "talk_logo_animation.json")
    private let loadingContainer = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
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
            heightAnchor.constraint(equalToConstant: 140),
            
            loadingContainer.widthAnchor.constraint(equalTo: widthAnchor),
            loadingContainer.heightAnchor.constraint(equalToConstant: 52),
            
            loadingView.widthAnchor.constraint(equalToConstant: 52),
            loadingView.heightAnchor.constraint(equalToConstant: 52),
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
        label.font = UIFont.bold(.body)
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
        if #available(iOS 16.4, *) {
            let nilDarkMode = AppSettingsModel.restore().isDarkModeEnabled == nil
            let isDarkModeStorage = AppSettingsModel.restore().isDarkModeEnabled == true
            let systemDarModeIsEnabled = traitCollection.userInterfaceStyle == .dark
            let isDarkMode = nilDarkMode ? systemDarModeIsEnabled : isDarkModeStorage
            
            let rootView = AddOrEditContactView()
                .injectAllObjects()
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
        loadingView.stop()
        loadingView.isHidden = true
        loadingContainer.removeFromSuperview()
    }
    
    public func startLoading() {
        loadingView.isHidden = false
        loadingView.play()
    }
}
