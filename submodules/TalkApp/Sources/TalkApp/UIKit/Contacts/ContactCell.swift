//
//  ContactCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import SwiftUI
import Chat

class ContactCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let notFoundLabel = UILabel()
    private let inviteButton = UIButton()
    private let blockedLable = UILabel()
    private let radio = SelectMessageRadio()
    private let avatar = UIImageView(frame: .zero)
    private let avatarInitialLable = UILabel()
    private var radioIsHidden = true
    private var showInvite = true

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
        
        /// Full name lable
        titleLabel.font = UIFont.fBoldSubheadline
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.textAlignment = .center
        titleLabel.accessibilityIdentifier = "ContactCell.titleLable"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        /// Not found label
        notFoundLabel.font = UIFont.fBoldCaption2
        notFoundLabel.textColor = Color.App.accentUIColor
        notFoundLabel.textAlignment = .center
        notFoundLabel.text = "Contctas.list.notFound".bundleLocalized()
        notFoundLabel.accessibilityIdentifier = "ContactCell.notFoundLabel"
        notFoundLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notFoundLabel)
        
        /// Invite button
        inviteButton.titleLabel?.font = UIFont.fBoldCaption2
        inviteButton.setTitleColor(Color.App.whiteUIColor, for: .normal)
        inviteButton.setTitle("Contacts.invite".bundleLocalized(), for: .normal)
        inviteButton.accessibilityIdentifier = "ContactCell.inviteButton"
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        inviteButton.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        inviteButton.layer.cornerRadius = 16
        contentView.addSubview(inviteButton)
        
        /// Block label
        blockedLable.font = UIFont.fCaption2
        blockedLable.textColor = Color.App.redUIColor
        blockedLable.textAlignment = .center
        blockedLable.text = "General.blocked".bundleLocalized()
        blockedLable.accessibilityIdentifier = "ContactCell.blockedLable"
        blockedLable.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(blockedLable)
        
        /// Selection radio
        radio.accessibilityIdentifier = "ContactCell.radio"
        radio.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(radio)
        
        /// Avatar or user name abbrevation
        avatar.accessibilityIdentifier = "ContactCell.avatar"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 22
        avatar.layer.masksToBounds = true
        avatar.contentMode = .scaleAspectFill
        contentView.addSubview(avatar)
        
        avatarInitialLable.accessibilityIdentifier = "ContactCell.avatarInitialLable"
        avatarInitialLable.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLable.layer.cornerRadius = 22
        avatarInitialLable.layer.masksToBounds = true
        avatarInitialLable.textAlignment = .center
        avatarInitialLable.font = UIFont.fBoldBody
        
        contentView.addSubview(avatarInitialLable)
        
        NSLayoutConstraint.activate([
            radio.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radio.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatar.leadingAnchor.constraint(equalTo: radio.trailingAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 58),
            avatar.heightAnchor.constraint(equalToConstant: 58),
            
            avatarInitialLable.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarInitialLable.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarInitialLable.widthAnchor.constraint(equalToConstant: 52),
            avatarInitialLable.heightAnchor.constraint(equalToConstant: 52),
            
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: inviteButton.leadingAnchor, constant: 16),
            
            notFoundLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            notFoundLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            inviteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            inviteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            inviteButton.widthAnchor.constraint(equalToConstant: 64),
            
            blockedLable.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            blockedLable.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        ])
        
        radio.isHidden = radioIsHidden
        if radioIsHidden {
            radio.removeFromSuperview()
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        }
        notFoundLabel.isHidden = true
        blockedLable.isHidden = true
        inviteButton.isHidden = true
    }
    
    public func setContact(contact: Contact, viewModel: ContactsViewModel) {
        titleLabel.text = "\(contact.firstName ?? "") \(contact.lastName ?? "")"

        blockedLable.isHidden = contact.blocked == false || contact.blocked == nil
        
        let isUser = (contact.hasUser == false || contact.hasUser == nil) && showInvite
        notFoundLabel.isHidden = !isUser
        inviteButton.isHidden = !isUser
        
        let contactName = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
        let isEmptyContactString = contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let name = !isEmptyContactString ? contactName : contact.user?.name
        
        avatar.backgroundColor = String.getMaterialColorByCharCode(str: name ?? "")
        avatarInitialLable.text = String.splitedCharacter(name ?? "")
        if let vm = viewModel.imageLoader(for: contact.id ?? -1) {
            avatar.image = vm.image
            avatarInitialLable.isHidden = vm.isImageReady
        } else {
            avatarInitialLable.isHidden = false
        }
    }
    
    public func setImage(_ image: UIImage?) {
        avatar.image = image
        avatarInitialLable.isHidden = image != nil
    }
}
