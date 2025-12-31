//
//  ThreadDetailTopToolbar.swift
//  Talk
//
//  Created by hamed on 3/25/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkUI
import SwiftUI
import Combine
import ChatModels

public final class ThreadDetailTopToolbar: UIStackView {
    private let overBlurEffectColorView = UIView()
    private let navBarView: CustomThreadDetailNavigationBar
    private weak var viewModel: ThreadDetailViewModel?

    init(viewModel: ThreadDetailViewModel?) {
        self.viewModel = viewModel
        navBarView = .init(viewModel: viewModel)
        super.init(frame: .zero)
        configureViews()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 0
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        configureBlurBackgroundView()
        configureNavBarView()
    }

    private func configureBlurBackgroundView() {
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityIdentifier = "effectViewTopThreadToolbar"
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)
        
        overBlurEffectColorView.translatesAutoresizingMaskIntoConstraints = false
        overBlurEffectColorView.accessibilityIdentifier = "overBlurEffectColorViewTopThreadToolbarView"
        overBlurEffectColorView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.clear : Color.App.accentUIColor
        addSubview(overBlurEffectColorView)
        
        NSLayoutConstraint.activate([
            overBlurEffectColorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overBlurEffectColorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overBlurEffectColorView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            overBlurEffectColorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func configureNavBarView() {
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        navBarView.accessibilityIdentifier = "navBarViewTopThreadToolbar"
        addArrangedSubview(navBarView)
        NSLayoutConstraint.activate([
            navBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            navBarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),           
        ])
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        overBlurEffectColorView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.clear : Color.App.accentUIColor
    }
}
