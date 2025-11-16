//
//  CallEventCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import UIKit

final class CallEventCell: UITableViewCell {
    // Views
    private let stack = UIStackView()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.normal(.body)
        dateLabel.accessibilityIdentifier = "dateLabelCallEventCell"

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = ConstantSizes.messageCallEventCellStackSapcing
        stack.accessibilityIdentifier = "stackCallEventCell"

        stack.addArrangedSubview(dateLabel)
        stack.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        stack.layer.cornerRadius = ConstantSizes.messageCallEventCellStackCornerRadius
        stack.layer.masksToBounds = true
        stack.layoutMargins = .init(top: 0, left: ConstantSizes.messageCallEventCellStackLayoutMargin, bottom: 0, right: ConstantSizes.messageCallEventCellStackLayoutMargin)
        stack.isLayoutMarginsRelativeArrangement = true
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: ConstantSizes.messageCallEventCellHeight),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ConstantSizes.messageCallEventCellStackMargin),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ConstantSizes.messageCallEventCellStackMargin),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        dateLabel.attributedText = viewModel.calMessage.callAttributedString
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
