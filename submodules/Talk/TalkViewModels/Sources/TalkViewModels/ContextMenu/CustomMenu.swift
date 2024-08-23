//
//  CustomMenu.swift
//  Talk
//
//  Created by hamed on 6/29/24.
//

import Foundation
import UIKit

public class CustomMenu: UIStackView {
    public weak var contexMenuContainer: ContextMenuContainerView?

    public init() {
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configureView() {
        axis = .vertical
        spacing = 0
        alignment = .fill
        distribution = .fillEqually
        layer.cornerRadius = 8
        layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func addItem(_ item: ActionMenuItem) {
        addArrangedSubview(item)
        item.contextMenuContainer = contexMenuContainer
    }

    public func addItems(_ children: [ActionMenuItem] ) {
        for child in children {
            addArrangedSubview(child)
        }
    }

    public func removeLastSeparator() {
        (subviews.last as? ActionMenuItem)?.removeSeparator()
    }

    public func height() -> CGFloat {
        CGFloat(arrangedSubviews.count) * ActionMenuItem.height
    }
}
