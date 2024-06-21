//
//  TopThreadToolbar.swift
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

public final class TopThreadToolbar: UIStackView {
    private let navBarView: CustomConversationNavigationBar
    private var pinMessageView: ThreadPinMessageView?
    private var navigationPlayerView: ThreadNavigationPlayer?
    private weak var viewModel: ThreadViewModel?

    init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        self.navBarView = .init(viewModel: viewModel)
        if let viewModel = viewModel {
            self.pinMessageView = .init(viewModel: viewModel.threadPinMessageViewModel)
            self.navigationPlayerView = ThreadNavigationPlayer(viewModel: viewModel)
        }
        super.init(frame: .zero)
        configureViews()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 0

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(effectView)

        NSLayoutConstraint.activate([
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor, constant: -100),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        configureNavBarView()
        configurePinMessageView()
        configurePlayerView()
    }

    private func configureNavBarView() {
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(navBarView)
        NSLayoutConstraint.activate([
            navBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            navBarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),           
        ])
    }

    private func configurePinMessageView() {
        if let pinMessageView = pinMessageView {
            addArrangedSubview(pinMessageView)
        }
    }

    private func configurePlayerView() {
        if let navigationPlayerView = navigationPlayerView {
            addArrangedSubview(navigationPlayerView)
        }
    }

    public func updateTitleTo(_ title: String?) {
        navBarView.updateTitleTo(title)
    }

    public func updateSubtitleTo(_ subtitle: String?) {
        navBarView.updateSubtitleTo(subtitle)
    }

    public func updateImageTo(_ image: UIImage?) {
        navBarView.updateImageTo(image)
    }
}
