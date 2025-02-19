//
//  MessageContainerStackView.swift
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
import TalkExtensions
import Photos

public final class MessageContainerStackView: UIStackView {
    // Views
    private let messageFileView: MessageFileView
    private let messageImageView: MessageImageView
    private let messageVideoView: MessageVideoView
    private let messageAudioView: MessageAudioView
    private let locationRowView: MessageLocationView
    private let groupParticipantNameView: GroupParticipantNameView
    private let replyInfoMessageRow: ReplyInfoView
    private let forwardMessageRow: ForwardInfoView
    private let singleEmojiView: SingleEmojiView
    private let textMessageView = TextMessageView()
    private static let tailImage = UIImage(named: "tail")
    private var tailImageView = UIImageView()
    private let footerView: FooterView
//    private let unsentMessageView = UnsentMessageView()

    // Models
    weak var viewModel: MessageRowViewModel?
    public weak var cell: MessageBaseCell?

    // Sizes
    private let tailWidth: CGFloat = 16
    private let tailHeight: CGFloat = 32
    private let margin: CGFloat = 4

    init(frame: CGRect, isMe: Bool) {
        self.groupParticipantNameView = .init(frame: frame)
        self.replyInfoMessageRow = .init(frame: frame, isMe: isMe)
        self.forwardMessageRow = .init(frame: frame, isMe: isMe)
        self.footerView = .init(frame: frame, isMe: isMe)
        self.messageFileView = .init(frame: frame, isMe: isMe)
        self.messageAudioView = .init(frame: frame, isMe: isMe)
        self.locationRowView = .init(frame: frame)
        self.messageImageView = .init(frame: frame)
        self.messageVideoView = .init(frame: frame, isMe: isMe)
        self.singleEmojiView = .init(frame: frame, isMe: isMe)
        super.init(frame: frame)
        configureView(isMe: isMe)

        addMenus()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView(isMe: Bool) {
        backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        axis = .vertical
        spacing = 4
        alignment = .top
        distribution = .fill
        layoutMargins = .init(all: margin)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 10
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        registerGestures()

        groupParticipantNameView.translatesAutoresizingMaskIntoConstraints = false
        replyInfoMessageRow.translatesAutoresizingMaskIntoConstraints = false
        forwardMessageRow.translatesAutoresizingMaskIntoConstraints = false
        messageFileView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageVideoView.translatesAutoresizingMaskIntoConstraints = false
        messageAudioView.translatesAutoresizingMaskIntoConstraints = false
        locationRowView.translatesAutoresizingMaskIntoConstraints = false
        singleEmojiView.translatesAutoresizingMaskIntoConstraints = false
        textMessageView.translatesAutoresizingMaskIntoConstraints = false
        textMessageView.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        footerView.translatesAutoresizingMaskIntoConstraints = false
//        unsentMessageView.translatesAutoresizingMaskIntoConstraints = false

        if !isMe {
            tailImageView = UIImageView(image: MessageContainerStackView.tailImage)
            tailImageView.translatesAutoresizingMaskIntoConstraints = false
            tailImageView.contentMode = .scaleAspectFit
            tailImageView.tintColor = Color.App.bgChatUserUIColor!
            addSubview(tailImageView)

            tailImageView.widthAnchor.constraint(equalToConstant: tailWidth).isActive = true
            tailImageView.heightAnchor.constraint(equalToConstant: tailHeight).isActive = true
            tailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -12).isActive = true
            tailImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        }
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        reattachOrDetach(viewModel: viewModel)
        isUserInteractionEnabled = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false
        if viewModel.calMessage.isLastMessageOfTheUser && !viewModel.calMessage.isMe && viewModel.threadVM?.thread.group == true {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            tailImageView.setIsHidden(false)
        } else {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            tailImageView.setIsHidden(true)
        }
    }

