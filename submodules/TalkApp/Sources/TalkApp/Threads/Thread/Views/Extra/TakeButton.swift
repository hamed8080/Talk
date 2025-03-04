//
//  TakeButton.swift
//  Talk
//
//  Created by hamed on 4/2/24.
//

import Foundation
import UIKit

public final class TakeButton: UIView {
    private let width: CGFloat = 52
    private let innerWidth: CGFloat = 46
    private let innerCircle = UIView()
    public var action: (() -> Void)?

    public init() {
        super.init(frame: .zero)
        configureView()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        layer.masksToBounds = true
        layer.cornerRadius = width / 2
        isUserInteractionEnabled = true
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(longPressGesture)
        addGestureRecognizer(tapGesture)

        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.isUserInteractionEnabled = false
        innerCircle.layer.backgroundColor = UIColor.white.cgColor
        innerCircle.layer.cornerRadius = innerWidth / 2
        innerCircle.layer.masksToBounds = true
        innerCircle.accessibilityIdentifier = "innerCircleTakeButton"
        addSubview(innerCircle)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: width),
            innerCircle.widthAnchor.constraint(equalToConstant: innerWidth),
            innerCircle.heightAnchor.constraint(equalToConstant: innerWidth),
            innerCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc private func onTapped(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.1) {
            self.innerCircle.layer.backgroundColor = UIColor.white.withAlphaComponent(0.4).cgColor
            self.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        } completion: { _ in
            self.innerCircle.layer.backgroundColor = UIColor.white.cgColor
            self.layer.borderColor = UIColor.white.cgColor
        }
        action?()
    }

    @objc func onLongPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            UIView.animate(withDuration: 0.1) {
                self.innerCircle.layer.backgroundColor = UIColor.white.withAlphaComponent(0.4).cgColor
                self.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
            }
        } else if gesture.state == .ended || gesture.state == .cancelled {
            UIView.animate(withDuration: 0.1) {
                self.innerCircle.layer.backgroundColor = UIColor.white.cgColor
                self.layer.borderColor = UIColor.white.cgColor
            }
        }
    }
}
