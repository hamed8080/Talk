//
//  CircularUIButton.swift
//  TalkUI
//
//  Created by hamed on 10/22/22.
//

import UIKit
import SwiftUI

public final class CircularUIButton: UIImageView {
    public var action: (() -> Void)?
    private var bgColor: UIColor!

    public init() {
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layer.masksToBounds = true
        contentMode = .scaleAspectFit
    }

    public func setup(image: UIImage,
                      bgColor: UIColor = Color.App.bgPrimaryUIColor!,
                      forgroundColor: UIColor = Color.App.accentUIColor!,
                      action: (() -> Void)? = nil) {
        self.action = action
        self.bgColor = bgColor
        self.image = image
        self.layer.backgroundColor = bgColor.cgColor
        self.tintColor = forgroundColor
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        addGestureRecognizer(tapGesture)
    }

    @objc private func onTapped(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            layer.backgroundColor = sender.state == .began ? bgColor?.withAlphaComponent(0.5).cgColor : bgColor.cgColor
        }
        action?()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2.0
    }
}
