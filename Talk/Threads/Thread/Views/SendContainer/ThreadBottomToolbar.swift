//
//  ThreadBottomToolbar.swift
//  Talk
//
//  Created by hamed on 3/24/24.
//

import Foundation
import UIKit
import TalkViewModels
import Combine
import TalkUI
import TalkModels

public final class ThreadBottomToolbar: UIStackView {
    private weak var viewModel: ThreadViewModel?
    private let mainSendButtons: MainSendButtons
    private let audioRecordingView: AudioRecordingView
    private let pickerButtons: PickerButtonsView
    private let attachmentFilesTableView: AttachmentFilesTableView
    private let replyPrivatelyPlaceholderView: ReplyPrivatelyMessagePlaceholderView
    private let replyPlaceholderView: ReplyMessagePlaceholderView
    private let forwardPlaceholderView: ForwardMessagePlaceholderView
    private let editMessagePlaceholderView: EditMessagePlaceholderView
    private let mentionTableView: MentionTableView
    public let selectionView: SelectionView
    private let muteBarView: MuteChannelBarView
    public var onUpdateHeight: ((CGFloat) -> Void)?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        self.mainSendButtons = MainSendButtons(viewModel: viewModel)
        self.audioRecordingView = AudioRecordingView(viewModel: viewModel)
        self.pickerButtons = PickerButtonsView(viewModel: viewModel?.sendContainerViewModel, threadVM: viewModel)
        self.attachmentFilesTableView = AttachmentFilesTableView(viewModel: viewModel)
        self.replyPlaceholderView = ReplyMessagePlaceholderView(viewModel: viewModel)
        self.replyPrivatelyPlaceholderView = ReplyPrivatelyMessagePlaceholderView(viewModel: viewModel)
        self.forwardPlaceholderView = ForwardMessagePlaceholderView(viewModel: viewModel)
        self.editMessagePlaceholderView = EditMessagePlaceholderView(viewModel: viewModel)
        self.selectionView = SelectionView(viewModel: viewModel)
        self.muteBarView = MuteChannelBarView(viewModel: viewModel)
        self.mentionTableView = MentionTableView(viewModel: viewModel)
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        axis = .vertical
        alignment = .fill
        spacing = 0
        isLayoutMarginsRelativeArrangement = true

        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.layer.masksToBounds = true
        effectView.layer.cornerRadius = 0
        effectView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        effectView.accessibilityIdentifier = "effectViewThreadBottomToolbar"
        addSubview(effectView)

        // addArrangedSubview(replyPrivatelyPlaceholderView)
        attachmentFilesTableView.stack = self
        forwardPlaceholderView.stack = self
        forwardPlaceholderView.set() // Show forward placeholder on open the thread
        replyPrivatelyPlaceholderView.stack = self
        replyPrivatelyPlaceholderView.set()
        if viewModel?.sendContainerViewModel.canShowMuteChannelBar() == true {
            addArrangedSubview(muteBarView)
        } else {
            addArrangedSubview(mainSendButtons)
        }
        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func showMainButtons(_ show: Bool) {
        if !show {
            mainSendButtons.removeFromSuperViewWithAnimation()
        } else if mainSendButtons.superview == nil {
            mainSendButtons.alpha = 0.0
            insertArrangedSubview(mainSendButtons, at: 0)
            UIView.animate(withDuration: 0.2) {
                self.mainSendButtons.alpha = 1.0
            }
        }
    }

    public func showPickerButtons(_ show: Bool) {
        mainSendButtons.toggleAttchmentButton(show: show)
        showPicker(show: show)
    }

    public func showSendButton(_ show: Bool) {
        mainSendButtons.showSendButton(show)
    }

    public func showMicButton(_ show: Bool) {
        mainSendButtons.showMicButton(show)
    }

    public func showSelectionBar(_ show: Bool) {
        selectionView.show(show: show, stack: self)
    }

    public func updateSelectionBar() {
        selectionView.update(stack: self)
    }

    public func updateMentionList() {
        mentionTableView.updateMentionList(stack: self)
    }

    private func showPicker(show: Bool) {
        pickerButtons.show(show, stack: self)
    }

    public func updateHeightWithDelay() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            onUpdateHeight?(frame.height)
        }
    }

    public func openEditMode(_ message: (any HistoryMessageProtocol)?) {
        editMessagePlaceholderView.set(stack: self)
        viewModel?.sendContainerViewModel.setText(newValue: message?.message ?? "")
    }

    public func openReplyMode(_ message: (any HistoryMessageProtocol)?) {
        replyPlaceholderView.set(stack: self)
    }

    public func focusOnTextView(focus: Bool) {
        mainSendButtons.focusOnTextView(focus: focus)
    }

    public func showForwardPlaceholder(show: Bool) {
        forwardPlaceholderView.set()
    }

    public func showReplyPrivatelyPlaceholder(show: Bool) {
        replyPrivatelyPlaceholderView.set()
    }

    public func openRecording(_ show: Bool) {
        viewModel?.attachmentsViewModel.clear()
        showMainButtons(!show)
        audioRecordingView.show(show, stack: self) // Reset to show RecordingView again
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateHeightWithDelay()
    }
}
