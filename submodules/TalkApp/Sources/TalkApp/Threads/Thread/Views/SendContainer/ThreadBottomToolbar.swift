//
//  ThreadBottomToolbar.swift
//  Talk
//
//  Created by hamed on 3/24/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkUI
import Combine
import TalkModels

public class ThreadBottomToolbar: UIView {
    private weak var viewModel: ThreadViewModel?
    private let vStack = UIStackView()
    private let emojiKeyboardView = UIEmojiKeyboardView()
    
    /// In Vertical Stack
    private let mainSendButtons: MainSendButtons
    private let audioRecordingContainerView: AudioRecordingContainerView
    private let pickerButtons: PickerButtonsView
    private let attachmentFilesTableView: AttachmentFilesTableView
    private let replyPrivatelyPlaceholderView: ReplyPrivatelyMessagePlaceholderView
    private let replyPlaceholderView: ReplyMessagePlaceholderView
    private let forwardPlaceholderView: ForwardMessagePlaceholderView
    private let editMessagePlaceholderView: EditMessagePlaceholderView
    private let mentionTableView: MentionTableView
    public let selectionView: SelectionView
    private let muteBarView: MuteChannelBarView
    private let closedBarView: ClosedBarView
    public var onUpdateHeight: (@Sendable (CGFloat) -> Void)?
    
    /// Constraints
    private var emojiHeightConstraint: NSLayoutConstraint?
    private var cancellableSet: Set<AnyCancellable> = Set()
    
    /// Computed properties
    private var sendVM: SendContainerViewModel? { viewModel?.sendContainerViewModel }
    
    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        self.mainSendButtons = MainSendButtons(viewModel: viewModel)
        self.audioRecordingContainerView = AudioRecordingContainerView(viewModel: viewModel)
        self.pickerButtons = PickerButtonsView(viewModel: viewModel?.sendContainerViewModel, threadVM: viewModel)
        self.attachmentFilesTableView = AttachmentFilesTableView(viewModel: viewModel)
        self.replyPlaceholderView = ReplyMessagePlaceholderView(viewModel: viewModel)
        self.replyPrivatelyPlaceholderView = ReplyPrivatelyMessagePlaceholderView(viewModel: viewModel)
        self.forwardPlaceholderView = ForwardMessagePlaceholderView(viewModel: viewModel)
        self.editMessagePlaceholderView = EditMessagePlaceholderView(viewModel: viewModel)
        self.selectionView = SelectionView(viewModel: viewModel)
        self.muteBarView = MuteChannelBarView(viewModel: viewModel)
        self.closedBarView = ClosedBarView(viewModel: viewModel)
        self.mentionTableView = MentionTableView(viewModel: viewModel)
        super.init(frame: .zero)
        
        configureViews()
        registerOnEmojiKeyboard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        var effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.layer.masksToBounds = true
        effectView.layer.cornerRadius = 0
        effectView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        effectView.accessibilityIdentifier = "ThreadViewControllerBottomUIVisualEffect"

        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.alignment = .fill
        vStack.spacing = 0
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        editMessagePlaceholderView.superViewStack = vStack
        editMessagePlaceholderView.registerObservers()
        
        addSubview(vStack)
        addSubview(emojiKeyboardView)
        addSubview(effectView)
        bringSubviewToFront(emojiKeyboardView)
        bringSubviewToFront(vStack)
        
