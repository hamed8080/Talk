//
//  ReactionCountRowView.swift
//  Talk
//
//  Created by hamed on 7/22/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkModels
import SwiftUI

final class ReactionCountRowView: UIView, UIContextMenuInteractionDelegate {
    // Views
    private let reactionEmojiCount = UILabel()

    // Models
    var row: ReactionRowsCalculated.Row?
    weak var viewModel: MessageRowViewModel?

    // Sizes
    private let totalWidth: CGFloat = 42
    private let emojiWidth: CGFloat = 20
    private let margin: CGFloat = 8

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 14
        layer.masksToBounds = true
        semanticContentAttribute = isMe == true ? .forceRightToLeft : .forceLeftToRight

        reactionEmojiCount.translatesAutoresizingMaskIntoConstraints = false
        reactionEmojiCount.font = UIFont.uiiransansBody
        reactionEmojiCount.textAlignment = .center
        reactionEmojiCount.accessibilityIdentifier = "reactionEmoji"
        reactionEmojiCount.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(reactionEmojiCount)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: totalWidth),
            heightAnchor.constraint(equalToConstant: 28),
            reactionEmojiCount.heightAnchor.constraint(equalToConstant: emojiWidth),
            reactionEmojiCount.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            reactionEmojiCount.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            reactionEmojiCount.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
        ])

        let menu = UIContextMenuInteraction(delegate: self)
        addInteraction(menu)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        addGestureRecognizer(tapGesture)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return ReactionRowContextMenuCofiguration.config(interaction: interaction)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: any NSCopying) -> UITargetedPreview? {
        guard let row = row else { return nil }
        return ReactionRowContextMenuCofiguration.targetedView(view: self, row: row, viewModel: viewModel)
    }

    func prepareContextMenu() {
        isUserInteractionEnabled = false
    }

    func setValue(row: ReactionRowsCalculated.Row) {
        self.row = row
        reactionEmojiCount.text = "\(row.emoji) \(row.countText)"
        backgroundColor = row.isMyReaction ? Color.App.color1UIColor?.withAlphaComponent(0.9) : Color.App.accentUIColor?.withAlphaComponent(0.1)
    }

    @objc private func onTapped(_ sender: UIGestureRecognizer) {
        if viewModel?.threadVM?.thread.reactionStatus == .disable { return }
        if let messageId = viewModel?.message.id, let sticker = row?.sticker {
            let myRow = viewModel?.reactionsModel.rows.first(where: {$0.isMyReaction})
            viewModel?.threadVM?.reactionViewModel.reaction(sticker, messageId: messageId, myReactionId: myRow?.myReactionId, myReactionSticker: myRow?.sticker)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.7
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
}
