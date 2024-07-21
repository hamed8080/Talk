//
//  UnreadBubbleCell.swift
//  Talk
//
//  Created by hamed on 7/6/23.
//

import SwiftUI
import ChatModels
import TalkViewModels

final class UnreadBubbleCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = true
        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont.uiiransansCaption
        label.textColor = Color.App.accentUIColor
        label.textAlignment = .center
        label.text = "Messages.unreadMessages".bundleLocalized()
        label.backgroundColor = Color.App.bgPrimaryUIColor
        label.accessibilityIdentifier = "labelUnreadBubbleCell"

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])
    }
}
