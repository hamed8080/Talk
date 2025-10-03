//
//  GroupParticipantNameView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Chat
import TalkModels

final class GroupParticipantNameView: UILabel {
    private var heightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        font = UIFont.fBoldBody
        numberOfLines = 1
        isOpaque = true
        heightConstraint = heightAnchor.constraint(equalToConstant: MessageRowSizes.groupParticipantNameViewHeight)
        heightConstraint.identifier = "heightConstraintGroupParticipantNameView"
        NSLayoutConstraint.activate([
            heightConstraint
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let name = viewModel.calMessage.groupMessageParticipantName
        textColor = viewModel.calMessage.participantColor
        textAlignment = .left
        text = name
    }
}
