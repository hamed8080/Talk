//
//  UIEmojiSectionHeaderLabelView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/14/26.
//

import UIKit
import SwiftUI

public final class UIEmojiSectionHeaderLabelView: UICollectionReusableView {
    static let identifier = "UIEmojiSectionHeaderLabelView"
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = Language.isRTL ? .right : .left
        label.textColor = Color.App.textSecondaryUIColor
        label.font = UIFont.bold(.body)
        addSubview(label)

        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
