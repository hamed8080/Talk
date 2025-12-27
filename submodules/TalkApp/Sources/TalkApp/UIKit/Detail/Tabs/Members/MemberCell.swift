//
//  MemberCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import TalkViewModels
import TalkModels
import Chat
import SwiftUI

class MemberCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let avatar = UIImageView()
    private let adminLabel = UILabel()
    private let assistantLabel = UILabel()
    private let avatarInitialLable = UILabel()
    let separtor = UIView()
    
    public var onContextMenu: ((UIGestureRecognizer) -> Void)?
    public weak var viewModel: ParticipantsViewModel?
    public static let identifier = "MEMBER-ROW"
   
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
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = 0.3
        addGestureRecognizer(longGesture)
        
        /// Title.
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.normal(.subheadline)
        nameLabel.textColor = Color.App.textPrimaryUIColor
        nameLabel.accessibilityIdentifier = "MemberCell.nameLable"
        nameLabel.textAlignment = Language.isRTL ? .right : .left
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)
        
        /// Avatar or user name abbrevation
        avatar.accessibilityIdentifier = "MemberCell.avatar"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 22
        avatar.layer.masksToBounds = true
        avatar.contentMode = .scaleAspectFill
        contentView.addSubview(avatar)
        
        avatarInitialLable.accessibilityIdentifier = "MemberCell.avatarInitialLable"
        avatarInitialLable.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLable.layer.cornerRadius = 22
        avatarInitialLable.layer.masksToBounds = true
        avatarInitialLable.textAlignment = .center
        avatarInitialLable.font = UIFont.bold(.body)
        avatarInitialLable.textColor = Color.App.whiteUIColor
        contentView.addSubview(avatarInitialLable)
        
        /// Admin.
        adminLabel.font = UIFont.bold(.caption)
        adminLabel.textColor = Color.App.accentUIColor
        adminLabel.accessibilityIdentifier = "MemberCell.adminLabel"
        adminLabel.translatesAutoresizingMaskIntoConstraints = false
        adminLabel.textAlignment = Language.isRTL ? .right : .left
        adminLabel.numberOfLines = 1
        adminLabel.text = "Participant.admin".bundleLocalized()
        contentView.addSubview(adminLabel)
        
        /// Assistant.
        assistantLabel.font = UIFont.bold(.caption)
        assistantLabel.textColor = Color.App.accentUIColor
        assistantLabel.accessibilityIdentifier = "MemberCell.assistantLabel"
        assistantLabel.translatesAutoresizingMaskIntoConstraints = false
        assistantLabel.textAlignment = Language.isRTL ? .right : .left
        assistantLabel.numberOfLines = 1
        assistantLabel.text = "Participant.assistant".bundleLocalized()
        contentView.addSubview(assistantLabel)
        
        /// Separator.
        separtor.accessibilityIdentifier = "MemberCell.separatorLabel"
        separtor.translatesAutoresizingMaskIntoConstraints = false
        separtor.backgroundColor = Color.App.dividerPrimaryUIColor
        contentView.addSubview(separtor)
    
        NSLayoutConstraint.activate([
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 48),
            avatar.heightAnchor.constraint(equalToConstant: 48),
            
            avatarInitialLable.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarInitialLable.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarInitialLable.widthAnchor.constraint(equalToConstant: 48),
            avatarInitialLable.heightAnchor.constraint(equalToConstant: 48),
            
            nameLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: assistantLabel.leadingAnchor, constant: -8),
            
            adminLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            adminLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            assistantLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            assistantLabel.trailingAnchor.constraint(equalTo: adminLabel.leadingAnchor, constant: -8),
            
            separtor.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 64),
            separtor.heightAnchor.constraint(equalToConstant: 0.5),
            separtor.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            separtor.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    public func setItem(_ participant: Participant, _ image: UIImage?) {
        let name = participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")"
        nameLabel.text = name
        avatar.backgroundColor = String.getMaterialColorByCharCode(str: name ?? "")
        avatarInitialLable.text = String.splitedCharacter(name ?? "")
        avatarInitialLable.isHidden = image != nil
        avatar.image = image
        let isAdmin = participant.admin == true || viewModel?.thread?.inviter?.id == participant.id
        adminLabel.isHidden = !isAdmin
        assistantLabel.isHidden = participant.auditor != true
        separtor.isHidden = viewModel?.list.last == participant
    }
    
    public func updateImage(_ image: UIImage?) {
        avatar.image = image
        avatarInitialLable.isHidden = image != nil
    }
    
    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        onContextMenu?(sender)
    }
}
