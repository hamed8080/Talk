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

final class SectionHeaderView: UIView {
    private var label = PaddingUILabel(frame: .zero, horizontal: 32, vertical: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.uiiransansCaption
        label.textColor = .white
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.backgroundColor = .black.withAlphaComponent(0.4)
        label.accessibilityIdentifier = "labelSectionHeaderView"

        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ section: MessageSection) {
        self.label.text = section.sectionText
    }
}
