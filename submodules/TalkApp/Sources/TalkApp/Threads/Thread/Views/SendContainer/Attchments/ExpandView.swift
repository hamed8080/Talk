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
import TalkUI

public class ExpandView: UIView {
    private let fileCountLabel = UILabel()
    private let expandButton = UIImageButton(imagePadding: .init(all: 8))
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
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let btnClear = UIButton(type: .system)
        btnClear.translatesAutoresizingMaskIntoConstraints = false
        btnClear.setTitle("General.cancel".bundleLocalized(), for: .normal)
        btnClear.titleLabel?.font = UIFont.fCaption
        btnClear.setTitleColor(Color.App.redUIColor, for: .normal)
        btnClear.accessibilityIdentifier = "btnClearExpandView"
        btnClear.setContentHuggingPriority(.required, for: .horizontal)
        btnClear.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        fileCountLabel.font = UIFont.fCaption
        fileCountLabel.translatesAutoresizingMaskIntoConstraints = false
        fileCountLabel.accessibilityIdentifier = "fileCountLabelClearExpandView"
        fileCountLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.imageView.tintColor = Color.App.iconSecondaryUIColor
        expandButton.imageView.contentMode = .scaleAspectFit
        expandButton.setContentHuggingPriority(.required, for: .horizontal)
        expandButton.accessibilityIdentifier = "expandButtonClearExpandView"
        expandButton.action = { [weak self] in
            self?.viewModel?.attachmentsViewModel.toggleExpandMode()
        }

        addSubview(expandButton)
        addSubview(btnClear)
        addSubview(fileCountLabel)

        NSLayoutConstraint.activate([
            expandButton.widthAnchor.constraint(equalToConstant: 36),
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
        let localized = "Thread.sendAttachments".bundleLocalized()
        let count = viewModel?.attachmentsViewModel.attachments.count ?? 0
        let value = count.localNumber(locale: Language.preferredLocale) ?? ""
        fileCountLabel.text = String(format: localized, "\(value)")
        expandButton.imageView.image = UIImage(systemName: viewModel?.attachmentsViewModel.isExpanded  == true ? "chevron.down" : "chevron.up")
    }
}
