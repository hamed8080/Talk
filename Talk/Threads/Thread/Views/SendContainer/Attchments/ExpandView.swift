//
//  ExpandView.swift
//  Talk
//
//  Created by hamed on 6/17/24.
//

import Foundation
import UIKit
import TalkViewModels
import SwiftUI
import TalkModels

public class ExpandView: UIView {
    private let fileCountLabel = UILabel()
    private let expandButton = UIImageView()
    weak var viewModel: ThreadViewModel?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        let btnClear = UIButton(type: .system)
        btnClear.translatesAutoresizingMaskIntoConstraints = false
        btnClear.setTitle("General.cancel".localized(), for: .normal)
        btnClear.titleLabel?.font = UIFont.uiiransansCaption
        btnClear.setTitleColor(Color.App.redUIColor, for: .normal)
        btnClear.accessibilityIdentifier = "btnClearExpandView"
        btnClear.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        fileCountLabel.font = UIFont.uiiransansCaption
        fileCountLabel.translatesAutoresizingMaskIntoConstraints = false
        fileCountLabel.accessibilityIdentifier = "fileCountLabelClearExpandView"

        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.tintColor = Color.App.iconSecondaryUIColor
        expandButton.contentMode = .scaleAspectFit
        expandButton.accessibilityIdentifier = "expandButtonClearExpandView"

        addSubview(expandButton)
        addSubview(btnClear)
        addSubview(fileCountLabel)

        NSLayoutConstraint.activate([
            expandButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            expandButton.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            expandButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            btnClear.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            btnClear.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            btnClear.trailingAnchor.constraint(equalTo: expandButton.leadingAnchor, constant: -8),
            fileCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            fileCountLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            fileCountLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
        ])
    }


    @objc private func clearTapped(_ sender: UIButton) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)) {
            viewModel?.attachmentsViewModel.clear()
        }
    }

    public func set() {
        let localized = String(localized: .init("Thread.sendAttachments"))
        let count = viewModel?.attachmentsViewModel.attachments.count ?? 0
        let value = count.localNumber(locale: Language.preferredLocale) ?? ""
        fileCountLabel.text = String(format: localized, "\(value)")
        expandButton.image = UIImage(systemName: viewModel?.attachmentsViewModel.isExpanded  == true ? "chevron.down" : "chevron.up")
    }
}
