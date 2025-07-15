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
    private var progressLayerLine = CAShapeLayer()
    private let imgCenter = UIImageView()
    private let artworkShadowLayer = CALayer()
    private let artworkImageLayer = CALayer()
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
        layer.backgroundColor = bgColor?.cgColor
        
        /// Setup artwork layer.
        artworkImageLayer.contentsGravity = .resizeAspectFill
        artworkImageLayer.masksToBounds = true
        
        /// Setup shadow layer over artwork layer.
        artworkShadowLayer.opacity = 0.0
        artworkShadowLayer.backgroundColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        artworkImageLayer.addSublayer(artworkShadowLayer)
        layer.addSublayer(artworkImageLayer)
        
        /// Setup progress line layer.
        progressLayerLine.fillColor = UIColor.clear.cgColor
        progressLayerLine.strokeColor = progressColor?.cgColor
        progressLayerLine.lineCap = .round
        progressLayerLine.lineWidth = lineWidth
        layer.addSublayer(progressLayerLine)
    
        /// Setup centered image like(play/pause) icon.
        imgCenter.translatesAutoresizingMaskIntoConstraints = false
        imgCenter.contentMode = .scaleAspectFit
        imgCenter.tintColor = iconTint
        imgCenter.accessibilityIdentifier = "imgCenterCircleProgressButton"
        addSubview(imgCenter)
        bringSubviewToFront(imgCenter)
        
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
                
        artworkImageLayer.frame = bounds
        artworkImageLayer.cornerRadius = bounds.width / 2
        artworkShadowLayer.frame = bounds
        artworkShadowLayer.cornerRadius = bounds.width / 2
    
        drawProgress()
    }
    
    /// Draw line progress.
    /// This method should be called inside the layout subview to get correct bounds.
    private func drawProgress() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (bounds.width / 2) - margin
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + (2 * CGFloat.pi)
        
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        progressLayerLine.path = path.cgPath
    }
    
    /// Animate the progress line.
    /// - Parameters:
    ///   - progress: A value between 0...1
    ///   - systemIconName: Hide icon if it is not passed
    public func animate(to progress: CGFloat, systemIconName: String = "") {
        if systemIconName != systemImageName {
            self.systemImageName = systemIconName
            UIView.transition(with: imgCenter, duration: 0.2, options: .transitionCrossDissolve) {
                self.imgCenter.image = UIImage(systemName: systemIconName, withConfiguration: CircleProgressButton.config)
            }
        }
        
        progressLayerLine.removeAnimation(forKey: "strokeEndAnimation")

        let fromValue = progressLayerLine.presentation()?.strokeEnd ?? progressLayerLine.strokeEnd
        animation.fromValue = fromValue
        animation.toValue = min(max(progress, 0.0), 1.0) // clamp between 0 and 1
        animation.duration = 0.3
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        progressLayerLine.add(animation, forKey: "strokeEndAnimation")

        // Update model layer after animation starts
        progressLayerLine.strokeEnd = progress
    }
    
    public func displayLinkAnimateTo(progress: CGFloat) {
        progressLayerLine.removeAnimation(forKey: "strokeEndAnimation")
        progressLayerLine.strokeEnd = progress
    }

    public func setProgressVisibility(visible: Bool) {
        progressLayerLine.isHidden = !visible
    }
    
    public func setArtwork(_ image: UIImage?) {
        artworkImageLayer.contents = image?.cgImage
        artworkShadowLayer.opacity = image == nil ? 0.0 : 1.0
    }
}
