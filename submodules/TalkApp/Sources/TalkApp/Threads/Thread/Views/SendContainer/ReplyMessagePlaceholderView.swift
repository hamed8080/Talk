//
//  ReplyMessagePlaceholderView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels
import Chat

public final class ReplyMessagePlaceholderView: UIStackView {
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private var replyImage = UIImageButton(imagePadding: .init(all: 4))
    private weak var viewModel: ThreadViewModel?
    
    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }
    
    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 2)
        isLayoutMarginsRelativeArrangement = true
        alignment = .center
        
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .leading
        vStack.accessibilityIdentifier = "vStackReplyMessagePlaceholderView"
        
        nameLabel.font = UIFont.fBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1
        nameLabel.accessibilityIdentifier = "nameLabelReplyMessagePlaceholderView"
        
        messageLabel.font = UIFont.fCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2
        messageLabel.accessibilityIdentifier = "messageLabelReplyMessagePlaceholderView"
        messageLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnMessage))
        messageLabel.addGestureRecognizer(tapGesture)
        messageLabel.textAlignment = Language.isRTL ? .right : .left
        
        replyImage.translatesAutoresizingMaskIntoConstraints = false
        replyImage.imageView.contentMode = .scaleAspectFit
        replyImage.accessibilityIdentifier = "replyImageReplyMessagePlaceholderView"
        
        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(messageLabel)
        
        let staticImageReply = UIImageButton(imagePadding: .init(all: 4))
        staticImageReply.translatesAutoresizingMaskIntoConstraints = false
        staticImageReply.imageView.image = UIImage(systemName: "arrow.turn.up.left")
        staticImageReply.imageView.tintColor = Color.App.accentUIColor
        staticImageReply.imageView.contentMode = .scaleAspectFit
        staticImageReply.accessibilityIdentifier = "staticReplyImageReplyMessagePlaceholderView"
        
        let closeButton = CloseButtonView()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.accessibilityIdentifier = "closeButtonReplyMessagePlaceholderView"
        closeButton.action = { [weak self] in
            self?.close()
        }
        
        addArrangedSubview(staticImageReply)
        addArrangedSubview(replyImage)
        addArrangedSubview(vStack)
        addArrangedSubview(closeButton)
        
        NSLayoutConstraint.activate([
            staticImageReply.widthAnchor.constraint(equalToConstant: 28),
            staticImageReply.heightAnchor.constraint(equalToConstant: 28),
            replyImage.widthAnchor.constraint(equalToConstant: 42),
            replyImage.heightAnchor.constraint(equalToConstant: 42),
            closeButton.widthAnchor.constraint(equalToConstant: 42),
            closeButton.heightAnchor.constraint(equalToConstant: 42),
        ])
    }
    
    public func set(stack: UIStackView) {
        let replyMessage = viewModel?.replyMessage
        let showReply = replyMessage != nil
        alpha = showReply ? 0.0 : 1.0
        if showReply {
            stack.insertArrangedSubview(self, at: 0)
        }
        UIView.animate(withDuration: 0.2) {
            self.alpha = showReply ? 1.0 : 0.0
            self.setIsHidden(!showReply)
        } completion: { completed in
            if completed, !showReply {
                self.removeFromSuperview()
            }
        }
        
        nameLabel.text = replyMessage?.participant?.name
        nameLabel.setIsHidden(replyMessage?.participant?.name == nil)
        
        replyImage.imageView.image = nil // clear out the old image
        if imageLink(replyMessage), let replyMessage = replyMessage {
            replyImage.isHidden = false
            setImage(replyMessage)
        } else {
            replyImage.isHidden = true
        }
        
        Task {
            let message = replyMessage?.fileMetaData?.name ?? replyMessage?.message ?? ""
            await MainActor.run {
                messageLabel.text = message
            }
        }
    }
    
    private func close() {
        viewModel?.scrollVM.disableExcessiveLoading()
        viewModel?.replyMessage = nil
        viewModel?.selectedMessagesViewModel.clearSelection()
        viewModel?.delegate?.openReplyMode(nil) // close the UI
    }
    
    private func imageLink(_ replyMessage: Message?) -> Bool {
        guard let type = replyMessage?.type else { return false }
        return [ChatModels.MessageType.picture, .podSpacePicture].contains(type)
    }
    
    private func setImage(_ replyMessage: Message) {
        Task {
            guard let url = await replyMessage.url else { return }
            let req = ImageRequest(hashCode: replyMessage.fileHashCode, quality: 0.5, size: .SMALL, thumbnail: true)
            guard let data = await ThumbnailDownloadManagerViewModel().downloadThumbnail(req: req, url: url) else { return }
            await MainActor.run { [weak self] in
                self?.replyImage.imageView.image = UIImage(data: data)
            }
        }
    }
    
    @objc private func tappedOnMessage() {
        guard
            let time = viewModel?.replyMessage?.time,
            let id = viewModel?.replyMessage?.id
        else { return }
        Task { [weak self] in
            await self?.viewModel?.historyVM.moveToTime(time, id)
        }
    }
}
