//
//  CustomizeReactionSectionHeader.swift
//  Talk
//
//  Created by hamed on 7/31/24.
//

import Foundation
import UIKit
import SwiftUI
import TalkModels

final class CustomizeReactionSectionHeader: UICollectionReusableView {
    static let reuseIdentifier = String(describing: CustomizeReactionSectionHeader.self)

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Color.App.textPrimaryUIColor
        label.font = UIFont.fSubheadline
        label.textAlignment = Language.isRTL ? .right : .left

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func setText(_ text: String) {
        label.text = text
    }
}
