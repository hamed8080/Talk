//
//  PaddingUIImageView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 5/27/21.
//

import UIKit

public final class PaddingUIImageView: UIView {
    private let imageView = UIImageView()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!

    public init() {
        super.init(frame: .zero)
        configureView()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        leadingConstraint = imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        trailingConstraint = imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        topConstraint = imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        bottomConstraint = imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            topConstraint,
            bottomConstraint,
        ])
    }

    public func set(image: UIImage, inset: UIEdgeInsets? = nil) {
        imageView.image = image
        if let inset = inset {
            setInset(inset: inset)
        }
    }
    
    public func setInset(inset: UIEdgeInsets = .zero) {
        leadingConstraint.constant = inset.left
        trailingConstraint.constant = -inset.right
        topConstraint.constant = inset.top
        bottomConstraint.constant = -inset.bottom
    }
}
