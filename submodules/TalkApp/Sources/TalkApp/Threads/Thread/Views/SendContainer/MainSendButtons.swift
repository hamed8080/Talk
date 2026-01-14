//
//  MainSendButtons.swift
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
import UIKit
import Combine
import Lottie

public final class MainSendButtons: UIView {
    private let btnTrailing = UIImageButton(imagePadding: .init(all: 10))
    private let btnLeading = UIImageButton(imagePadding: .init(all: 8))
    private let multilineTextField = SendContainerTextView()
    private weak var threadVM: ThreadViewModel?
    private var viewModel: SendContainerViewModel { threadVM?.sendContainerViewModel ?? .init() }
    private var cancellableSet = Set<AnyCancellable>()
    private static let initSize: CGFloat = 48
    private static let buttonSize = initSize - 8
    private let animationView = LottieAnimationView(fileName: "talk_logo_animation.json", color: Color.App.whiteUIColor ?? .white)
    
    private var heightConstraint: NSLayoutConstraint?
    private var appState: AppState { AppState.shared }
    private var objc: ObjectsContainer { appState.objectsContainer }
    private var prop: NavigationProperties { objc.navVM.navigationProperties }

    public init(viewModel: ThreadViewModel?) {
        self.threadVM = viewModel
        super.init(frame: .zero)
        configureView()
        registerGestures()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        semanticContentAttribute = .forceLeftToRight
        
        btnTrailing.imageView.image = UIImage(systemName: "plus")
        btnTrailing.translatesAutoresizingMaskIntoConstraints = false
        btnTrailing.imageView.contentMode = .scaleAspectFit
        btnTrailing.tintColor = Color.App.whiteUIColor
        btnTrailing.layer.masksToBounds = true
        btnTrailing.layer.cornerRadius = MainSendButtons.buttonSize / 2
        btnTrailing.backgroundColor = Color.App.accentUIColor
        btnTrailing.imageView.backgroundColor = Color.App.accentUIColor
        btnTrailing.imageView.isOpaque = true
        btnTrailing.accessibilityIdentifier = "btnToggleAttachmentButtonsMainSendButtons"
        btnTrailing.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(btnTrailing)
        
        btnLeading.translatesAutoresizingMaskIntoConstraints = false
        btnLeading.imageView.contentMode = .scaleAspectFit
        btnLeading.tintColor = Color.App.whiteUIColor
        btnLeading.layer.masksToBounds = true
        btnLeading.layer.cornerRadius = MainSendButtons.buttonSize / 2
        btnLeading.imageView.isOpaque = true
        btnLeading.accessibilityIdentifier = "btnToggleAttachmentButtonsMainSendButtons"
        btnLeading.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(btnLeading)

        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.layer.masksToBounds = true
        hStack.layer.cornerRadius = MainSendButtons.initSize / 2
        hStack.backgroundColor = Color.App.bgSendInputUIColor
        hStack.isOpaque = true
        hStack.alignment = .bottom
        hStack.accessibilityIdentifier = "hStackMainSendButtons"
        hStack.layoutMargins = .init(top: -2, left: 8, bottom: 4, right: 8)//-4 to move textfield higher to make the cursor center in the textfield.
        hStack.isLayoutMarginsRelativeArrangement = true
        
        multilineTextField.translatesAutoresizingMaskIntoConstraints = false
        multilineTextField.accessibilityIdentifier = "multilineTextFieldMainSendButtons"
        multilineTextField.setContentHuggingPriority(.required, for: .horizontal)
        multilineTextField.setContentCompressionResistancePriority(.required, for: .horizontal)
        multilineTextField.threadVM = threadVM
        hStack.addArrangedSubview(multilineTextField)
        addSubview(hStack)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.layer.masksToBounds = true
        animationView.layer.cornerRadius = MainSendButtons.buttonSize / 2
        animationView.backgroundColor = Color.App.accentUIColor
        addSubview(animationView)
        if appState.connectionStatus != .connected {
            animationView.play()
        }

        heightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        heightConstraint?.isActive = true
        NSLayoutConstraint.activate([
            hStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            hStack.leadingAnchor.constraint(equalTo: btnLeading.trailingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(equalTo: btnTrailing.leadingAnchor, constant: -8),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            btnLeading.widthAnchor.constraint(equalToConstant: MainSendButtons.buttonSize),
            btnLeading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            btnLeading.heightAnchor.constraint(equalToConstant: MainSendButtons.buttonSize),
            btnLeading.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            btnTrailing.widthAnchor.constraint(equalToConstant: MainSendButtons.buttonSize),
            btnTrailing.heightAnchor.constraint(equalToConstant: MainSendButtons.buttonSize),
            btnTrailing.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            btnTrailing.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            animationView.widthAnchor.constraint(equalToConstant: MainSendButtons.buttonSize),
            animationView.heightAnchor.constraint(equalToConstant: MainSendButtons.buttonSize),
            animationView.trailingAnchor.constraint(equalTo: btnTrailing.trailingAnchor),
            animationView.leadingAnchor.constraint(equalTo: btnTrailing.leadingAnchor),
            animationView.topAnchor.constraint(equalTo: btnTrailing.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: btnTrailing.bottomAnchor),
        ])
        
        registerHeightChange()
        registerInternetConnection()
        
        /// Prepare draft mode.
        prepareDraft()
        
        registerTextChange()
        registerModeChange()
        registerAttachmentsChange()
        
        // It's essential when we open up the thread for the first time in situation like we are forwarding/reply privately
        setButtonsIcons(mode: viewModel.getMode())
    }

    private func registerInternetConnection() {
        appState.$connectionStatus
            .sink { [weak self] newState in
                self?.showConnectionAnimation(show: newState != .connected)
            }
            .store(in: &cancellableSet)
    }
    
    private func registerModeChange() {
        viewModel.modePublisher.sink { [weak self] newMode in
            guard let self = self, appState.lifeCycleState == .active else { return }
            setButtonsIcons(mode: newMode)
            let isShowPickerButton = newMode.type == .showButtonsPicker
            threadVM?.delegate?.showPickerButtons(isShowPickerButton)
        }
        .store(in: &cancellableSet)
        
        threadVM?.attachmentsViewModel.objectWillChange.sink { [weak self] in
            guard let self = self else { return }
            let disable = threadVM?.attachmentsViewModel.attachementsReady == false
            disableSendButton(disable)
        }
        .store(in: &cancellableSet)
    }
    
    private func registerAttachmentsChange() {
        /// We have to drop first to prevent emptying the send button if it has a draft / editMessage draft
        threadVM?.attachmentsViewModel.$attachments.dropFirst().sink { [weak self] attachments in
            guard let self = self else { return }
            /// Just update the UI to call registerModeChange inside that method it will detect the mode.
            viewModel.setMode(type: .voice)
            if attachments.count > 0 {
                setButtonsIcons(mode: viewModel.getMode(), hasAttachment: attachments.count > 0)
            }
        }
        .store(in: &cancellableSet)
    }
    
    private func registerHeightChange() {
        multilineTextField.onHeightChange = { [weak self] height in
            guard let self = self else { return }
            heightConstraint?.constant = height + 16
        }
    }

    private func registerTextChange() {
        multilineTextField.onTextChanged = { [weak self] text in
            guard let self = self else { return }
            viewModel.setText(newValue: text ?? "")
            setButtonsIcons(mode: viewModel.getMode())
        }

        viewModel.onTextChanged = { [weak self] newValue in
            guard let self = self else { return }
            multilineTextField.setTextAndDirection(newValue ?? "")
            multilineTextField.updateHeightIfNeeded()
            setButtonsIcons(mode: viewModel.getMode())
        }
    }
    
    private func prepareDraft() {
        if !viewModel.isTextEmpty() {
            multilineTextField.setTextAndDirection(viewModel.getText())
            /// We need a delay to get the correct frame width after showing,
            /// and then we can calculate the right height if the text is too long in draft mode.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.multilineTextField.updateHeightIfNeeded()
            }
        }
    }

