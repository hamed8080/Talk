//
//  CustomizeReactionsToolbar.swift
//  Talk
//
//  Created by hamed on 7/31/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkUI
import SwiftUI

public final class CustomizeReactionsToolbar: UIView {
    private weak var viewModel: ThreadViewModel?
    private let title = UILabel()

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configure()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityIdentifier = "effectViewTopThreadToolbar"
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        let backButton = UIImageButton(imagePadding: .init(all: 8))
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.imageView.image = UIImage(systemName: "chevron.backward")
        backButton.imageView.tintColor = Color.App.accentUIColor
        backButton.imageView.contentMode = .scaleAspectFit
        backButton.imageView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        backButton.accessibilityIdentifier = "backButtonCustomConversationNavigationBar"
        backButton.action = { [weak self] in
            (self?.viewModel?.delegate as? UIViewController)?.navigationController?.popViewController(animated: true)
        }

        addSubview(backButton)


        title.text = "EditGroup.customizedReactions".bundleLocalized()
        title.textColor = Color.App.accentUIColor
        title.font = UIFont.fSubheadline
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 46),

            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            backButton.widthAnchor.constraint(equalToConstant: 36),

            title.centerXAnchor.constraint(equalTo: centerXAnchor),
            title.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            title.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
}
