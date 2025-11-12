//
//  ContactsNavigationBar.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import UIKit
import TalkModels
import SwiftUI
import TalkUI

class ContactsNavigationBar: UIView {
    private let overBlurEffectColorView = UIView()
    private let titleLabel = UILabel()
    private let searchButton = UIImageButton(imagePadding: .init(all: 12))
    private let searchField = UITextField()
    private let menuButton = UIButton(type: .system)
    private let dropDownImageView = UIImageView()
    
    private var searchActive = false
    weak var viewModel: ContactsViewModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {

        let isDark = traitCollection.userInterfaceStyle == .dark
        
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityIdentifier = "effectContactsNavigationBar"
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)
        
        overBlurEffectColorView.translatesAutoresizingMaskIntoConstraints = false
        overBlurEffectColorView.accessibilityIdentifier = "overBlurEffectColorViewContactsNavigationBar"
        overBlurEffectColorView.backgroundColor = isDark ? UIColor.clear : Color.App.accentUIColor
        addSubview(overBlurEffectColorView)
        
        titleLabel.text = "Contacts"
        titleLabel.font = UIFont.fBoldSubheadline
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = Color.App.toolbarButtonUIColor
        addSubview(titleLabel)
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.imageView.image = UIImage(systemName: "magnifyingglass")
        searchButton.imageView.tintColor = Color.App.toolbarButtonUIColor
        searchButton.imageView.contentMode = .scaleAspectFit
        searchButton.accessibilityIdentifier = "searchButtonThreadsTopToolbarView"
        searchButton.action = { [weak self] in
            self?.toggleSearch()
        }
        
        addSubview(searchButton)
        
        // Configure search field
        searchField.alpha = 0
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.delegate = self
        searchField.placeholder = "General.searchHere".bundleLocalized()
        searchField.layer.backgroundColor = Color.App.bgSendInputUIColor?.withAlphaComponent(0.8).cgColor
        searchField.layer.cornerRadius = 16
        searchField.layer.masksToBounds = true
        searchField.font = UIFont.fBody
        searchField.textAlignment = Language.isRTL ? .right : .left
        searchField.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        searchField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        searchField.leftViewMode = .always
        searchField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        searchField.rightViewMode = .always
        addSubview(searchField)
        
        // Configure menu button
        menuButton.alpha = 0
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.titleLabel?.font = UIFont.fBoldCaption3
        menuButton.titleLabel?.textAlignment = Language.isRTL ? .right : .left
        menuButton.setTitleColor(isDark ? Color.App.accentUIColor : Color.App.whiteUIColor, for: .normal)
        menuButton.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
                
        let actions = SearchParticipantType.allCases.filter({ $0 != .admin }).compactMap({ type in
            UIAction(title: type.rawValue.bundleLocalized(), image: nil) { [weak self] _ in
                self?.viewModel?.searchType = type
                self?.menuButton.setTitle(type.rawValue.bundleLocalized() ?? "", for: .normal)
            }
        })
        menuButton.menu = UIMenu(title: "", children: actions)
        addSubview(menuButton)
        
        let config = UIImage.SymbolConfiguration(pointSize: 12)
        let dropDownImage = UIImage(systemName: "chevron.down")?.applyingSymbolConfiguration(config)
        dropDownImageView.image = dropDownImage
        dropDownImageView.contentMode = .scaleAspectFit
        dropDownImageView.tintColor = Color.App.accentUIColor
        dropDownImageView.translatesAutoresizingMaskIntoConstraints = false
        dropDownImageView.alpha = 0.0
        addSubview(dropDownImageView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            
            overBlurEffectColorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overBlurEffectColorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overBlurEffectColorView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            overBlurEffectColorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
    
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            
            searchButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            searchButton.widthAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),
            searchButton.heightAnchor.constraint(equalToConstant: ToolbarButtonItem.buttonWidth),

            searchField.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -8),
            searchField.heightAnchor.constraint(equalToConstant: 36),

            menuButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            menuButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -8),
            menuButton.widthAnchor.constraint(equalToConstant: 92),
            
            dropDownImageView.centerYAnchor.constraint(equalTo: menuButton.centerYAnchor, constant: 0),
            dropDownImageView.widthAnchor.constraint(equalToConstant: 16),
            dropDownImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        if let buttonLabel = menuButton.titleLabel {
            dropDownImageView.leadingAnchor.constraint(equalTo: buttonLabel.trailingAnchor, constant: 4).isActive = true
        }
    }
    
    public func setFilter() {
        menuButton.setTitle(viewModel?.searchType.rawValue.bundleLocalized() ?? "", for: .normal)
    }
    
    // MARK: - Behavior
    
    @objc private func toggleSearch() {
        searchActive.toggle()
        
        let showSearch = searchActive
        
        UIView.animate(withDuration: 0.25) {
            self.titleLabel.alpha = showSearch ? 0 : 1
            self.searchField.alpha = showSearch ? 1 : 0
            self.menuButton.alpha = showSearch ? 1 : 0
            self.dropDownImageView.alpha = showSearch ? 1 : 0
            
            let iconName = showSearch ? "xmark" : "magnifyingglass"
            self.searchButton.imageView.image = UIImage(systemName: iconName)
        }
        
        if showSearch {
            searchField.becomeFirstResponder()
        } else {
            searchField.resignFirstResponder()
            searchField.text = ""
            
            /// Reset search type filter
            viewModel?.searchType = .name
            setFilter()
            
            viewModel?.searchContactString = ""
            /// We have to call UpdateUI her,
            /// because the searchContactString newValue is different than the old value inside the
            /// ContactsViewModel.searchContactString
            viewModel?.delegate?.updateUI(animation: false, reloadSections: true)
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        overBlurEffectColorView.backgroundColor = isDark ? UIColor.clear : Color.App.accentUIColor
        menuButton.setTitleColor(isDark ? Color.App.accentUIColor : Color.App.whiteUIColor, for: .normal)
    }
}

extension ContactsNavigationBar: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        viewModel?.searchContactString = newText
        return true
    }
}
