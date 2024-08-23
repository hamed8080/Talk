//
//  CircleProgressButton.swift
//
//
//  Created by hamed on 1/3/24.
//

import Foundation
import UIKit
import SwiftUI

public final class CircleProgressButton: UIButton {
    private var progressColor: UIColor?
    private var bgColor: UIColor?
    private var shapeLayer = CAShapeLayer()
    private let imgCenter = UIImageView()
    private var iconTint: UIColor?
    private var lineWidth: CGFloat
    private var animation = CABasicAnimation(keyPath: "strokeEnd")
    private let margin: CGFloat
    private var systemImageName: String = ""
    private static let font = UIFont.systemFont(ofSize: 8, weight: .bold)
    private static let config = UIImage.SymbolConfiguration(font: font)

    public init(progressColor: UIColor? = .darkText,
                iconTint: UIColor? = Color.App.textPrimaryUIColor,
                bgColor: UIColor? = .white.withAlphaComponent(0.3),
                lineWidth: CGFloat = 3,
                iconSize: CGSize = .init(width: 16, height: 16),
                margin: CGFloat = 6
    ) {
        self.lineWidth = lineWidth
        self.margin = margin
        super.init(frame: .zero)
        self.bgColor = bgColor
        self.progressColor = progressColor
        self.iconTint = iconTint
        configureView(iconSize: iconSize)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(iconSize: CGSize) {
        imgCenter.translatesAutoresizingMaskIntoConstraints = false
        imgCenter.contentMode = .scaleAspectFit
        imgCenter.tintColor = iconTint
        imgCenter.accessibilityIdentifier = "imgCenterCircleProgressButton"
        addSubview(imgCenter)
        layer.backgroundColor = bgColor?.cgColor
        NSLayoutConstraint.activate([
            imgCenter.centerXAnchor.constraint(equalTo: centerXAnchor),
            imgCenter.centerYAnchor.constraint(equalTo: centerYAnchor),
            imgCenter.widthAnchor.constraint(equalToConstant: iconSize.width),
            imgCenter.heightAnchor.constraint(equalToConstant: iconSize.height),
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        drawProgress()
    }

    private func drawProgress() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center,
                                radius: (bounds.width / 2) - margin,
                                startAngle: -CGFloat.pi / 2,
                                endAngle: 2 * CGFloat.pi,
                                clockwise: true)

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = progressColor?.cgColor
        shapeLayer.path = path.cgPath
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = lineWidth
        layer.addSublayer(shapeLayer)
    }

    public func animate(to progress: CGFloat, systemIconName: String = "") {
        if systemIconName != systemImageName {
            self.systemImageName = systemIconName
            UIView.transition(with: imgCenter, duration: 0.2, options: .transitionCrossDissolve) {
                self.imgCenter.image = UIImage(systemName: systemIconName, withConfiguration: CircleProgressButton.config)
            }
        }
        animation.toValue = progress
        animation.duration = 0.3
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        shapeLayer.strokeEnd = progress
        shapeLayer.add(animation, forKey: "strokeEndAnimation")
    }

    public func setProgressVisibility(visible: Bool) {
        shapeLayer.isHidden = !visible
    }
}
