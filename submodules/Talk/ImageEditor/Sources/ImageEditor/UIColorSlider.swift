//
//  UIColorSlider.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 11/3/25.
//

import UIKit

class UIColorSlider: UIView {
    var onColorChanged: ((UIColor) -> Void)?
    
    private let slider = UISlider()
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1.0
        
        // Setup gradient showing full hue spectrum
        gradientLayer.colors = stride(from: 0, through: 1, by: 0.1).map {
            UIColor(hue: $0, saturation: 1, brightness: 1, alpha: 1).cgColor
        }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.cornerRadius = 8
        layer.insertSublayer(gradientLayer, at: 0)
        
        // Setup vertical slider
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.isContinuous = true
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.thumbTintColor = .white
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        // Rotate slider vertically (-90°)
        slider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        
        // Smaller thumb image
        let thumbSize: CGFloat = 14
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: thumbSize, height: thumbSize))
        let thumbImage = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: thumbSize, height: thumbSize)
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: rect)
            UIColor.lightGray.setStroke()
            ctx.cgContext.setLineWidth(1)
            ctx.cgContext.strokeEllipse(in: rect.insetBy(dx: 0.5, dy: 0.5))
        }
        slider.setThumbImage(thumbImage, for: .normal)
        slider.setThumbImage(thumbImage, for: .highlighted)
        
        addSubview(slider)
        
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),
            slider.widthAnchor.constraint(equalTo: heightAnchor),  // flipped because of rotation
            slider.heightAnchor.constraint(equalTo: widthAnchor)
        ])
        
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    @objc private func sliderChanged(_ sender: UISlider) {
        let hue = CGFloat(sender.value)
        let color = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
        onColorChanged?(color)
    }
}
