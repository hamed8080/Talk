//
//  TabDetailsTextView.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import UIKit
import TalkViewModels
import SwiftUI

final class TabDetailsTextView: UIView {

    // MARK: - UI

    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.normal(.body)
        label.textColor = Color.App.textPrimaryUIColor
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.textAlignment = Language.isRTL ? .right : .left
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.normal(.caption2)
        label.textColor = Color.App.textSecondaryUIColor
        return label
    }()

    private let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.normal(.caption3)
        label.textColor = Color.App.textSecondaryUIColor
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var bottomStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [timeLabel, UIView(), fileSizeLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [fileNameLabel, bottomStack])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            bottomStack.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(with rowModel: TabRowModel) {
        fileNameLabel.text = rowModel.fileName
        timeLabel.text = rowModel.time
        fileSizeLabel.text = rowModel.fileSizeString
    }
}