    private func registerGestures() {
        btnLeading.action = { [weak self] in
            guard let self = self else { return }
            
            let hasForward = prop.forwardMessages?.isEmpty == false
            let sameForward = viewModel.threadId == prop.forwardMessageRequest?.threadId
            let hasForwardSameInThread = hasForward && sameForward
            
            let mode = viewModel.getMode()
            if viewModel.showAudio(mode: mode) == true {
                startVoiceRecording()
            } else {
                // open the picker with leading attachment button once use has entered something in the text field.
                onBtnToggleAttachmentButtonsTapped()
            }
        }
        
        btnTrailing.action = { [weak self] in
            guard let self = self else { return }
            let mode = viewModel.getMode()
            let isPickerOpen = mode.type == .showButtonsPicker
            let isEmptyText = viewModel.isTextEmpty()
            let hasAttachment = viewModel.hasAttachment()
            let hasForward = prop.forwardMessages?.isEmpty == false
            let sameForward = viewModel.threadId == prop.forwardMessageRequest?.threadId
            let hasForwardSameInThread = hasForward && sameForward
            let hasReplyPrivately = prop.replyPrivately != nil
            
            if isPickerOpen || (!isPickerOpen && !hasAttachment && isEmptyText) && !hasForwardSameInThread && !hasReplyPrivately {
                // Close / Open picker
                onBtnToggleAttachmentButtonsTapped()
            } else if !isEmptyText || hasAttachment || hasForwardSameInThread || hasReplyPrivately {
                // Send
                onBtnSendTapped()
            }
        }
    }

