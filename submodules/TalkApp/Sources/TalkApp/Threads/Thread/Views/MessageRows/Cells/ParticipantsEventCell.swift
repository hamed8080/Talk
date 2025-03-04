//
//  ParticipantsEventCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels

final class ParticipantsEventCell: UITableViewCell {
    private let label = PaddingUILabel(frame: .zero, horizontal: 16, vertical: 8)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.label.font = UIFont.fBody
        label.label.numberOfLines = 0
        label.label.textColor = Color.App.textPrimaryUIColor
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.label.textAlignment = .center
        label.backgroundColor = .black.withAlphaComponent(0.4)
        label.accessibilityIdentifier = "labelParticipantsEventCell"

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 1, constant: -24),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])

        // Set content compression resistance priority
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Set content hugging priority
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    public func setValues(viewModel: MessageRowViewModel) {
        label.label.attributedText = viewModel.calMessage.addOrRemoveParticipantsAttr
    }
}