    private func reattachOrDetach(viewModel: MessageRowViewModel) {
        if viewModel.calMessage.isFirstMessageOfTheUser && !viewModel.calMessage.isMe {
            groupParticipantNameView.set(viewModel)
            addArrangedSubview(groupParticipantNameView)
        } else {
            groupParticipantNameView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isReply {
            replyInfoMessageRow.set(viewModel)
            addArrangedSubview(replyInfoMessageRow)
            replyInfoMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin).isActive = true
        } else {
            replyInfoMessageRow.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isForward {
            forwardMessageRow.set(viewModel)
            addArrangedSubview(forwardMessageRow)
            forwardMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin).isActive = true
        } else {
            forwardMessageRow.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isImage {
            messageImageView.set(viewModel)
            addArrangedSubview(messageImageView)
        } else {
            messageImageView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isMap {
            locationRowView.set(viewModel)
            addArrangedSubview(locationRowView)
        } else {
            locationRowView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isFile {
            messageFileView.set(viewModel)
            addArrangedSubview(messageFileView)
        } else {
            messageFileView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isAudio {
            messageAudioView.set(viewModel)
            addArrangedSubview(messageAudioView)
        } else {
            messageAudioView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isVideo {
            messageVideoView.set(viewModel)
            addArrangedSubview(messageVideoView)
            // This line should be called below addArrangedSubview to give the video view chance to get superView.
            messageVideoView.updateWidthConstarints()
        } else {
            messageVideoView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.hasText || viewModel.calMessage.rowType.isPublicLink {
            textMessageView.set(viewModel)
            addArrangedSubview(textMessageView)
        } else {
            textMessageView.removeFromSuperview()
        }
        
        if viewModel.calMessage.rowType.isSingleEmoji {
            textMessageView.removeFromSuperview()
            tailImageView.removeFromSuperview()
            singleEmojiView.set(viewModel)
            addArrangedSubview(singleEmojiView)
            let isSingleEmojiWithAttachment: Bool = !viewModel.calMessage.rowType.isBareSingleEmoji
            backgroundColor = isSingleEmojiWithAttachment ? (viewModel.calMessage.isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!) : nil
        } else {
            singleEmojiView.removeFromSuperview()
            backgroundColor = viewModel.calMessage.isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        }

        //        if viewModel.calMessage.rowType.isUnSent {
        //            unsentMessageView.set(viewModel)
        //            addArrangedSubview(unsentMessageView)
        //        } else {
        //            unsentMessageView.removeFromSuperview()
        //        }
        //

        footerView.set(viewModel)
        addArrangedSubview(footerView)
    }

    private func registerGestures() {
        replyInfoMessageRow.isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = true
    }
}

public struct ActionModel {
    let viewModel: MessageRowViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    var message: HistoryMessageType { viewModel.message }
}

// MARK: Upadate methods
extension MessageContainerStackView {
    func edited() {
        guard let viewModel = viewModel else { return }
        /// We have to call set because if row type changes we have to update the row view
        ///for example when two emoji converts to a single emoji
        set(viewModel)
        
        if viewModel.calMessage.rowType.hasText, textMessageView.superview == nil {
            footerView.removeFromSuperview()
            addArrangedSubview(textMessageView)
            addArrangedSubview(footerView)
        }
        UIView.animate(withDuration: 0.2) {
            self.textMessageView.setText(viewModel: viewModel)
            self.footerView.edited()
        }
    }

    func pinChanged() {
        guard let viewModel = viewModel else { return }
        footerView.pinChanged(isPin: viewModel.message.pinned == true)
    }

    func sent() {
        guard let viewModel = viewModel else { return }
        footerView.sent(image: viewModel.message.uiFooterStatus.image)
    }

    func delivered() {
        guard let viewModel = viewModel else { return }
        footerView.delivered(image: viewModel.message.uiFooterStatus.image)
    }

    func seen() {
        guard let viewModel = viewModel else { return }
        footerView.seen(image: viewModel.message.uiFooterStatus.image)
    }

    func updateProgress(viewModel: MessageRowViewModel) {
        messageAudioView.updateProgress(viewModel: viewModel)
        messageFileView.updateProgress(viewModel: viewModel)
        messageImageView.updateProgress(viewModel: viewModel)
        messageVideoView.updateProgress(viewModel: viewModel)
    }

    func updateThumbnail(viewModel: MessageRowViewModel) {
        messageImageView.updateThumbnail(viewModel: viewModel)
    }

    func updateReplyImageThumbnail(viewModel: MessageRowViewModel) {
        replyInfoMessageRow.setImageView(viewModel: viewModel)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        messageAudioView.downloadCompleted(viewModel: viewModel)
        messageFileView.downloadCompleted(viewModel: viewModel)
        messageImageView.downloadCompleted(viewModel: viewModel)
        messageVideoView.downloadCompleted(viewModel: viewModel)
        locationRowView.downloadCompleted(viewModel: viewModel)
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        messageAudioView.uploadCompleted(viewModel: viewModel)
        messageFileView.uploadCompleted(viewModel: viewModel)
        messageImageView.uploadCompleted(viewModel: viewModel)
        messageVideoView.uploadCompleted(viewModel: viewModel)
        footerView.set(viewModel)
    }

    public func reactionsUpdated(viewModel: MessageRowViewModel) {
        footerView.reactionsUpdated(viewModel: viewModel)        
    }
    
    public func reactionDeleted(_ reaction: Reaction) {
        footerView.reactionDeleted(reaction)
    }
    
    public func reactionAdded(_ reaction: Reaction) {
        footerView.reactionAdded(reaction)
    }
    
    public func reactionReplaced(_ reaction: Reaction) {
        footerView.reactionReplaced(reaction)
    }

    public func prepareForContextMenu(userInterfaceStyle: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = userInterfaceStyle
        let isMe = viewModel?.calMessage.isMe == true
        gestureRecognizers?.removeAll() // remove add menu gesture to prevent reopen the context menu while we are one.

        isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = false
        replyInfoMessageRow.isUserInteractionEnabled = false
        textMessageView.isUserInteractionEnabled = true
        textMessageView.forceEnableSelection = true
        tailImageView.isHidden = true
        textMessageView.isSelectable = true
        backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
    }
}
