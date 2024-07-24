//
//  MuteChannelBarView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import Chat

public final class MuteChannelBarView: UIView {
    weak var viewModel: ThreadViewModel?
    private let btn = UIButton(type: .system)

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.font = UIFont.fSubheadline
        btn.accessibilityIdentifier = "btnMuteChannelBarView"
        btn.setTitleColor(Color.App.accentUIColor, for: .normal)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(muteTapped)))

        addSubview(btn)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 72),
            btn.heightAnchor.constraint(equalToConstant: 48),
            btn.topAnchor.constraint(equalTo: topAnchor),
            btn.leadingAnchor.constraint(equalTo: leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        set()
    }

    public func set() {
        setIsHidden(!(viewModel?.sendContainerViewModel.canShowMuteChannelBar() == true))
        let isMute = viewModel?.thread.mute == true
        let title = isMute ? "Thread.unmute".bundleLocalized() : "Thread.mute".bundleLocalized()
        btn.setTitle(title, for: .normal)
    }

    @objc private func muteTapped(_ sender: UIButton) {
        guard let viewModel = viewModel else { return }
        viewModel.threadsViewModel?.toggleMute(viewModel.thread)
    }
}
