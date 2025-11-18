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
    private let label = PaddingUILabel(frame: .zero,
                                       horizontal: ConstantSizes.messageParticipantsEventCellLableHorizontalPadding,
                                       vertical: ConstantSizes.messageParticipantsEventCellLableVerticalPadding)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.label.font = UIFont.normal(.body)
        label.label.numberOfLines = 0
        label.label.textColor = Color.App.textPrimaryUIColor
        label.layer.cornerRadius = ConstantSizes.messageParticipantsEventCellCornerRadius
        label.layer.masksToBounds = true
        label.label.textAlignment = .center
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        label.accessibilityIdentifier = "labelParticipantsEventCell"

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 1, constant: -ConstantSizes.messageParticipantsEventCellWidthRedaction),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ConstantSizes.messageParticipantsEventCellMargin),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ConstantSizes.messageParticipantsEventCellMargin),
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
    
    private func setSelectedBackground(highlight: Bool) {
        if highlight {
            let dark = traitCollection.userInterfaceStyle == .dark
            let selectedColor = dark ? Color.App.accentUIColor?.withAlphaComponent(0.4) : Color.App.dividerPrimaryUIColor?.withAlphaComponent(0.5)
            contentView.backgroundColor = selectedColor
        } else {
            contentView.backgroundColor = nil
        }
    }
    
    public func setHighlight(highlight: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.setSelectedBackground(highlight: highlight)
        }
    }
}
