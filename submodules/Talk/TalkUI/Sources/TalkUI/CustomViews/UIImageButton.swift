//
//  UIImageButton.swift
//  TalkUI
//
//  Created by hamed on 10/22/22.
//

import UIKit

public final class UIImageButton: UIView {
    public let imageView = UIImageView()
    public var action: (() -> Void)?

    public init(imagePadding: UIEdgeInsets = .init(all: 8)) {
        super.init(frame: .zero)
        configureView(imagePadding: imagePadding)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(imagePadding: UIEdgeInsets) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.accessibilityIdentifier = "imageViewUIImageButton"
        addSubview(imageView)

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: imagePadding.left),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -imagePadding.right),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: imagePadding.top),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -imagePadding.bottom),
        ])
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.layer.opacity = 0.4
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.layer.opacity = 1.0
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.layer.opacity = 1.0
        }
    }

    @objc private func onTapped(_ sender: UITapGestureRecognizer) {
        action?()
    }
}
