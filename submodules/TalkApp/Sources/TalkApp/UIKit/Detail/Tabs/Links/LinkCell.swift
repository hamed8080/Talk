//
//  LinkCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/25/25.
//

import UIKit
import SwiftUI

class LinkCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let linkImageView = PaddingUIImageView()
    private let separator = TableViewControllerDevider()
    public var onContextMenu: ((UIGestureRecognizer) -> Void)?
   
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
        
        /// Links label of the conversation.
        titleLabel.font = UIFont.normal(.subheadline)
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.accessibilityIdentifier = "LinkCell.titleLable"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        /// Static image icon.
        linkImageView.accessibilityIdentifier = "LinkCell.linkImageView"
        linkImageView.translatesAutoresizingMaskIntoConstraints = false
        linkImageView.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        linkImageView.layer.cornerRadius = 8
        linkImageView.contentMode = .scaleAspectFit
        linkImageView.tintColor = Color.App.whiteUIColor
        linkImageView.set(image: UIImage(systemName: "link") ?? .init(), inset: .init(all: 6))
        contentView.addSubview(linkImageView)
        
        contentView.addSubview(separator)
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = 0.3
        addGestureRecognizer(longGesture)
        
        NSLayoutConstraint.activate([
            
            linkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            linkImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            linkImageView.widthAnchor.constraint(equalToConstant: 36),
            linkImageView.heightAnchor.constraint(equalToConstant: 36),
            
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: linkImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            separator.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -ConstantSizes.tableViewSeparatorLeading),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: ConstantSizes.tableViewSeparatorHeight),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
        ])
    }
    
    public func setItem(_ item: TabRowModel) {
        titleLabel.text = item.links.joined(separator: "\n")
    }
    
    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        onContextMenu?(sender)
    }
}
