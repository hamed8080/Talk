//
//  DetailViewButtonItem.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/30/25.
//

import UIKit
import TalkUI

public class DetailViewButtonItem: UIView {
    private let imageView = PaddingUIImageView()
    public var onTap:(() -> Void)?
    
    public init (asssetImageName: String, inset: UIEdgeInsets = .init(all: 10)) {
        super.init(frame: .zero)
        configureView()
        setImage(image: UIImage(named: asssetImageName) ?? .init())
        imageView.setInset(inset: inset)
    }
    
    public init (systemName: String, inset: UIEdgeInsets = .init(all: 10)) {
        super.init(frame: .zero)
        configureView()
        setImage(image: UIImage(systemName: systemName) ?? .init())
        imageView.setInset(inset: inset)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(gesture)
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 48),
            heightAnchor.constraint(equalToConstant: 48),
            
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalToConstant: 48),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    public func setImage(image: UIImage) {
        imageView.set(image: image)
    }
    
    @objc private func tapped() {
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
