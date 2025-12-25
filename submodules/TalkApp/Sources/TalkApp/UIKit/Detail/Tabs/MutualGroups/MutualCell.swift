//
//  MutualCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/25/25.
//

import UIKit
import SwiftUI

class MutualCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let avatarInitialLable = UILabel()
    private let avatar = UIImageView(frame: .zero)
    private let separator = TableViewControllerDevider()
   
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
        
        /// Title of the conversation.
        titleLabel.font = UIFont.normal(.subheadline)
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.accessibilityIdentifier = "ConversationCell.titleLable"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        /// Avatar or user name abbrevation
        avatar.accessibilityIdentifier = "ConversationCell.avatar"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 20
        avatar.layer.masksToBounds = true
        avatar.contentMode = .scaleAspectFill
        contentView.addSubview(avatar)
        
        /// User initial over the avatar image if the image is nil.
        avatarInitialLable.accessibilityIdentifier = "ConversationCell.avatarInitialLable"
        avatarInitialLable.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLable.layer.cornerRadius = 22
        avatarInitialLable.layer.masksToBounds = true
        avatarInitialLable.textAlignment = .center
        avatarInitialLable.font = UIFont.normal(.subheadline)
        avatarInitialLable.textColor = Color.App.whiteUIColor
        contentView.addSubview(avatarInitialLable)
        
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 48),
            avatar.heightAnchor.constraint(equalToConstant: 48),
            
            avatarInitialLable.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarInitialLable.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarInitialLable.widthAnchor.constraint(equalToConstant: 38),
            avatarInitialLable.heightAnchor.constraint(equalToConstant: 38),
            
            titleLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            separator.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -ConstantSizes.tableViewSeparatorLeading),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: ConstantSizes.tableViewSeparatorHeight),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
        ])
    }
    
    public func setConversation(conversation: CalculatedConversation) {
        titleLabel.text = conversation.computedTitle
        avatar.backgroundColor = String.getMaterialColorByCharCode(str: conversation.title ?? "")
        avatarInitialLable.text = String.splitedCharacter(conversation.computedTitle)
        let loader = conversation.imageLoader as? ImageLoaderViewModel
        let image = loader?.isImageReady == true ? loader?.image : nil
        setImage(image)
    }
    
    public func setImage(_ image: UIImage?) {
        avatar.image = image
        avatarInitialLable.isHidden = image != nil
    }
}
