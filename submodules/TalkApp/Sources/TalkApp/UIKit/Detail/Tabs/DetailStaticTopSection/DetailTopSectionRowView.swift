//
//  DetailTopSectionRowView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/28/25.
//

import UIKit
import SwiftUI

public class DetailTopSectionRowView: UIView {
    /// Views
    private var keyLabel: UILabel = UILabel(frame: .zero)
    private var valueLabel: UILabel = UILabel(frame: .zero)
    
    /// Models
    let key: String
    let value: String
    public var lineLimit: Int? = nil
    public var onTap: (() -> Void)?
    
    public init(key: String, value: String, onTap: (() -> Void)? = nil) {
        self.key = key
        self.onTap = onTap
        self.value = value
        super.init(frame: .zero)
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.text = key.bundleLocalized()
        keyLabel.font = UIFont.normal(.caption)
        keyLabel.textColor = Color.App.textSecondaryUIColor
        keyLabel.textAlignment = Language.isRTL ? .right : .left
        addSubview(keyLabel)
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.normal(.body)
        valueLabel.textColor = Color.App.textPrimaryUIColor
        valueLabel.numberOfLines = lineLimit ?? 0
        valueLabel.textAlignment = Language.isRTL ? .right : .left
        addSubview(valueLabel)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        addGestureRecognizer(gesture)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            
            keyLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            keyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            valueLabel.topAnchor.constraint(equalTo: keyLabel.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }
    
    public func setKey(_ key: String) {
        keyLabel.text = key
    }
    
    public func setValue(_ value: String) {
        valueLabel.text = value
    }
    
    @objc private func onTapped() {
        onTap?()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.5
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
}