    private func startVoiceRecording() {
        threadVM?.delegate?.showRecording(true)
        viewModel.setMode(type: .voice)
    }

    @objc private func onBtnSendTapped() {
        threadVM?.historyVM.cancelTasks()
        let task: Task<Void, any Error> = Task { [weak self] in
            guard let self = self else { return }
            await threadVM?.sendMessageViewModel.sendTextMessage()
            threadVM?.mentionListPickerViewModel.text = ""
            threadVM?.delegate?.openReplyMode(nil)
            threadVM?.delegate?.openEditMode(nil)
        }
        threadVM?.historyVM.setTask(task)
    }

    @objc private func onBtnToggleAttachmentButtonsTapped() {
        let isShowingButtonsPicker = threadVM?.sendContainerViewModel.getMode().type == .showButtonsPicker
        viewModel.setMode(type: isShowingButtonsPicker ? .voice : .showButtonsPicker)
        setButtonsIcons(mode: viewModel.getMode())
        onViewModelChanged()
    }

    public func onViewModelChanged() {
        if viewModel.getText() != multilineTextField.string {
            multilineTextField.setTextAndDirection(viewModel.getText())  // When sending a message and we want to clear out the txetfield
        }
        setButtonsIcons(mode: viewModel.getMode())
    }

    private func setButtonsIcons(mode: SendcContainerMode, hasAttachment: Bool? = nil) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            let showMic = viewModel.showAudio(mode: mode)
            let isTextEmpty = multilineTextField.isEmptyText()
            let showCamera = viewModel.showCamera(mode: mode)
            let showSendButton = viewModel.showSendButton(mode: mode)
            let pickerIsOpen = mode.type == .showButtonsPicker
            let hasAttachment = hasAttachment ?? viewModel.hasAttachment()
            let hasForward = prop.forwardMessages?.isEmpty == false
            let sameForward = viewModel.threadId == prop.forwardMessageRequest?.threadId
            let hasForwardSameInThread = hasForward && sameForward
            let hasReplyPrivately = prop.replyPrivately != nil
            
            let hideLeading = hasAttachment || pickerIsOpen || hasForwardSameInThread
            
            btnLeading.constraints.first(where: {$0.firstAttribute == .width})?.constant = hideLeading ? 0 : MainSendButtons.buttonSize
            
            /// Leading Icon
            if showMic && isTextEmpty && !pickerIsOpen {
                btnLeading.imageView.tintColor = Color.App.textSecondaryUIColor
                btnLeading.imageView.image = UIImage(systemName: "mic")
            } else if showCamera && isTextEmpty && !pickerIsOpen {
                btnLeading.imageView.image = UIImage(systemName: "camera")
                btnLeading.imageView.tintColor = Color.App.accentUIColor
            } else if (isTextEmpty && pickerIsOpen) || hasForwardSameInThread {
                btnLeading.imageView.image = nil
            } else {
                btnLeading.imageView.image = UIImage(named: "ic_attachment")?.withRenderingMode(.alwaysTemplate)
                btnLeading.imageView.tintColor = Color.App.accentUIColor
            }
            
            /// Trailing icon
            let trailingIcon: String
            if hasAttachment || !isTextEmpty || hasForwardSameInThread || hasReplyPrivately {
                trailingIcon = "chevron.right"
            } else if pickerIsOpen {
                trailingIcon = "chevron.down"
            } else {
                trailingIcon = "plus"
            }
            
            btnTrailing.imageView.image = UIImage(systemName: trailingIcon)
        }
    }

    public func focusOnTextView(focus: Bool) {
        if focus {
            multilineTextField.focus()
        } else {
            multilineTextField.unfocus()
        }
    }
    
    private func disableSendButton(_ disable: Bool) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }
            btnTrailing.isUserInteractionEnabled = !disable
            btnTrailing.alpha = disable ? 0.5 : 1
        }
    }
    
    private func showConnectionAnimation(show: Bool) {
        animationView.isHidden = !show
        if show {
            animationView.play()
        } else {
            animationView.stop()
        }
        btnTrailing.isUserInteractionEnabled = !show
    }
}
