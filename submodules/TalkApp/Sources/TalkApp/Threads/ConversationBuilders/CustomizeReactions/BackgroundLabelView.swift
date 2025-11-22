//
//  BackgroundLabelView.swift
//  Talk
//
//  Created by hamed on 7/31/24.
//

import Foundation
import UIKit
import SwiftUI

public final class BackgroundLabelView: UICollectionReusableView {
    static let reuseIdentifier = "BackgroundLabelView"
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
        label.textAlignment = .center
        label.textColor = Color.App.textPrimaryUIColor
        label.font = UIFont.normal(.body)
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
}
