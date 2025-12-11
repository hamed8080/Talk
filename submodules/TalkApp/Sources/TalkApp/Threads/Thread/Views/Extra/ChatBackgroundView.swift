//
//  ChatBackgroundView.swift
//  Talk
//
//  Created by hamed on 7/7/24.
//

import UIKit
import TalkViewModels
import SwiftUI
import TalkUI

@MainActor
class ChatBackgroundView: UIView {
    private let imageView = UIImageView()
    private let gradinetLayer = CAGradientLayer()

    private let lightColors = [
        UIColor(red: 220.0/255.0, green: 194.0/255.0, blue: 178.0/255.0, alpha: 0.5).cgColor,
        UIColor(red: 234.0/255.0, green: 173.0/255.0, blue: 120.0/255.0, alpha: 0.7).cgColor,
        UIColor(red: 216.0/255.0, green: 125.0/255.0, blue: 78.0/255.0, alpha: 0.9).cgColor
    ]

    private let darkColors = [
        UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0).cgColor
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configure() {
        backgroundColor = UIColor(named: "bg_chat_color")
        let isDarkModeEnabled = AppSettingsModel.restore().isDarkModeEnabled ?? (traitCollection.userInterfaceStyle == .dark)
        
        imageView.image = UIImage(named: "chat_bg")
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = isDarkModeEnabled ? UIColor.white.withAlphaComponent(0.8) : .black
        
        gradinetLayer.colors = isDarkModeEnabled ? darkColors : lightColors
        gradinetLayer.startPoint = .init(x: 0, y: 0)
        gradinetLayer.endPoint = .init(x: 0, y: 1)
        layer.addSublayer(gradinetLayer)
        addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradinetLayer.frame = bounds
        imageView.frame = bounds
    }
}
