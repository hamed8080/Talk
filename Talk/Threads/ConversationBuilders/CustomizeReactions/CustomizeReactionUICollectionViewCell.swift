//
//  CustomizeReactionUICollectionViewCell.swift
//  Talk
//
//  Created by hamed on 7/31/24.
//

import Foundation
import UIKit
import SwiftUI
import TalkUI

public final class CustomizeReactionUICollectionViewCell: UICollectionViewCell {
    static let identifier = String(describing: CustomizeReactionUICollectionViewCell.self)
    private let imageView = UIImageView()
    private let overlayIconImageContainer = UIView()
    private let overlayIconImageView = UIImageButton(imagePadding: .init(all: 3))
    private let margin: CGFloat = 16

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        overlayIconImageContainer.translatesAutoresizingMaskIntoConstraints = false
        overlayIconImageContainer.layer.cornerRadius = 10
        overlayIconImageContainer.layer.masksToBounds = true
        overlayIconImageContainer.layer.borderColor = Color.App.whiteUIColor?.cgColor
        overlayIconImageContainer.layer.borderWidth = 1.5
        contentView.addSubview(overlayIconImageContainer)

        overlayIconImageView.contentMode = .scaleAspectFit
        overlayIconImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayIconImageView.tintColor = UIColor.white
        overlayIconImageView.isUserInteractionEnabled = false
        overlayIconImageContainer.addSubview(overlayIconImageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor , constant: -margin),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin),

            overlayIconImageContainer.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -margin),
            overlayIconImageContainer.centerYAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            overlayIconImageContainer.widthAnchor.constraint(equalToConstant: 20),
            overlayIconImageContainer.heightAnchor.constraint(equalToConstant: 20),

            overlayIconImageView.leadingAnchor.constraint(equalTo: overlayIconImageContainer.leadingAnchor),
            overlayIconImageView.trailingAnchor.constraint(equalTo: overlayIconImageContainer.trailingAnchor),
            overlayIconImageView.topAnchor.constraint(equalTo: overlayIconImageContainer.topAnchor),
            overlayIconImageView.bottomAnchor.constraint(equalTo: overlayIconImageContainer.bottomAnchor),
        ])
    }

    private func image(emoji: String, size: CGFloat) -> UIImage {
        let font = UIFont.systemFont(ofSize: size)
        let emojiSize = emoji.size(withAttributes: [.font: font])

        let renderer = UIGraphicsImageRenderer(size: emojiSize)
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(.init(origin: .zero, size: emojiSize))
            emoji.draw(at: .zero, withAttributes: [.font: font])
        }
        return image
    }

    public func setModel(_ row: Item, type: CustomizeSectionType) {
        imageView.image = image(emoji: row.sticker.emoji, size: bounds.width)
        if type == .selected {
            overlayIconImageView.imageView.image = UIImage(systemName: "minus")
            overlayIconImageContainer.backgroundColor = UIColor(red: 244.0 / 255.0, green: 67.0 / 255.0, blue: 54.0 / 255.0, alpha: 1.0)
        } else {
            overlayIconImageView.imageView.image = UIImage(systemName: "plus")
            overlayIconImageContainer.backgroundColor = UIColor(red: 0.0 / 255.0, green: 120.0 / 255.0, blue: 212.0 / 255.0, alpha: 1.0)
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
}
