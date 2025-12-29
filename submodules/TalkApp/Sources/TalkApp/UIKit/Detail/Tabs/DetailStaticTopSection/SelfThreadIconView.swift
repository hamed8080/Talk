//
//  SelfThreadIconView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/29/25.
//

import UIKit

class SelfThreadIconView: UIView {
    /// Views
    private var imageView = UIImageView()
    
    /// Models
    private let imageSize: CGFloat
    private let iconSize: CGFloat
    
    init(imageSize: CGFloat, iconSize: CGFloat) {
        self.imageSize = imageSize
        self.iconSize = iconSize
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "bookmark")
        
        
        let startColor = UIColor(red: 255/255, green: 145/255, blue: 98/255, alpha: 1.0)
        let endColor = UIColor(red: 255/255, green: 90/255, blue: 113/255, alpha: 1.0)
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(gradientLayer)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: imageSize),
            widthAnchor.constraint(equalToConstant: imageSize),
            
            imageView.heightAnchor.constraint(equalToConstant: iconSize),
            imageView.widthAnchor.constraint(equalToConstant: iconSize),
        ])
    }
}
