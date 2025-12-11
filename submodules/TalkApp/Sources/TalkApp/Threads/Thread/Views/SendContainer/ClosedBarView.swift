//
//  ClosedBarView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import Chat
public final class ClosedBarView: UIView {
    weak var viewModel: ThreadViewModel?
    private let lblCloesd = UILabel()
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
        // Configure lblCloesd
        lblCloesd.font = UIFont.normal(.subheadline)
        lblCloesd.accessibilityIdentifier = "lblClosedBarView"
        lblCloesd.textColor = Color.App.textSecondaryUIColor
        lblCloesd.text = "Thread.groupCloesdByAdmin".bundleLocalized()

        // Configure btn
        btn.titleLabel?.font = UIFont.bold(.body)
        btn.accessibilityIdentifier = "btnClosedBarView"
        btn.setTitleColor(Color.App.accentUIColor, for: .normal)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(btnTapped)))
        btn.setTitle("Genreal.deleteConversation".bundleLocalized(), for: .normal)

        // Configure stackView
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        stackView.spacing = 8 // Space between lblCloesd and btn
        stackView.addArrangedSubview(lblCloesd)
        stackView.addArrangedSubview(btn)

        // Add stackView to the view
        addSubview(stackView)

        // Center stackView horizontally and vertically in the parent view
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        set()
    }

    public func set() {
        let isClosed = viewModel?.thread.closed == true
        setIsHidden(!isClosed)
    }

    public func closed() {
        setIsHidden(false)
    }

    @objc private func btnTapped(_ sender: UIButton) {
        guard let thread = viewModel?.thread else { return }
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(LeaveThreadDialog(conversation: thread))
    }
}
