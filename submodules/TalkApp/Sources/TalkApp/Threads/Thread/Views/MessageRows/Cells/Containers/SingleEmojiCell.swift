//
//  SingleEmojiView.swift
//  Talk
//
//  Created by hamed on 7/6/23.
//

import SwiftUI
import ChatModels
import TalkViewModels

final class SingleEmojiView: UILabel {
    
    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = true
        font = .systemFont(ofSize: 64)
        accessibilityIdentifier = "labelUnreadBubbleCell"
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 72),
        ])
    }
    
    public func set(_ viewModel: MessageRowViewModel) {
        text = viewModel.message.message
    }
}
