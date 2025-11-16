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

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ConstantSizes.messageForwardInfoViewStackCornerRadius
        layer.masksToBounds = true
        backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        semanticContentAttribute = Language.isRTL || isMe ? .forceRightToLeft : .forceLeftToRight

        forwardStaticLabel.translatesAutoresizingMaskIntoConstraints = false
        forwardStaticLabel.font = UIFont.normal(.caption3)
        forwardStaticLabel.textColor = Color.App.accentUIColor
        forwardStaticLabel.text = ForwardInfoView.forwardFromStaticText
        forwardStaticLabel.accessibilityIdentifier = "forwardStaticLebelForwardInfoView"
        forwardStaticLabel.textAlignment = Language.isRTL || isMe ? .right : .left
        addSubview(forwardStaticLabel)

        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.font = UIFont.bold(.caption2)
        participantLabel.textColor = Color.App.accentUIColor
        participantLabel.numberOfLines = 1
        participantLabel.accessibilityIdentifier = "participantLabelForwardInfoView"
        participantLabel.textAlignment = Language.isRTL || isMe ? .right : .left
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
        bar.layer.cornerRadius = ConstantSizes.messageForwardInfoViewBarWidth / 2
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
            heightAnchor.constraint(equalToConstant: ConstantSizes.messageForwardInfoViewHeight),
            
            bar.widthAnchor.constraint(equalToConstant: ConstantSizes.messageForwardInfoViewBarWidth),
            bar.topAnchor.constraint(equalTo: topAnchor, constant: ConstantSizes.messageForwardInfoViewMargin),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ConstantSizes.messageForwardInfoViewMargin),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ConstantSizes.messageForwardInfoViewBarMargin),

            forwardStaticLabel.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: ConstantSizes.messageForwardInfoViewMargin),
            forwardStaticLabel.topAnchor.constraint(equalTo: topAnchor, constant: ConstantSizes.messageForwardInfoViewMargin),
            forwardStaticLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ConstantSizes.messageForwardInfoViewMargin),

            participantLabel.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: ConstantSizes.messageForwardInfoViewMargin),
            participantLabel.topAnchor.constraint(equalTo: forwardStaticLabel.bottomAnchor, constant: ConstantSizes.messageForwardInfoViewVerticalSpacing),
            participantLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ConstantSizes.messageForwardInfoViewMargin),
            participantLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ConstantSizes.messageForwardInfoViewMargin)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if touches.first?.view == participantLabel {
            setDimColor(dim: true)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if touches.first?.view == participantLabel {
            setDimColor(dim: false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if touches.first?.view == participantLabel {
            setDimColor(dim: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if touches.first?.view == participantLabel {
            setDimColor(dim: false)
        }
    }
    
    private func setDimColor(dim: Bool) {
        participantLabel.textColor = Color.App.accentUIColor?.withAlphaComponent(dim ? 0.5 : 1.0)
    }

    @objc private func onTappedParticpant(_ sender: UIGestureRecognizer) {
        let isMe = viewModel?.message.forwardInfo?.participant?.id == AppState.shared.user?.id
        if let participant = viewModel?.message.forwardInfo?.participant, !isMe {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                Task { [weak self] in
                    try await AppState.shared.objectsContainer.navVM.openThread(participant: participant)
                }
            }
        }
    }
}
