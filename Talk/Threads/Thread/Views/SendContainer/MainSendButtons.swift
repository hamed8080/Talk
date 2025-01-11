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
import UIKit
import Combine

public final class MainSendButtons: UIStackView {
    private let btnToggleAttachmentButtons = UIImageButton(imagePadding: .init(all: 8))
    private let btnSend = UIImageButton(imagePadding: .init(all: 10))
    private let btnMic = UIImageButton(imagePadding: .init(all: 8))
    private let btnCamera = UIImageButton(imagePadding: .init(all: 8))
    private var btnEmoji = UIImageButton(imagePadding: .init(all: 8))
    private let multilineTextField = SendContainerTextView()
    private weak var threadVM: ThreadViewModel?
    private var viewModel: SendContainerViewModel { threadVM?.sendContainerViewModel ?? .init() }
    private var cancellableSet = Set<AnyCancellable>()
    public static let initSize: CGFloat = 42
    private var cameraCapturer: CameraCapturer?

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
        axis = .horizontal
        spacing = 8
        alignment = .bottom
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true
        semanticContentAttribute = .forceLeftToRight

        btnToggleAttachmentButtons.translatesAutoresizingMaskIntoConstraints = false
        btnToggleAttachmentButtons.imageView.contentMode = .scaleAspectFit
        btnToggleAttachmentButtons.tintColor = Color.App.accentUIColor
        btnToggleAttachmentButtons.layer.masksToBounds = true
        btnToggleAttachmentButtons.layer.cornerRadius = MainSendButtons.initSize / 2
        btnToggleAttachmentButtons.backgroundColor = Color.App.bgSendInputUIColor
        btnToggleAttachmentButtons.imageView.backgroundColor = Color.App.bgSendInputUIColor
        btnToggleAttachmentButtons.imageView.isOpaque = true
        btnToggleAttachmentButtons.accessibilityIdentifier = "btnToggleAttachmentButtonsMainSendButtons"
        btnToggleAttachmentButtons.setContentHuggingPriority(.required, for: .horizontal)

        btnMic.translatesAutoresizingMaskIntoConstraints = false
        btnMic.imageView.contentMode = .scaleAspectFit
        btnMic.tintColor = Color.App.textSecondaryUIColor
        btnMic.accessibilityIdentifier = "btnMicMainSendButtons"
        btnMic.isOpaque = true

        btnCamera.translatesAutoresizingMaskIntoConstraints = false
        btnCamera.imageView.contentMode = .scaleAspectFit
        btnCamera.tintColor = Color.App.textSecondaryUIColor
        btnCamera.accessibilityIdentifier = "btnCameraMainSendButtons"
        btnCamera.setContentHuggingPriority(.required, for: .horizontal)
        btnCamera.isOpaque = true
        btnCamera.setIsHidden(true)

        btnSend.translatesAutoresizingMaskIntoConstraints = false
        btnSend.imageView.contentMode = .scaleAspectFit
        btnSend.tintColor = Color.App.textPrimaryUIColor
        btnSend.layer.masksToBounds = true
        btnSend.layer.cornerRadius = (MainSendButtons.initSize - 4) / 2
        btnSend.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        btnSend.backgroundColor = Color.App.accentUIColor
        btnSend.isOpaque = true
        btnSend.accessibilityIdentifier = "btnSendMainSendButtons"
        btnSend.setContentHuggingPriority(.required, for: .horizontal)
        btnSend.setIsHidden(true)
        btnSend.action = { [weak self] in
            self?.onBtnSendTapped()
        }

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
        hStack.layoutMargins = .init(top: -4, left: 8, bottom: 0, right: 8)//-4 to move textfield higher to make the cursor center in the textfield.
        hStack.isLayoutMarginsRelativeArrangement = true

        
        
        multilineTextField.translatesAutoresizingMaskIntoConstraints = false
        multilineTextField.accessibilityIdentifier = "multilineTextFieldMainSendButtons"
        multilineTextField.setContentHuggingPriority(.required, for: .horizontal)
        multilineTextField.setContentCompressionResistancePriority(.required, for: .horizontal)
        hStack.addArrangedSubview(multilineTextField)

        btnEmoji.translatesAutoresizingMaskIntoConstraints = false
        btnEmoji.imageView.tintColor = Color.App.redUIColor
        btnEmoji.accessibilityIdentifier = "btnEmojiMainSendButtons"
        btnEmoji.setIsHidden(true)
        btnEmoji.setContentHuggingPriority(.required, for: .horizontal)
//        hStack.addArrangedSubview(btnEmoji)

