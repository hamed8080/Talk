//
//  ToastView.swift
//  Talk
//
//  Created by hamed on 10/7/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

public struct ToastView<ContentView: View>: View {
    let title: String?
    let titleColor: Color
    let message: String
    let titleFont: Font
    let messageFont: Font
    let messageColor: Color
    let leadingView: () -> ContentView

    public init(title: String? = nil,
                titleColor: Color = Color.App.textPrimary,
                message: String,
                messageColor: Color = Color.App.red,
                titleFont: Font = .iransansBoldBody,
                messageFont: Font = .iransansCaption,
                @ViewBuilder leadingView: @escaping () -> ContentView)
    {
        self.title = title
        self.titleColor = titleColor
        self.message = message
        self.leadingView = leadingView
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.messageColor = messageColor
    }

    public var body: some View {
        GeometryReader { reader in
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    if let title = title {
                        Text(title)
                            .font(titleFont)
                            .foregroundStyle(titleColor)
                    }
                    HStack(spacing: 8) {
                        leadingView()
                        Text(message)
                            .font(messageFont)
                            .fontWeight(.light)
                            .foregroundStyle(messageColor)
                        Spacer()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(12)))
                .frame(maxWidth: 380)
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 96, trailing: 8))
        }
    }
}

public final class ToastUIView: UIStackView {
    private let label = UILabel()
    private let hStack = UIStackView()
    private let messageLabel = UILabel()
    private let title: String?
    private let titleColor: UIColor
    private let message: String
    private let titleFont: UIFont
    private let messageFont: UIFont
    private let messageColor: UIColor
    private let leadingView: UIView?

    public init(title: String? = nil,
                titleColor: UIColor = Color.App.textPrimaryUIColor!,
                message: String,
                messageColor: UIColor = Color.App.redUIColor!,
                titleFont: UIFont = .uiiransansBoldBody!,
                messageFont: UIFont = .uiiransansCaption!,
                leadingView: UIView? = nil)
    {
        self.title = title
        self.titleColor = titleColor
        self.message = message
        self.leadingView = leadingView
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.messageColor = messageColor
        super.init(frame: .zero)
        configureView()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false

        alignment = .leading
        spacing = 0
        layoutMargins = .init(all: 8)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 8
        layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effetcView = UIVisualEffectView(effect: blurEffect)
        effetcView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effetcView)

        label.text = title
        label.isHidden = title == nil
        label.font = titleFont
        label.textColor = titleColor
        addArrangedSubview(label)

        hStack.spacing = 8
        hStack.axis = .horizontal
        hStack.alignment = .leading

        if let leadingView = leadingView {
            hStack.addArrangedSubview(leadingView)
        }

        messageLabel.textColor = messageColor
        messageLabel.font = messageFont
        messageLabel.text = String(localized: .init(message))
        hStack.addArrangedSubview(messageLabel)

        addArrangedSubview(hStack)

        NSLayoutConstraint.activate([
            effetcView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effetcView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effetcView.topAnchor.constraint(equalTo: topAnchor),
            effetcView.bottomAnchor.constraint(equalTo: bottomAnchor),
            widthAnchor.constraint(lessThanOrEqualToConstant: 380),
        ])
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(message: "TEST") {}
    }
}
