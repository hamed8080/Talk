//
//  FooterReactionsCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import TalkExtensions
import TalkViewModels
import SwiftUI
import Chat
import TalkUI
import TalkModels

final class FooterReactionsCountView: UIStackView {
    // Sizes
    private let maxReactionsToShow: Int = 4
    private let height: CGFloat = 28
    private let margin: CGFloat = 28
    private weak var viewModel: MessageRowViewModel?
    static let moreButtonId = -2

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 4
        alignment = .fill
        distribution = .fillProportionally
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        accessibilityIdentifier = "stackReactionCountScrollView"

        for _ in 0..<maxReactionsToShow {
            addArrangedSubview(ReactionCountRowView(frame: .zero, isMe: isMe))
        }

        addArrangedSubview(MoreReactionButtonRow(frame: .zero, isMe: isMe))

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let rows = viewModel.reactionsModel.rows.count > maxReactionsToShow ? Array(viewModel.reactionsModel.rows.prefix(4)) : viewModel.reactionsModel.rows

        // Show item only if index is equal to index or it is type of more reaction button.
        arrangedSubviews.enumerated().forEach { index, view in
            if index < rows.count, let rowView = view as? ReactionCountRowView {
                rowView.setIsHidden(false)
                rowView.setValue(row: rows[index])
                rowView.viewModel = viewModel
            } else {
                view.setIsHidden(true)
            }
        }
        if viewModel.reactionsModel.rows.count > maxReactionsToShow, let moreButton = arrangedSubviews[maxReactionsToShow] as? MoreReactionButtonRow {
            moreButton.setIsHidden(false)
            moreButton.row = .init(reactionId: FooterReactionsCountView.moreButtonId,
                                   edgeInset: .zero,
                                   sticker: nil,
                                   emoji: "",
                                   countText: "",
                                   isMyReaction: false,
                                   hasReaction: false,
                                   selectedEmojiTabId: "General.all")
            moreButton.viewModel = viewModel
        }
    }
}
