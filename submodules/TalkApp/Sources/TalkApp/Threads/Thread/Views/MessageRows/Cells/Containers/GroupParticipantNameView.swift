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
        textAlignment = .left
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ConstantSizes.groupParticipantNameViewHeight)
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        textColor = viewModel.calMessage.participantColor
        text = viewModel.calMessage.groupMessageParticipantName
    }
}
