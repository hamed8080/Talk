//
//  UIEmojiRowCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/14/26.
//

import Foundation
import UIKit
import TalkViewModels

final class UIEmojiRowCell: UICollectionViewCell {
    static let identifier: String = "UIEmojiRowCell"
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        label.contentMode = .scaleAspectFit
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.normal(.largeTitle).withSize(ConstantSizes.emojiKeyboardLabelTextSize)
        label.textAlignment = .center
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ConstantSizes.emojiKeyboardLabelMargin),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor , constant: -ConstantSizes.emojiKeyboardLabelMargin),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ConstantSizes.emojiKeyboardLabelMargin),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ConstantSizes.emojiKeyboardLabelMargin),
        ])
    }
}
