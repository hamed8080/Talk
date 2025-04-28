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
    private weak var threadVM: ThreadViewModel?
    private var vc: UIViewController? { threadVM?.delegate as? UIViewController }
    private let documentPicker = DocumnetPickerViewController()
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
            leadingSpacer.widthAnchor.constraint(equalToConstant: 66),
            leadingSpacer.heightAnchor.constraint(equalToConstant: 66),
            trailingSpacer.widthAnchor.constraint(equalToConstant: 66),
            trailingSpacer.heightAnchor.constraint(equalToConstant: 66),
        ])

        btnGallery.accessibilityIdentifier = "btnGalleryPickerButtonsView"
        btnFile.accessibilityIdentifier = "btnFilePickerButtonsView"
        btnLocation.accessibilityIdentifier = "btnLocationPickerButtonsView"

        addArrangedSubviews([leadingSpacer, btnGallery, btnFile, btnLocation, trailingSpacer])
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
    }

    @objc private func onBtnGalleryTapped(_ sender: UIGestureRecognizer) {
        presentImagePicker()
        closePickerButtons()
    }

    @objc private func onBtnFileTapped(_ sender: UIGestureRecognizer) {
        presentFilePicker()
        closePickerButtons()
    }

    @objc private func onBtnLocationTapped(_ sender: UIGestureRecognizer) {
        presentMapPicker()
        closePickerButtons()
    }

    @objc private func onBtnContactTapped(_ sender: UIGestureRecognizer) {
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
        if let sheet = mapVC.sheetPresentationController {
            sheet.detents = [.large()] // Full height
            sheet.prefersGrabberVisible = true // Optional grabber at the top
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false // Prevents dismissal by scrolling
            sheet.largestUndimmedDetentIdentifier = .large // Keep it undimmed
        }
        mapVC.modalPresentationStyle = .pageSheet
        vc?.present(mapVC, animated: true)
    }
}
