//
//  CircularSymbolButton.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/26/25.
//

import UIKit

class CircularSymbolButton: UIView {

    private let width: CGFloat
    private let height: CGFloat
    private let blurView: UIVisualEffectView
    private let iconImageView: UIImageView
    var onTap: (() -> Void)?

    init(
        _ systemName: String, width: CGFloat = 48, height: CGFloat = 48,
        radius: CGFloat = 24, addBGEffect: Bool = true
    ) {
        self.width = width
        self.height = height
        // SF Symbol Configuration
        let config = UIImage.SymbolConfiguration(paletteColors: [.white])
        let image = UIImage(systemName: systemName, withConfiguration: config)

        // Blur effect setup
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true

        // Image view setup
        iconImageView = UIImageView(image: image)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white

        super.init(frame: .zero)

        addSubview(blurView)
        addSubview(iconImageView)

        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: width).isActive = true
        heightAnchor.constraint(equalToConstant: height).isActive = true

        // Layer styling
        layer.cornerRadius = radius
        clipsToBounds = true

        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(onTapped))
        addGestureRecognizer(tapGesture)

        // Constraints

        if addBGEffect {
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        } else {
            blurView.removeFromSuperview()
        }
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
        ])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        iconImageView.alpha = 0.6
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        iconImageView.alpha = 1.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapped() {
        onTap?()
        iconImageView.alpha = 1.0
    }
}
