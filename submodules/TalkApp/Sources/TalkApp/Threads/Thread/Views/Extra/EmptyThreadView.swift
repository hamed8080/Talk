//
//  EmptyThreadView.swift
//  Talk
//
//  Created by hamed on 3/7/24.
//

import SwiftUI
import TalkViewModels
import TalkUI

public final class EmptyThreadView: UIView {
    private let vStack = UIStackView()
    private var vStackWidthConstraint: NSLayoutConstraint?
    private var animator: FadeInOutAnimator?

    public init() {
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        accessibilityIdentifier = "emptyThreadViewThreadViewController"
        
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.alignment = .center
        vStack.layoutMargins = .init(horizontal: 48, vertical: 48)
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.layer.masksToBounds = true
        vStack.layer.cornerRadius = 12
        vStack.accessibilityIdentifier = "vStackEmptyThreadView"

        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.accessibilityIdentifier = "effectViewEmptyThreadView"
        vStack.addSubview(effectView)

        let label = UILabel()
        label.textColor = Color.App.textPrimaryUIColor
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.normal(.subtitle)
        label.accessibilityIdentifier = "labelEmptyThreadView"

        let image = UIImageView(image: nil)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        image.tintColor = Color.App.accentUIColor
        image.accessibilityIdentifier = "imageEmptyThreadView"

        vStack.addArrangedSubview(label)
        vStack.addArrangedSubview(image)

        addSubview(vStack)

        vStackWidthConstraint = vStack.widthAnchor.constraint(equalToConstant: 320)
        vStackWidthConstraint?.isActive = true
        NSLayoutConstraint.activate([
            vStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            image.widthAnchor.constraint(equalToConstant: 36),
            image.heightAnchor.constraint(equalToConstant: 36)
        ])
        prepareIU(image, label)
    }

    private func prepareIU(_ imageView: UIImageView, _ label: UILabel) {
        Task.detached {
            let image = UIImage(systemName: "text.bubble")
            let text = "Thread.noMessage".bundleLocalized()
            await MainActor.run {
                label.text = text
                imageView.image = image
            }
        }
    }
    
    public func attachToParent(parent: UIView) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: vStack.heightAnchor),
            leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor),
            centerYAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.centerYAnchor),
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let isLarge = bounds.width > 400
        vStackWidthConstraint?.constant = isLarge ? 340 : bounds.width - 16
    }
    
    public func show(_ show: Bool, parent: UIView) {
        if animator == nil {
            animator = FadeInOutAnimator(view: self)
        } else {
            animator?.cancelAnimation()
        }
        if show, superview == nil {
            attachToParent(parent: parent)
        }
        parent.bringSubviewToFront(self)
        animator?.startAnimation(show: show)
    }
}
