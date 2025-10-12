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
    private let titleLabel = UILabel()
    private let searchButton = UIButton(type: .system)
    private let searchField = UITextField()
    private let menuButton = UIButton(type: .system)
    private var searchActive = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {

        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityIdentifier = "effectContactsNavigationBar"
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)
        
        titleLabel.text = "Contacts"
        titleLabel.font = UIFont.fBoldSubheadline
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = Color.App.toolbarButtonUIColor
        addSubview(titleLabel)
        
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(toggleSearch), for: .touchUpInside)
        addSubview(searchButton)
        
        // Configure search field
        searchField.placeholder = "Search..."
        searchField.borderStyle = .roundedRect
        searchField.alpha = 0
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.layer.cornerRadius = 8
        searchField.layer.masksToBounds = true
        addSubview(searchField)
        
        // Configure menu button
        menuButton.setTitle("Test", for: .normal)
        menuButton.alpha = 0
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = UIMenu(title: "", children: [
            UIAction(title: "Sort", image: UIImage(systemName: "arrow.up.arrow.down")) { _ in
                print("Sort tapped")
            },
            UIAction(title: "Filter", image: UIImage(systemName: "line.3.horizontal.decrease.circle")) { _ in
                print("Filter tapped")
            },
            UIAction(title: "Settings", image: UIImage(systemName: "gearshape")) { _ in
                print("Settings tapped")
            }
        ])
        addSubview(menuButton)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 64),
            
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
    
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 16),
            
            searchButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            searchButton.heightAnchor.constraint(equalToConstant: 48),

            searchField.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -8),
            
            menuButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            menuButton.leadingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: 16),
            menuButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -16),
            menuButton.widthAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    // MARK: - Behavior
    
    @objc private func toggleSearch() {
        searchActive.toggle()
        
        let showSearch = searchActive
        
        UIView.animate(withDuration: 0.25) {
            self.titleLabel.alpha = showSearch ? 0 : 1
            self.searchField.alpha = showSearch ? 1 : 0
            self.menuButton.alpha = showSearch ? 1 : 0
            
            let iconName = showSearch ? "xmark" : "magnifyingglass"
            self.searchButton.setImage(UIImage(systemName: iconName), for: .normal)
        }
        
        if showSearch {
            searchField.becomeFirstResponder()
        } else {
            searchField.resignFirstResponder()
        }
    }
}
