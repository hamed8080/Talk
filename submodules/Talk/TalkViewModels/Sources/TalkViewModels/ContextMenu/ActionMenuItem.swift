//
//  ActionMenuItem.swift
//  Talk
//
//  Created by hamed on 6/30/24.
//

import Foundation
import UIKit
import TalkModels

public class ActionMenuItem: UIView {
    private let label = UILabel()
    private let imageView = UIImageView()
    private let separator = UIView()
    private let model: ActionItemModel
    private let action: () -> Void
    static let height: CGFloat = 42
    public weak var contextMenuContainer: ContextMenuContainerView?

    public init(model: ActionItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configureView() {
        backgroundColor = .clear

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = model.title
        label.textColor = model.color
        label.font = UIFont(name: "SVJBTlNhbnNY".fromBase64() ?? "", size: 16)
        addSubview(label)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: model.image ?? "")
        imageView.tintColor = model.color
        addSubview(imageView)

        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        addSubview(separator)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ActionMenuItem.height),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),

            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        if model.sandbox {
            let sandboxLabel = SandboxView()
            sandboxLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sandboxLabel)
            
            NSLayoutConstraint.activate([
                sandboxLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                sandboxLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                sandboxLabel.widthAnchor.constraint(equalToConstant: 96),
            ])
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        addGestureRecognizer(tapGesture)
    }

    func removeSeparator() {
        separator.removeFromSuperview()
    }

    @objc private func onTapped(_ sender: UIGestureRecognizer) {
        action()
        contextMenuContainer?.hide()
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.backgroundColor = .gray.withAlphaComponent(0.4)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.backgroundColor = .clear
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.backgroundColor = .clear
        }
    }
}

fileprivate class SandboxView: UILabel {
    
    public init() {
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configureView() {
        text = "SANDBOX"
        textColor = UIColor(named: "accent")
        font = UIFont.preferredFont(forTextStyle: .caption2)
    }
}

