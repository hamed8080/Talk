//
//  PaddingUILabel.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 5/27/21.
//

import UIKit

public class PaddingUILabel: UIView {
    public let label = UILabel()
    private let horizontal: CGFloat
    private let vertical: CGFloat

    public init(frame: CGRect, horizontal: CGFloat, vertical: CGFloat) {
        self.horizontal = horizontal
        self.vertical = vertical
        super.init(frame: frame)
        setupView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: vertical / 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(vertical / 2)),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontal / 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(horizontal / 2)),
        ])
    }
}
