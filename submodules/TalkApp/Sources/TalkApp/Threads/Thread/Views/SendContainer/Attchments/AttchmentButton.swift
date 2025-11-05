//
//  AttchmentButton.swift
//  Talk
//
//  Created by hamed on 6/17/24.
//

import Foundation
import UIKit
import SwiftUI
import TalkViewModels
import TalkUI

public final class AttchmentButton: UIStackView {
    private let imageContainer = UIView()
    private let imageView: UIImageView
    private let label: UILabel
    private var imageContainerWidthConstraint: NSLayoutConstraint!
    private var imageContainerHeightConstraint: NSLayoutConstraint!

    public init(title: String, image: String) {
        let image = UIImage(systemName: image)?.withRenderingMode(.alwaysTemplate)
        self.imageView = UIImageView(image: image)
        self.label = UILabel()
        label.text = title.bundleLocalized()
        super.init(frame: .zero)
        configureViews()
        registerGestures()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        axis = .vertical
        spacing = 4
        isUserInteractionEnabled = true
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Color.App.accentUIColor
        imageView.accessibilityIdentifier = "imageViewAttchmentButton"

        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.layer.borderColor = Color.App.textSecondaryUIColor?.withAlphaComponent(0.5).cgColor
        imageContainer.layer.borderWidth = 1
        imageContainer.layer.masksToBounds = true
        imageContainer.layer.cornerRadius = 24
        imageContainer.accessibilityIdentifier = "imageContainerAttchmentButton"
        imageContainer.addSubview(imageView)

        label.textColor = Color.App.textSecondaryUIColor
        label.font = UIFont.fCaption3
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.accessibilityIdentifier = "labelAttchmentButton"

        addArrangedSubviews([imageContainer, label])

        imageContainerWidthConstraint = imageContainer.widthAnchor.constraint(equalToConstant: 66)
        imageContainerWidthConstraint.identifier = "imageContainerWidthConstraintAttchmentButton"
        imageContainerHeightConstraint = imageContainer.heightAnchor.constraint(equalToConstant: 66)
        imageContainerHeightConstraint.identifier = "imageContainerHeightConstraintAttchmentButton"
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            imageContainerWidthConstraint,
            imageContainerHeightConstraint,
        ])
    }

    private func registerGestures() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(onPressingDown))
        addGestureRecognizer(gesture)
    }

    @objc private func onPressingDown(_ sender: UILongPressGestureRecognizer) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            imageContainerWidthConstraint.constant = sender.state == .began ? 52 : 66
            imageContainerHeightConstraint.constant = sender.state == .began ? 52 : 66
            imageContainer.backgroundColor = sender.state == .began ? Color.App.textSecondaryUIColor?.withAlphaComponent(0.5) : .clear
        }
    }
}
