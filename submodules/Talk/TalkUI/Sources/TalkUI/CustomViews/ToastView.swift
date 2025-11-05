//
//  ToastView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 7/26/25.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels

public final class ToastUIView: UIStackView {
    private let label = UILabel()
    private let hStack = UIStackView()
    private let messageLabel = UILabel()
    private let sandboxLabel = UILabel()
    
    private let title: String?
    private let titleColor: UIColor
    private let message: String
    private let titleFont: UIFont
    private let messageFont: UIFont
    private let messageColor: UIColor
    private let showSandBox: Bool
    private let leadingView: UIView?
    private let disableWidthConstraint: Bool
    private let onSwipeDown: (() -> Void)?
    private var isSwipingDownAnimation = false
    
    public init(title: String? = nil,
                titleColor: UIColor = Color.App.textPrimaryUIColor!,
                message: String,
                messageColor: UIColor = Color.App.textPrimaryUIColor!,
                titleFont: UIFont = .fBoldSubheadline!,
                messageFont: UIFont = .fBody!,
                showSandBox: Bool = false,
                leadingView: UIView? = nil,
                disableWidthConstraint: Bool = false,
                onSwipeDown: (() -> Void )? = nil
    )
    {
        self.title = title
        self.titleColor = titleColor
        self.message = message
        self.leadingView = leadingView
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.messageColor = messageColor
        self.showSandBox = showSandBox
        self.disableWidthConstraint = disableWidthConstraint
        self.onSwipeDown = onSwipeDown
        super.init(frame: .zero)
        configureView()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        alignment = .leading
        spacing = 0
        layoutMargins = .init(all: 16)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 8
        layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effetcView = UIVisualEffectView(effect: blurEffect)
        effetcView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effetcView)
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(oneSwipeGesture))
        swipeDownGesture.direction = .down
        effetcView.isUserInteractionEnabled = true
        effetcView.addGestureRecognizer(swipeDownGesture)
        
        if let leadingView = leadingView {
            addArrangedSubview(leadingView)
        }

        label.text = title
        label.isHidden = title == nil
        label.font = titleFont
        label.textColor = titleColor
        label.textAlignment = Language.isRTL ? .right : .left
        label.isUserInteractionEnabled = false
        addArrangedSubview(label)

        hStack.spacing = 8
        hStack.axis = .horizontal
        hStack.alignment = .leading
        hStack.isUserInteractionEnabled = false

        if let leadingView = leadingView {
            hStack.addArrangedSubview(leadingView)
        }

        messageLabel.textColor = messageColor
        messageLabel.font = messageFont
        messageLabel.text = message.bundleLocalized()
        messageLabel.numberOfLines = 5
        messageLabel.textAlignment = Language.isRTL ? .right : .left
        messageLabel.isUserInteractionEnabled = false
        hStack.addArrangedSubview(messageLabel)
        addArrangedSubview(hStack)
        
        sandboxLabel.textColor = Color.App.accentUIColor
        sandboxLabel.font = UIFont.fBody
        sandboxLabel.text = "SANDBOX"
        sandboxLabel.textAlignment = Language.isRTL ? .right : .left
        sandboxLabel.isUserInteractionEnabled = false
        addSubview(sandboxLabel)

        NSLayoutConstraint.activate([
            effetcView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effetcView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effetcView.topAnchor.constraint(equalTo: topAnchor),
            effetcView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            sandboxLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            sandboxLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])

        if !disableWidthConstraint {
            widthAnchor.constraint(lessThanOrEqualToConstant: 380).isActive = true
        }
        
        sandboxLabel.isHidden = !showSandBox
    }
    
    @objc private func oneSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        guard !isSwipingDownAnimation, gesture.direction == .down else { return }
        isSwipingDownAnimation = true
        
        UIView.animate(withDuration: 0.12, delay: 0.0) { [weak self] in
            guard let self = self else { return }
            self.frame.origin.y += self.frame.height
        } completion: { [weak self] completed in
            self?.onSwipeDown?()
            self?.isSwipingDownAnimation = false
        }
    }
}

public struct ToastViewWrapper: UIViewRepresentable {
    private let title: String?
    private let titleColor: UIColor
    private let message: String
    private let titleFont: UIFont
    private let messageFont: UIFont
    private let messageColor: UIColor
    private let showSandbox: Bool
    private let disableWidthConstraint: Bool
    private let leadingView: UIView?
    private let attachToVC: UIViewController?
    private var onSwipeDown: (() -> Void)?
    
    public init(title: String? = nil,
                titleColor: UIColor = Color.App.textPrimaryUIColor!,
                message: String,
                messageColor: UIColor = Color.App.textPrimaryUIColor!,
                titleFont: UIFont = .fBoldSubheadline!,
                messageFont: UIFont = .fBody!,
                showSandbox: Bool = false,
                leadingView: UIView? = nil,
                attachToVC: UIViewController? = nil,
                disableWidthConstraint: Bool = false,
                onSwipeDown: (() -> Void)? = nil
    )
    {
        self.title = title
        self.titleColor = titleColor
        self.message = message
        self.leadingView = leadingView
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.messageColor = messageColor
        self.showSandbox = showSandbox
        self.disableWidthConstraint = disableWidthConstraint
        self.attachToVC = attachToVC
        self.onSwipeDown = onSwipeDown
    }
    
    public func makeUIView(context: Context) -> some UIView {
        
        let container = UIView()
        let toastView = ToastUIView(title: title,
                             titleColor: titleColor,
                             message: message,
                             messageColor: messageColor,
                             titleFont: titleFont,
                             messageFont: messageFont,
                             showSandBox: showSandbox,
                             leadingView: leadingView,
                             onSwipeDown: onSwipeDown)
        toastView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(toastView)
        
        NSLayoutConstraint.activate([
            toastView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            toastView.heightAnchor.constraint(greaterThanOrEqualToConstant: 82),
            toastView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toastView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        ])
        
        attachToVC?.view.addSubview(container)
        
        return container
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastViewWrapper(message: "TEST")
    }
}
