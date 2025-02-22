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
        dateLabel.font = UIFont.uiiransansBody
        dateLabel.accessibilityIdentifier = "dateLabelCallEventCell"

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        stack.accessibilityIdentifier = "stackCallEventCell"

        stack.addArrangedSubview(dateLabel)
        stack.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        stack.layer.cornerRadius = 14
        stack.layer.masksToBounds = true
        stack.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 32),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        dateLabel.attributedText = viewModel.calMessage.callAttributedString
    }
}