        addArrangedSubviews([btnToggleAttachmentButtons, hStack, btnMic, btnCamera, btnSend])

        NSLayoutConstraint.activate([
            btnToggleAttachmentButtons.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnToggleAttachmentButtons.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnSend.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize - 4),
            btnSend.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize - 4),
            btnMic.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnMic.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnCamera.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnCamera.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnEmoji.widthAnchor.constraint(equalToConstant: MainSendButtons.initSize),
            btnEmoji.heightAnchor.constraint(equalToConstant: MainSendButtons.initSize),
        ])

        /// Prepare draft mode.
        prepareDraft()
        
        registerTextChange()
        
        prepareUI()
    }

    private func prepareUI() {
        Task.detached {
            let sendImage: UIImage?
            if #available(iOS 13.0, *) {
                let config = UIImage.SymbolConfiguration(pointSize: 8, weight: .medium, scale: .small)
                sendImage = UIImage(systemName: "arrow.up", withConfiguration: config)
            } else {
                sendImage = UIImage(systemName: "arrow.up")
            }
            let emojiImage = UIImage(named: "emoji")
            let cameraImage = UIImage(systemName: "camera")
            let micImage = UIImage(systemName: "mic")
            let toogleImage = UIImage(systemName: "paperclip")
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                btnSend.imageView.image = sendImage
                btnEmoji.imageView.image = emojiImage
                btnCamera.imageView.image = cameraImage
                btnMic.imageView.image = micImage
                btnToggleAttachmentButtons.imageView.image = toogleImage
            }
        }

        // It's essential when we open up the thread for the first time in situation like we are forwarding/reply privately
        animateMainButtons()
    }

    private func registerTextChange() {
        multilineTextField.onTextChanged = { [weak self] text in
            guard let self = self else { return }
            viewModel.setText(newValue: text ?? "")
            let isEmpty = threadVM?.sendContainerViewModel.isTextEmpty() == true
            btnSend.showWithAniamtion(!isEmpty)
            btnMic.showWithAniamtion(isEmpty)
        }

        viewModel.onTextChanged = { [weak self] newValue in
            guard let self = self else { return }
            multilineTextField.setTextAndDirection(newValue ?? "")
            multilineTextField.updateHeightIfNeeded()

            let isEmpty = threadVM?.sendContainerViewModel.isTextEmpty() == true
            btnSend.showWithAniamtion(!isEmpty)
            btnMic.showWithAniamtion(isEmpty)
        }
    }
    
    private func prepareDraft() {
        if !viewModel.isTextEmpty() {
            multilineTextField.setTextAndDirection(viewModel.getText())
            let isEmpty = multilineTextField.isEmptyText()
            btnSend.showWithAniamtion(!isEmpty)
            btnMic.showWithAniamtion(isEmpty)
            /// We need a delay to get the correct frame width after showing,
            /// and then we can calculate the right height if the text is too long in draft mode.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.multilineTextField.updateHeightIfNeeded()
            }
        }
    }

    private func registerGestures() {
        let micTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMode))
        let cameraTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMode))
        btnMic.addGestureRecognizer(micTapGesture)
        btnCamera.addGestureRecognizer(cameraTapGesture)

        let micLongGesture = UILongPressGestureRecognizer(target: self, action: #selector(startRecording))
        micLongGesture.minimumPressDuration = 0.3
        let cameraLongGesture = UILongPressGestureRecognizer(target: self, action: #selector(showPopup))
        cameraLongGesture.minimumPressDuration = 0.3
        btnMic.addGestureRecognizer(micLongGesture)
        btnCamera.addGestureRecognizer(cameraLongGesture)

        btnToggleAttachmentButtons.action = { [weak self] in
            self?.onBtnToggleAttachmentButtonsTapped()
        }
    }

    @objc private func toggleMode(_ sender: UIGestureRecognizer) {
        viewModel.toggleVideorecording()
        let isRecording = viewModel.isVideoRecordingSelected
        btnCamera.showWithAniamtion(isRecording)
        btnMic.showWithAniamtion(!isRecording)
    }

    @objc private func startRecording(_ sender: UIGestureRecognizer) {
        // Update ThreadViewContorler delegate to show recordingUI
        // Check if it is began then show the UI unless we don't call it twice.
        if sender.state != .began { return }
        threadVM?.delegate?.showRecording(true)
        threadVM?.delegate?.showPickerButtons(false)
    }

    @objc private func showPopup(_ sender: UIGestureRecognizer) {
        // Check if it is began then show the popover unless we don't call it twice.
        if sender.state != .began { return }
        let takeVideo  = UIAlertAction(title: "MessageType.video".bundleLocalized(), style: .default) { (action) in
            // Respond to user selection of the action
            self.openTakeVideoPicker()
        }
        takeVideo.setValue(UIImage(systemName: "video"), forKey: "image")

        let takePhoto = UIAlertAction(title: "MessageType.picture".bundleLocalized(), style: .default) { (action) in
            // Respond to user selection of the action
            self.openTakePicturePicker()
        }
        takePhoto.setValue(UIImage(systemName: "photo"), forKey: "image")

        let cancel = UIAlertAction(title: "General.cancel".bundleLocalized(), style: .cancel) { (action) in
            // Respond to user selection of the action
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(takeVideo)
        alert.addAction(takePhoto)
        alert.addAction(cancel)

        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.sourceView = btnCamera

        (threadVM?.delegate as? UIViewController)?.present(alert, animated: true) {
            // The alert was presented
        }
    }

    @objc private func onBtnSendTapped() {
        Task { [weak self] in
            guard let self = self else { return }
            await threadVM?.sendMessageViewModel.sendTextMessage()
            threadVM?.mentionListPickerViewModel.text = ""
            threadVM?.delegate?.openReplyMode(nil)
            threadVM?.delegate?.openEditMode(nil)
        }
    }

    @objc private func onBtnToggleAttachmentButtonsTapped() {
        let currentValue = threadVM?.sendContainerViewModel.showPickerButtons == true
        let newState = !currentValue
        threadVM?.delegate?.showPickerButtons(newState) // toggle
        toggleAttchmentButton(show: newState)
        onViewModelChanged()
    }

    public func onViewModelChanged() {
        if viewModel.getText() != multilineTextField.string {
            multilineTextField.setTextAndDirection(viewModel.getText())  // When sending a message and we want to clear out the txetfield
        }
        animateMainButtons()
    }

    private func animateMainButtons() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            btnMic.setIsHidden(!viewModel.showAudio())
            btnCamera.setIsHidden(!viewModel.showCamera())
            btnSend.setIsHidden(!viewModel.showSendButton())
        }
    }

    public func toggleAttchmentButton(show: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            let attImage = UIImage(systemName: show ? "chevron.down" : "paperclip")
            btnToggleAttachmentButtons.imageView.image = attImage
        }
    }

    private func openTakeVideoPicker() {
        let captureObject = CameraCapturer(isVideo: true) { [weak self] image, url, resources in
            guard let self = self, let videoURL = url, let data = try? Data(contentsOf: videoURL) else { return }
            let fileName = "video-\(Date().fileDateString).mov"
            let item = ImageItem(id: UUID(), isVideo: true, data: data, width: 0, height: 0, originalFilename: fileName)
            threadVM?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            self.cameraCapturer = nil
        }
        self.cameraCapturer = captureObject
        (threadVM?.delegate as? UIViewController)?.present(captureObject.vc, animated: true)
    }

    private func openTakePicturePicker() {
        let captureObject = CameraCapturer(isVideo: false) { [weak self] image, url, resources in
            guard let self = self, let image = image else { return }
            let item = ImageItem(data: image.jpegData(compressionQuality: 80) ?? Data(),
                                 width: Int(image.size.width),
                                 height: Int(image.size.height),
                                 originalFilename: "image-\(Date().fileDateString).jpg")
            threadVM?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            self.cameraCapturer = nil
        }
        self.cameraCapturer = captureObject
        (threadVM?.delegate as? UIViewController)?.present(captureObject.vc, animated: true)
    }

    public func focusOnTextView(focus: Bool) {
        if focus {
            multilineTextField.becomeFirstResponder()
        } else {
            multilineTextField.resignFirstResponder()
        }
    }

    public func showSendButton(_ show: Bool) {
        btnSend.showWithAniamtion(show)
    }

    public func showMicButton(_ show: Bool) {
        btnMic.showWithAniamtion(show)
    }
}