        emojiKeyboardView.onEmojiSelect = { [weak self] newValue in
            self?.viewModel?.sendContainerViewModel.appendEmoji(newValue)
        }
        let emojiHeightConstraint = emojiKeyboardView.heightAnchor.constraint(equalToConstant: 0)
        self.emojiHeightConstraint = emojiHeightConstraint
        
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor),
            vStack.bottomAnchor.constraint(equalTo: emojiKeyboardView.topAnchor),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            emojiHeightConstraint,
            emojiKeyboardView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            emojiKeyboardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emojiKeyboardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        bringSubviewToFront(vStack)
        bringSubviewToFront(emojiKeyboardView)
        
        // addArrangedSubview(replyPrivatelyPlaceholderView)
        attachmentFilesTableView.stack = vStack
        forwardPlaceholderView.stack = vStack
        forwardPlaceholderView.set() // Show forward placeholder on open the thread
        replyPrivatelyPlaceholderView.stack = vStack
        replyPrivatelyPlaceholderView.set()
        if viewModel?.thread.closed == true {
            vStack.addArrangedSubview(closedBarView)
        } else if viewModel?.sendContainerViewModel.canShowMuteChannelBar() == true {
            vStack.addArrangedSubview(muteBarView)
        } else {
            vStack.addArrangedSubview(mainSendButtons)
        }
    }
    
    public func showMainButtons(_ show: Bool, withRemoveAnimaiton: Bool = true) {
        if !show {
            removeMainSendButtonWithAnimation(withRemoveAnimation: withRemoveAnimaiton)
        } else if mainSendButtons.superview == nil {
            if show, viewModel?.sendContainerViewModel.canShowMuteChannelBar() == true {
                animateToShowChannelMuteBar()
            } else {
                animateToShowMainSendButton()
            }
        }
    }

    public func showPickerButtons(_ show: Bool) {
        showPicker(show: show)
        viewModel?.scrollVM.disableExcessiveLoading()
    }

    public func showSelectionBar(_ show: Bool) {
        selectionView.show(show: show, stack: vStack)
    }

    public func updateSelectionBar() {
        selectionView.update(stack: vStack)
    }

    public func updateMentionList() {
        mentionTableView.updateMentionList(stack: vStack)
    }

    private func showPicker(show: Bool) {
        pickerButtons.show(show, stack: vStack)
    }

    public func updateHeightWithDelay() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                onUpdateHeight?(frame.height)
            }
        }
    }
    
    public func openReplyMode(_ message: HistoryMessageType?) {
        replyPlaceholderView.set(stack: vStack)
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
        showMainButtons(!show, withRemoveAnimaiton: false)
        audioRecordingContainerView.show(show, stack: vStack) // Reset to show RecordingView again
    }

    public func onConversationClosed() {
        for view in vStack.arrangedSubviews {
            view.removeFromSuperview()
        }
        vStack.addArrangedSubview(closedBarView)
        closedBarView.closed()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateHeightWithDelay()
    }

    public func muteChanged() {
        muteBarView.set()
    }
    
    private func animateToShowChannelMuteBar() {
        UIView.animate(withDuration: 0.2) {
            self.mainSendButtons.removeFromSuperview()
            self.muteBarView.set()
        }
    }
    
    private func animateToShowMainSendButton() {
        mainSendButtons.alpha = 0.0
        vStack.insertArrangedSubview(mainSendButtons, at: 0)
        UIView.animate(withDuration: 0.2) {
            self.mainSendButtons.alpha = 1.0
        }
    }
    
    private func removeMainSendButtonWithAnimation(withRemoveAnimation: Bool) {
        // withRemoveAnimation prevents having two views in the stack and leads to a really tall view and a bad animation.
        mainSendButtons.removeFromSuperViewWithAnimation(withAimation: withRemoveAnimation)
        mainSendButtons.removeFromSuperview()
    }
}

extension ThreadBottomToolbar {
    private func registerOnEmojiKeyboard() {
        sendVM?.$showEmojiKeybaord.sink { [weak self] newValue in
            self?.showEmojiKeyboard(show: newValue)
        }
        .store(in: &cancellableSet)
    }
    
    private func showEmojiKeyboard(show: Bool) {
        if show {
            viewModel?.delegate?.setTapGesture(enable: false)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            emojiKeyboardView.initSections()
        }
        emojiHeightConstraint?.constant = show ? ConstantSizes.emojiKeyboardHeight : 0
        let vc = viewModel?.delegate?.viewController as? ThreadViewController
        vc?.contentInsetManager.updateContentInset(methodName: "showEmojiKeyboard")
        
        let opt: UIView.AnimationOptions = [.curveEaseInOut, .preferredFramesPerSecond60, .allowAnimatedContent]
        UIView.animate(withDuration: 0.15, delay: 0.0, options: opt) { [weak self] in
            guard let self = self else { return }
 
            layoutIfNeeded()
            vc?.view.layoutIfNeeded()
        }
    }
}
