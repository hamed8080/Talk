//
//  MemberSearchTextFieldCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import UIKit
import SwiftUI
import TalkUI

final class MemberSearchTextFieldCell: UITableViewCell {
    
    // MARK: - View Models
    var viewModel: ParticipantsViewModel?
    
    // MARK: - UI Components
    private let searchContainer = UIStackView()
    private let iconView = UIImageView()
    private let textField = UITextField()
    private let menuButton = UIButton(type: .system)
    
    // MARK: - State
    private var showPopover = false
    public static let identifier = "MEMBER-SEARCH-CELL"
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupPopover()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = Color.App.bgSecondaryUIColor
        backgroundColor = Color.App.bgSecondaryUIColor
        
        // Container stack
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Search box
        searchContainer.axis = .horizontal
        searchContainer.alignment = .center
        searchContainer.spacing = 8
        searchContainer.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        iconView.image = UIImage(systemName: "magnifyingglass")
        iconView.tintColor = Color.App.textSecondaryUIColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        textField.placeholder = "General.searchHere".bundleLocalized()
        textField.font = UIFont.normal(.body)
        textField.returnKeyType = .done
        textField.delegate = self
        textField.textAlignment = Language.isRTL ? .right : .left
        textField.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        textField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        
        searchContainer.addArrangedSubview(iconView)
        searchContainer.addArrangedSubview(textField)
        hStack.addArrangedSubview(searchContainer)
        hStack.addArrangedSubview(menuButton)
        
        // Search Type Button
        updateSearchTypeButton()
    }
    
    private func updateSearchTypeButton() {
        let title = viewModel?.searchType.rawValue ?? ""
        let image = UIImage(systemName: "chevron.down")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = image
        config.imagePadding = 4
        config.baseForegroundColor = Color.App.textSecondaryUIColor
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var newAttrs = attrs
            newAttrs.font = UIFont.bold(.caption3)
            return newAttrs
        }
        
        menuButton.configuration = config
    }
    
    // MARK: - Popover Setup
    private func setupPopover() {
        // Configure menu button
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        menuButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Default value
        let defualtType = SearchParticipantType.name
        menuButton.setTitle(defualtType.rawValue.bundleLocalized() ?? "", for: .normal)
        viewModel?.searchType = defualtType
        
        let actions = SearchParticipantType.allCases.filter({ $0 != .admin }).compactMap({ type in
            UIAction(title: type.rawValue.bundleLocalized(), image: nil) { [weak self] _ in
                self?.viewModel?.searchType = type
                self?.menuButton.setTitle(type.rawValue.bundleLocalized() ?? "", for: .normal)
            }
        })
        menuButton.menu = UIMenu(title: "", children: actions)
    }
    
    @objc private func textDidChange(_ textField: UITextField) {
        viewModel?.searchText = textField.text ?? ""
    }
}

// MARK: - UITextFieldDelegate
extension MemberSearchTextFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
