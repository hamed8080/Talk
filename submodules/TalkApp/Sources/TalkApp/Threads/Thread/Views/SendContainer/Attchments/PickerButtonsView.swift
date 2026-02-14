//
//  PickerButtonsView.swift
//  Talk
//
//  Created by Hamed Hosseini on 11/23/21.
//

import AdditiveUI
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels
import UIKit

public final class PickerButtonsView: UIStackView {
    private weak var viewModel: SendContainerViewModel?
    private let btnGallery = AttchmentButton(title: "General.gallery", image: "photo.fill")
    private let btnFile = AttchmentButton(title: "General.file", image: "doc.fill")
    private let btnLocation = AttchmentButton(title: "General.location", image: "location.fill")
    private let btnContact = AttchmentButton(title: "General.contact", image: "person.2.crop.square.stack.fill")
    private let btnCamera = AttchmentButton(title: "General.camera", image: "camera.fill")
    private weak var threadVM: ThreadViewModel?
    private var vc: UIViewController? { threadVM?.delegate?.viewController }
    private let documentPicker = DocumnetPickerViewController()
    private var cameraCapturer: CameraCapturer?
    private let galleryPicker = GallleryMediaPickerViewController()

    public init(viewModel: SendContainerViewModel?, threadVM: ThreadViewModel?) {
        self.threadVM = threadVM
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        registerGestures()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        axis = .horizontal
        spacing = 8
        alignment = .center
        distribution = .equalCentering
        layoutMargins = .init(top: 8, left: 8, bottom: 0, right: 8)
        isLayoutMarginsRelativeArrangement = true
        let leadingSpacer = UIView()
        leadingSpacer.translatesAutoresizingMaskIntoConstraints = false
        leadingSpacer.accessibilityIdentifier = "leadingSpacerPickerButtonsView"
        let trailingSpacer = UIView()
        trailingSpacer.translatesAutoresizingMaskIntoConstraints = false
        trailingSpacer.accessibilityIdentifier = "trailingSpacerPickerButtonsView"

        NSLayoutConstraint.activate([
            leadingSpacer.widthAnchor.constraint(equalToConstant: 24),
            leadingSpacer.heightAnchor.constraint(equalToConstant: 66),
            trailingSpacer.widthAnchor.constraint(equalToConstant: 24),
            trailingSpacer.heightAnchor.constraint(equalToConstant: 66),
        ])

        btnGallery.accessibilityIdentifier = "btnGalleryPickerButtonsView"
        btnFile.accessibilityIdentifier = "btnFilePickerButtonsView"
        btnLocation.accessibilityIdentifier = "btnLocationPickerButtonsView"
        btnCamera.accessibilityIdentifier = "btnCameraPickerButtonsView"

        addArrangedSubviews([leadingSpacer, btnCamera, btnGallery, btnFile, btnLocation, trailingSpacer])
    }

    private func registerGestures() {
        let galleryGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnGalleryTapped))
        galleryGesture.numberOfTapsRequired = 1
        btnGallery.addGestureRecognizer(galleryGesture)

        let fileGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnFileTapped))
        fileGesture.numberOfTapsRequired = 1
        btnFile.addGestureRecognizer(fileGesture)

        let locationGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnLocationTapped))
        locationGesture.numberOfTapsRequired = 1
        btnLocation.addGestureRecognizer(locationGesture)

        let contactGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnContactTapped))
        contactGesture.numberOfTapsRequired = 1
        btnContact.addGestureRecognizer(contactGesture)
        
        let cameraGesture = UITapGestureRecognizer(target: self, action: #selector(onBtnCameraTapped))
        cameraGesture.numberOfTapsRequired = 1
        btnCamera.addGestureRecognizer(cameraGesture)
    }

    @objc private func onBtnGalleryTapped(_ sender: UIGestureRecognizer) {
        hideKeyboard()
        presentImagePicker()
        closePickerButtons()
    }

    @objc private func onBtnFileTapped(_ sender: UIGestureRecognizer) {
        hideKeyboard()
        presentFilePicker()
        closePickerButtons()
    }

    @objc private func onBtnLocationTapped(_ sender: UIGestureRecognizer) {
        hideKeyboard()
        presentMapPicker()
        closePickerButtons()
    }

    @objc private func onBtnContactTapped(_ sender: UIGestureRecognizer) {
        hideKeyboard()
        closePickerButtons()
    }
    
    @objc private func onBtnCameraTapped(_ sender: UIGestureRecognizer) {
        hideKeyboard()
        openTakeVideoPicker()
        closePickerButtons()
    }

    public func closePickerButtons() {
        viewModel?.setMode(type: .voice)
    }

    public func show(_ show: Bool, stack: UIStackView) {
        if show {
            alpha = 0.0
            isHidden = false
            frame.origin.y += frame.size.height
            stack.insertArrangedSubview(self, at: 0)
        }
        UIView.animate(withDuration: show ? 0.3 : 0.2, delay: show ? 0.1 : 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2, options: .curveEaseInOut) {
            if show {
                self.frame.origin.y -= self.frame.size.height
            }
            self.alpha = show ? 1.0 : 0.0
            self.setIsHidden(!show)
        } completion: { completed in
            if completed, !show {
                self.removeFromSuperViewWithAnimation()
            }
        }
    }
    
    /// Hide keyboard when opening the map or other tools.
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension PickerButtonsView  {

    public func presentFilePicker() {
        documentPicker.viewModel = threadVM
        documentPicker.present(vc: vc)
    }
}

extension PickerButtonsView {

    public func presentImagePicker() {
        galleryPicker.viewModel = threadVM
        galleryPicker.present(vc: vc)
    }
}

extension PickerButtonsView {
    func presentMapPicker() {
        let mapVC = MapPickerViewController()
        mapVC.viewModel = threadVM
        mapVC.modalPresentationStyle = .fullScreen
        vc?.present(mapVC, animated: true)
    }
}

extension PickerButtonsView {
    private func openTakeVideoPicker() {
        let captureObject = CameraCapturer() { [weak self] image, url, resources in
            if let image = image {
                self?.onImageCaptured(image: image)
            } else if let url = url {
                self?.onVideoCaptured(videoURL: url)
            }
        }
        self.cameraCapturer = captureObject
        if captureObject.isCameraAccessDenied() {
            showPermissionDialog()
        } else {
            (threadVM?.delegate?.viewController)?.present(captureObject.vc, animated: true)
        }
    }
    
    private func onVideoCaptured(videoURL: URL) {
        guard let data = try? Data(contentsOf: videoURL) else { return }
        let fileName = "video-\(Date().fileDateString).mov"
        let item = ImageItem(id: UUID(), isVideo: true, data: data, width: 0, height: 0, originalFilename: fileName)
        threadVM?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
        /// Just update the UI to call registerModeChange inside that method it will detect the mode.
        viewModel?.setMode(type: .voice)
    }
    
    private func onImageCaptured(image: UIImage) {
        let item = ImageItem(data: image.jpegData(compressionQuality: 0.8) ?? Data(),
                             width: Int(image.size.width),
                             height: Int(image.size.height),
                             originalFilename: "image-\(Date().fileDateString).jpg")
        threadVM?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
        
        /// Wait to dismiss camera view controller then show image editor because image editor uses window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.threadVM?.attachmentsViewModel.delegate?.showImageEditorIfOneImagePicked()
        }
        self.cameraCapturer = nil
        /// Just update the UI to call registerModeChange inside that method it will detect the mode.
        viewModel?.setMode(type: .voice)
    }
    
    private func showPermissionDialog() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(CameraAccessDialog())
    }
}
