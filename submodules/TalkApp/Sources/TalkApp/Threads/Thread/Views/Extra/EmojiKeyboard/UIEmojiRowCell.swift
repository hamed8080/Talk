//
//  UIEmojiRowCell.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/14/26.
//

import Foundation
import UIKit

final class UIEmojiRowCell: UICollectionViewCell {
    static let identifier: String = "UIEmojiRowCell"
    let label = UILabel()
    private let margin: CGFloat = 4
    
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
        layer.cornerRadius = contentView.frame.height / 2.0
        layer.masksToBounds = false
        
        label.contentMode = .scaleAspectFit
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.normal(.largeTitle).withSize(38)
        label.textAlignment = .center
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor , constant: -margin),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin),
        ])
    }
}
