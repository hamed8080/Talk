//
//  SectionHeaderView.swift
//  Talk
//
//  Created by hamed on 3/14/24.
//

import Foundation
import TalkViewModels
import UIKit
import SwiftUI
import TalkUI

final class SectionHeaderView: UITableViewHeaderFooterView {
    private var label = PaddingUILabel(frame: .zero, horizontal: 32, vertical: 8)
    public weak var delegate: ThreadViewDelegate?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear

        label.translatesAutoresizingMaskIntoConstraints = false
        label.label.font = UIFont.fBoldCaption
        label.label.textColor = .white
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.label.textAlignment = .center
        label.backgroundColor = .black.withAlphaComponent(0.4)
        label.accessibilityIdentifier = "labelSectionHeaderView"

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped(_:)))
        addGestureRecognizer(tapGesture)
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ section: MessageSection) {
        self.label.label.text = section.sectionText
    }

    @objc private func onTapped(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        delegate?.openMoveToDatePicker()
    }
}
