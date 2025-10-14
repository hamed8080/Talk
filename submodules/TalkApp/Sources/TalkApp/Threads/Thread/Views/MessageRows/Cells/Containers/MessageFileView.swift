//
//  MessageRowAudioDownloaderView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

final class MessageFileView: UIStackView {
    // Views
    private let vStack = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.textPrimaryUIColor,
                                                      bgColor: Color.App.accentUIColor,
                                                      margin: 2
    )

    // Models
    private weak var viewModel: MessageRowViewModel?
    private var message: HistoryMessageType? { viewModel?.message }

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        layoutMargins = .init(top: ConstantSizes.messageFileViewStackLayoutMarginSize, left: ConstantSizes.messageFileViewStackLayoutMarginSize, bottom: 0, right: 0)
        isLayoutMarginsRelativeArrangement = true
        axis = .horizontal
        alignment = .top
        spacing = ConstantSizes.messageFileViewStackSpacing
        backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        isOpaque = true

        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        progressButton.isUserInteractionEnabled = true
        progressButton.accessibilityIdentifier = "progressButtonMessageFileView"
        progressButton.isOpaque = true
        addArrangedSubview(progressButton)

        let typeSizeHStack = UIStackView()
        typeSizeHStack.translatesAutoresizingMaskIntoConstraints = false
        typeSizeHStack.axis = .horizontal
        typeSizeHStack.spacing = 4
        typeSizeHStack.accessibilityIdentifier = "typeSizeHStackMessageFileView"
        typeSizeHStack.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        typeSizeHStack.isOpaque = true

        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.font = UIFont.fBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor
        fileTypeLabel.accessibilityIdentifier = "fileTypeLabelMessageFileView"
        fileTypeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileTypeLabel.isOpaque = true
        typeSizeHStack.addArrangedSubview(fileTypeLabel)

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.fBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageFileView"
        fileSizeLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileSizeLabel.isOpaque = true
        typeSizeHStack.addArrangedSubview(fileSizeLabel)

        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 4
        vStack.accessibilityIdentifier = "vStackMessageFileView"
        vStack.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        vStack.isOpaque = true

        fileNameLabel.font = UIFont.fBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.accessibilityIdentifier = "fileNameLabelMessageFileView"
        fileNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fileNameLabel.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        fileNameLabel.isOpaque = true

        vStack.addArrangedSubview(fileNameLabel)
        vStack.addArrangedSubview(typeSizeHStack)
        addArrangedSubview(vStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ConstantSizes.messageFileViewHeight),
            progressButton.widthAnchor.constraint(equalToConstant: ConstantSizes.messageFileViewProgressButtonSize),
            progressButton.heightAnchor.constraint(equalToConstant: ConstantSizes.messageFileViewProgressButtonSize),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        setSemanticContent(viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight)
        updateProgress(viewModel: viewModel)
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileTypeLabel.text = viewModel.calMessage.extName
    }

    @objc private func onTap() {
        viewModel?.onTap(sourceView: progressButton)
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isFile { return }
        let progress = viewModel.fileState.progress
        let downloadIcon = viewModel.fileState.iconState
        let isUploading = viewModel.fileState.isUploading || viewModel.message is UploadFileMessage
        let icon = isUploading ? "arrow.up" : downloadIcon
        progressButton.animate(to: progress, systemIconName: icon)
        progressButton.setProgressVisibility(visible: canShowProgress)
        progressButton.showRotation(show: canShowProgress)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isFile { return }
        updateProgress(viewModel: viewModel)
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isFile { return }
        updateProgress(viewModel: viewModel)
    }

    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }
}
