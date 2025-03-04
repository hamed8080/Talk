//
//  ForwardInfoView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

final class ForwardInfoView: UIView {
    // Views
    private let forwardStaticLabel = UILabel()
    private let participantLabel = UILabel()
    private let bar = UIView()

    // Models
    private weak var viewModel: MessageRowViewModel?
    private static let forwardFromStaticText = "Message.forwardedFrom".bundleLocalized()

    // Sizes
    private let margin: CGFloat = 6
    private let imageSize: CGFloat = 36
    private let barWidth: CGFloat = 2.5
    private let barMargin: CGFloat = 0.5
    private let verticalSpacing: CGFloat = 2.0

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 6
        layer.masksToBounds = true
        backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight

        forwardStaticLabel.translatesAutoresizingMaskIntoConstraints = false
        forwardStaticLabel.font = UIFont.fCaption3
        forwardStaticLabel.textColor = Color.App.accentUIColor
        forwardStaticLabel.text = ForwardInfoView.forwardFromStaticText
        forwardStaticLabel.accessibilityIdentifier = "forwardStaticLebelForwardInfoView"
        forwardStaticLabel.textAlignment = isMe ? .right : .left
        addSubview(forwardStaticLabel)

        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.font = UIFont.fBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor
        participantLabel.numberOfLines = 1
        participantLabel.accessibilityIdentifier = "participantLabelForwardInfoView"
        participantLabel.textAlignment = isMe ? .right : .left
        participantLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        participantLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        participantLabel.layer.cornerRadius = 6
        participantLabel.layer.masksToBounds = true
        participantLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTappedParticpant))
        participantLabel.addGestureRecognizer(tapGesture)
        addSubview(participantLabel)

        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = barWidth / 2
        bar.layer.masksToBounds = true
        bar.accessibilityIdentifier = "barForwardInfoView"
        bar.setContentHuggingPriority(.required, for: .horizontal)
        bar.setContentCompressionResistancePriority(.required, for: .horizontal)
        bar.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        addSubview(bar)

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onForwardTapped))
        addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: barWidth),
            bar.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: barMargin),

            forwardStaticLabel.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: margin),
            forwardStaticLabel.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            forwardStaticLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),

            participantLabel.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: margin),
            participantLabel.topAnchor.constraint(equalTo: forwardStaticLabel.bottomAnchor, constant: verticalSpacing),
            participantLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            participantLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin)
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        setIsHidden(false)

        let fi = viewModel.message.forwardInfo
        let title = fi?.participant?.name ?? fi?.conversation?.title
        participantLabel.text = title
        participantLabel.setIsHidden(title == nil)
    }

    @objc private func onForwardTapped(_ sender: UIGestureRecognizer) {
#if DEBUG
        print("on forward tapped")
#endif
    }

    @objc private func onTappedParticpant(_ sender: UIGestureRecognizer) {
        let isMe = viewModel?.message.forwardInfo?.participant?.id == AppState.shared.user?.id
        if let participant = viewModel?.message.forwardInfo?.participant, !isMe {
            participantLabel.backgroundColor = Color.App.textPlaceholderUIColor?.withAlphaComponent(0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                AppState.shared.openThread(participant: participant)
                self.participantLabel.backgroundColor = .clear
            }
        }
    }
}
