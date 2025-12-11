//
//  MentionCell.swift
//  Talk
//
//  Created by hamed on 6/8/24.
//

import Foundation
import UIKit
import TalkUI
import SwiftUI
import TalkViewModels
import ChatModels

final class MentionCell: UITableViewCell {
    private let lblName = UILabel()
    private let lblUserName = UILabel()
    private let imageParticipant = MentionParticipantImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        backgroundColor = .clear
        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.layoutMargins = .init(all: 8)
        hStack.isLayoutMarginsRelativeArrangement = true
        hStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        hStack.accessibilityIdentifier = "hStackMentionCell"

        lblName.font = UIFont.normal(.caption2)
        lblName.textColor = Color.App.textPrimaryUIColor
        lblName.numberOfLines = 1
        lblName.accessibilityIdentifier = "lblNameMentionCell"

        lblUserName.font = UIFont.normal(.caption2)
        lblUserName.textColor = Color.App.accentUIColor
        lblUserName.numberOfLines = 1
        lblUserName.accessibilityIdentifier = "lblUserNameMentionCell"

        imageParticipant.translatesAutoresizingMaskIntoConstraints = false
        imageParticipant.accessibilityIdentifier = "imageParticipantMentionCell"

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.alignment = .leading
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.layoutMargins = .init(all: 4)
        vStack.accessibilityIdentifier = "vStackMentionCell"
        vStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        vStack.addArrangedSubview(lblName)
        vStack.addArrangedSubview(lblUserName)
        
        hStack.addArrangedSubview(imageParticipant)
        hStack.addArrangedSubview(vStack)
        contentView.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageParticipant.widthAnchor.constraint(equalToConstant: 32), // Cell height - paddings 48 - (8 * 2)
            imageParticipant.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    public func setValues(_ viewModel: ThreadViewModel, _ participant: Participant) {
        lblName.text = participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")"
        lblUserName.text = participant.username ?? ""
        let vm = viewModel.mentionListPickerViewModel.avatarVMS[participant.id ?? 0]
        imageParticipant.setValues(vm: vm, participant: participant)
    }
}
