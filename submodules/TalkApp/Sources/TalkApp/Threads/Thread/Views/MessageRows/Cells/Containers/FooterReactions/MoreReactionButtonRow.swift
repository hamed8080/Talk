//
//  MoreReactionButtonRow.swift
//  Talk
//
//  Created by hamed on 7/22/24.
//

import Foundation
import TalkViewModels
import UIKit
import TalkModels
import SwiftUI

class MoreReactionButtonRow: UIView, UIContextMenuInteractionDelegate {
    // Views
    private let imgCenter = UIImageView()

    // Models
    weak var viewModel: MessageRowViewModel?
    var row: ReactionRowsCalculated.Row?

    // Sizes
    private let totlaWidth: CGFloat = 42
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

        imgCenter.image = UIImage(systemName: "chevron.down")
        imgCenter.translatesAutoresizingMaskIntoConstraints = false
        imgCenter.contentMode = .scaleAspectFit
        imgCenter.tintColor = Color.App.textSecondaryUIColor
        imgCenter.accessibilityIdentifier = "imgCenterMoveToBottomButton"
        addSubview(imgCenter)

        let menu = UIContextMenuInteraction(delegate: self)
        addInteraction(menu)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: totlaWidth),
            imgCenter.heightAnchor.constraint(equalToConstant: emojiWidth),
            imgCenter.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            imgCenter.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            imgCenter.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
        ])
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return ReactionRowContextMenuCofiguration.config(interaction: interaction)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: any NSCopying) -> UITargetedPreview? {
        guard let row = row else { return nil }
        return ReactionRowContextMenuCofiguration.targetedView(view: self, row: row, viewModel: viewModel)
    }
}
