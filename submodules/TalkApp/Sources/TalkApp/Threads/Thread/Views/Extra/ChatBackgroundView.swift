//
//  ChatBackgroundView.swift
//  Talk
//
//  Created by hamed on 7/7/24.
//

import UIKit
import TalkViewModels

@MainActor
class ChatBackgroundView: UIImageView {
    private let gradinetLayer = CAGradientLayer()

    private let lightColors = [
        UIColor(red: 220/255, green: 194/255, blue: 178/255, alpha: 0.5).cgColor,
        UIColor(red: 234/255, green: 173/255, blue: 120/255, alpha: 0.7).cgColor,
        UIColor(red: 216/255, green: 125/255, blue: 78/255, alpha: 0.9).cgColor
    ]

    private let darkColors = [
        UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0).cgColor
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configure() {
        image = UIImage(named: "chat_bg")
        contentMode = .scaleAspectFill

        let isDarkModeEnabled = AppSettingsModel.restore().isDarkModeEnabled ?? (traitCollection.userInterfaceStyle == .dark)
        if isDarkModeEnabled {
            tintColor = UIColor.gray
            backgroundColor = UIColor.black.withAlphaComponent(0.35)
        }
            
        gradinetLayer.colors = isDarkModeEnabled ? darkColors : lightColors
        gradinetLayer.startPoint = .init(x: 0, y: 0)
        gradinetLayer.endPoint = .init(x: 0, y: 1)
        layer.addSublayer(gradinetLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradinetLayer.frame = bounds
    }
}
