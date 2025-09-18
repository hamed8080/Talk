//
//  ReplyInfoView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import Additive
import TalkModels

final class ReplyInfoView: UIView {
    // Views
    private let participantLabel = UILabel()
    private let imageIconView = UIImageView(frame: .zero)
    private let deletedLabel = UILabel()
    private let replyLabel = UILabel()
    private let bar = UIView()

    // Models
    private weak var viewModel: MessageRowViewModel?
    private var imageIconViewLeadingConstriant: NSLayoutConstraint!
    /*
     These two texts are used to localize,
     and bundle which are costly to reconstruct every time.
     */
    private static let deletedStaticText = "Messages.deletedMessageReply".bundleLocalized()
    private static let repliedToStaticText = "Message.replyTo".bundleLocalized()

    // Sizes
    private static let margin: CGFloat = 6
    private static let imageSize: CGFloat = 36
    private static let barWidth: CGFloat = 2.5
    private static let barMargin: CGFloat = 0.5

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        isOpaque = true
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onReplyTapped))
        addGestureRecognizer(tap)

        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.contentMode = .scaleAspectFit
        imageIconView.accessibilityIdentifier = "imageIconViewReplyInfoView"
        imageIconView.setContentHuggingPriority(.required, for: .horizontal)
        imageIconView.layer.cornerRadius = 4
        imageIconView.layer.masksToBounds = true
        addSubview(imageIconView)

        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.font = UIFont.fCaption3
        replyLabel.numberOfLines = 1
        replyLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        replyLabel.lineBreakMode = .byTruncatingTail
        replyLabel.textAlignment = isMe ? .right : .left
        replyLabel.accessibilityIdentifier = "replyLabelReplyInfoView"
        replyLabel.setContentHuggingPriority(.required, for: .vertical)
        replyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        replyLabel.backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        replyLabel.isOpaque = true
        addSubview(replyLabel)

        deletedLabel.translatesAutoresizingMaskIntoConstraints = false
        deletedLabel.text = ReplyInfoView.deletedStaticText
        deletedLabel.font = UIFont.fBoldCaption2
        deletedLabel.textColor = Color.App.textSecondaryUIColor
        deletedLabel.textAlignment = isMe ? .right : .left
        deletedLabel.setIsHidden(true)
        deletedLabel.accessibilityIdentifier = "deletedLabelReplyInfoView"
        deletedLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        deletedLabel.backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        deletedLabel.isOpaque = true
        addSubview(deletedLabel)

        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.font = UIFont.fBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor
        participantLabel.accessibilityIdentifier = "participantLabelReplyInfoView"
        participantLabel.textAlignment = isMe ? .right : .left
        participantLabel.backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        participantLabel.isOpaque = true
        addSubview(participantLabel)

        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true
        bar.accessibilityIdentifier = "barReplyInfoView"
        addSubview(bar)

        imageIconViewLeadingConstriant = imageIconView.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: ReplyInfoView.margin)
        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: ReplyInfoView.barWidth),
            bar.topAnchor.constraint(equalTo: topAnchor, constant: ReplyInfoView.margin),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ReplyInfoView.margin),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ReplyInfoView.barMargin),

            imageIconViewLeadingConstriant,
            imageIconView.topAnchor.constraint(equalTo: topAnchor, constant: ReplyInfoView.margin),
            imageIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ReplyInfoView.margin),
            imageIconView.widthAnchor.constraint(equalToConstant: ReplyInfoView.imageSize),
            imageIconView.heightAnchor.constraint(equalToConstant: ReplyInfoView.imageSize),

            participantLabel.topAnchor.constraint(equalTo: topAnchor, constant: ReplyInfoView.margin),
            participantLabel.leadingAnchor.constraint(equalTo: imageIconView.trailingAnchor, constant: ReplyInfoView.margin),
            participantLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ReplyInfoView.margin),

            deletedLabel.topAnchor.constraint(equalTo: topAnchor, constant: ReplyInfoView.margin),
            deletedLabel.leadingAnchor.constraint(equalTo: participantLabel.leadingAnchor),
            deletedLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ReplyInfoView.margin),

            replyLabel.topAnchor.constraint(equalTo: participantLabel.bottomAnchor, constant: ReplyInfoView.margin),
            replyLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ReplyInfoView.margin),
            replyLabel.leadingAnchor.constraint(equalTo: participantLabel.leadingAnchor),
            replyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ReplyInfoView.margin)
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        participantLabel.text = "\(ReplyInfoView.repliedToStaticText)  \(replyInfo?.participant?.name ?? "")"
        participantLabel.setIsHidden(replyInfo?.participant?.name == nil)
        replyLabel.text = replyInfo?.message
        
        /// Override reply file name over reply message text, file name has a higher priority
        if viewModel.calMessage.replyFileName != nil {
            replyLabel.text = viewModel.calMessage.replyFileName
        }
        replyLabel.setIsHidden(replyInfo?.message?.isEmpty == true && viewModel.calMessage.replyFileName == nil)

        deletedLabel.setIsHidden(replyInfo?.deleted == nil || replyInfo?.deleted == false)
        setImageView(viewModel: viewModel)
    }

    func setImageView(viewModel: MessageRowViewModel) {
        let hasImage = viewModel.calMessage.isReplyImage
        if hasImage {
            setReplyImage()
        }
        imageIconView.setIsHidden(!hasImage)
        imageIconViewLeadingConstriant.constant = hasImage ? ReplyInfoView.margin : -ReplyInfoView.imageSize
    }

    @objc func onReplyTapped(_ sender: UIGestureRecognizer) {
        if viewModel?.message.replyInfo?.deleted == true { return }
        let task: Task<Void, any Error> = Task { [weak self] in
            guard let self = self else { return }
            if isReplyPrivately {
                moveToReplyPrivately()
            } else {
                await moveToReply()
            }
        }
        historyVM?.setTask(task)
    }

    private func moveToReply() async {
        await historyVM?.moveToTime(replyTime, replyId, highlight: true)
    }

    private func moveToReplyPrivately() {
        Task {
            try await AppState.shared.openThreadAndMoveToMessage(
                conversationId: sourceConversationId,
                messageId: replyId,
                messageTime: replyTime
            )
        }
    }

    private var historyVM: ThreadHistoryViewModel? { viewModel?.threadVM?.historyVM }

    private var replyTime: UInt {
        replyInfo?.repliedToMessageTime ?? 0
    }

    private var replyId: Int {
        replyInfo?.repliedToMessageId ?? -1
    }

    private var isReplyPrivately: Bool {
        replyInfo?.replyPrivatelyInfo != nil
    }

    private var replyInfo: ReplyInfo? {
        viewModel?.message.replyInfo
    }

    private var sourceConversationId: Int {
        replyInfo?.replyPrivatelyInfo?.threadId ?? -1
    }
    
    /// Get reply image from the disk or get thumbnail from the server,
    /// and then store it into fileState
    private func setReplyImage() {
        Task { [weak self] in
            guard let self = self else { return }
            let image = await viewModel?.getReplyImage()
            await MainActor.run { [weak self] in
                /// Set imageView
                self?.imageIconView.image = image
            }
        }
    }
}
