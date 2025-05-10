//
// ImageEditorView.swift
// Copyright (c) 2022 ImageEditor
//
// Created by Hamed Hosseini on 12/14/22

import UIKit
import SwiftUI
import CoreImage

@MainActor
public final class ImageEditorView: UIView, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let btnClose = CircularSymbolButton("xmark")
    private let btnReset = CircularSymbolButton("arrow.trianglehead.2.counterclockwise.rotate.90")
    private let btnDoneCropping = CircularSymbolButton("checkmark", imageIconSize: 36)
    private let buttonsHStack = UIStackView()
    private let btnAddText = CircularSymbolButton("t.square", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnFlip = CircularSymbolButton("arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnRotate = CircularSymbolButton("rotate.left", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnCrop = CircularSymbolButton("crop", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnDone = UIButton(type: .system)
    
    private let cropOverlay = CropOverlayView()
    private var isCropping = false
    
    private let url: URL
    private let doneTitle: String
    private let font: UIFont
    private let padding: CGFloat = 16
    
    public var onDone: (URL?, Error?) -> Void
    public var onClose: (() -> Void)?
    
    public init(url: URL, font: UIFont = .systemFont(ofSize: 16), doneTitle: String, onDone: @escaping (URL?, Error?) -> Void) {
        self.url = url
        self.doneTitle = doneTitle
        self.font = font
        self.onDone = onDone
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        // Force Left-to-Right
        semanticContentAttribute = .forceLeftToRight
        
        /// Setup scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        addSubview(scrollView)
        
        /// Setup imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(contentsOfFile: url.path())
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        
        /// Setup btnClose
        btnClose.onTap = {[weak self] in self?.onClose?() }
        addSubview(btnClose)
        
        /// Setup btnReset
        btnReset.onTap = {[weak self] in self?.resetTapped() }
        addSubview(btnReset)
        
        /// Setup Done btnDoneCropping
        btnDoneCropping.onTap = {[weak self] in self?.croppingDoneTapped() }
        if let url = Bundle.module.url(forResource: "doneCropping", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            btnDoneCropping.setCustomImage(image: image)
        }
        
        addSubview(btnDoneCropping)
        showBtnCroppingDone(show: false)
        
        /// Setup btnAddText
        btnAddText.onTap = {[weak self] in self?.addTextTapped() }
        
        /// Setup btnFlip
        btnFlip.onTap = {[weak self] in self?.flipTapped() }
        
        /// Setup btnRotate
        btnRotate.onTap = {[weak self] in self?.rotateTapped() }
        
        /// Setup btnCrop
        btnCrop.onTap = {[weak self] in self?.cropTapped() }
        
        /// Setup btnDone
        btnDone.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        btnDone.setTitle(doneTitle, for: .normal)
        btnDone.setTitleColor(.white, for: .normal)
        btnDone.titleLabel?.font = font
        
        let dividerContainer = UIView()
        dividerContainer.translatesAutoresizingMaskIntoConstraints = false
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .white.withAlphaComponent(0.4)
        dividerContainer.addSubview(divider)
        
        /// Setup buttonsHStack
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        buttonsHStack.axis = .horizontal
        buttonsHStack.spacing = 0
        buttonsHStack.distribution = .fillEqually
        buttonsHStack.alignment = .center
        buttonsHStack.translatesAutoresizingMaskIntoConstraints = false
        buttonsHStack.layer.cornerRadius = 12
        buttonsHStack.clipsToBounds = true
        buttonsHStack.layoutMargins = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        buttonsHStack.isLayoutMarginsRelativeArrangement = true
        buttonsHStack.addSubview(blurView)
        buttonsHStack.semanticContentAttribute = .forceLeftToRight
        addSubview(buttonsHStack)
        
        buttonsHStack.addArrangedSubview(btnDone)
        buttonsHStack.addArrangedSubview(dividerContainer)
        buttonsHStack.addArrangedSubview(btnAddText)
        buttonsHStack.addArrangedSubview(btnFlip)
        buttonsHStack.addArrangedSubview(btnRotate)
        buttonsHStack.addArrangedSubview(btnCrop)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            btnClose.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            btnClose.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            
            btnReset.trailingAnchor.constraint(equalTo: btnClose.leadingAnchor, constant: -padding),
            btnReset.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            
            btnDoneCropping.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            btnDoneCropping.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            
            buttonsHStack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            buttonsHStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonsHStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            
            dividerContainer.heightAnchor.constraint(equalToConstant: 32),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.topAnchor.constraint(equalTo: dividerContainer.topAnchor, constant: 6),
            divider.bottomAnchor.constraint(equalTo: dividerContainer.bottomAnchor, constant: -6),
            divider.centerXAnchor.constraint(equalTo: dividerContainer.centerXAnchor),
            
            blurView.topAnchor.constraint(equalTo: buttonsHStack.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: buttonsHStack.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: buttonsHStack.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: buttonsHStack.trailingAnchor),
        ])
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

extension ImageEditorView {
    func scaleImage(image: UIImage, to newSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension ImageEditorView {
    @objc func rotateTapped() {
        guard let image = imageView.image else { return }
        /// Disable rotate button while rotating
        btnRotate.isUserInteractionEnabled = false
        btnRotate.alpha = 0.0
        
        let rotatedImage = imageView.rotate()
        
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = rotatedImage
        } completion: { _ in
            // Renable after animation
            self.btnRotate.isUserInteractionEnabled = true
            self.btnRotate.alpha = 1.0
        }
    }
}

extension ImageEditorView {
    @objc func addTextTapped() {
        let textView = EditableTextView()
        textView.text = "Edit me"
        textView.frame = CGRect(x: imageView.center.x - 100, y: imageView.center.y - 100, width: 200, height: textView.fontSize + 16)
        addSubview(textView)
    }
}

extension ImageEditorView {
    @objc func flipTapped() {
        guard let image = imageView.image?.cgImage else { return }
        let ciImage = CIImage(cgImage: image)
        
        /// Flip horizontally
        let flippedCIImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
        let context = CIContext()
        if let cgImage = context.createCGImage(flippedCIImage, from: flippedCIImage.extent) {
            let flippedImage = UIImage(cgImage: cgImage)
            UIView.transition(with: imageView, duration: 0.2, options: .transitionFlipFromLeft) {
                self.imageView.image = flippedImage
            }
        }
    }
}

/// Actions
extension ImageEditorView {
    @objc func doneTapped() {
        if isCropping {
            removeCropOverlays()
        }
        
        resignAllTextViews()
        addTextViewsToImageLayer()
        /// to clear out focus on text view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard
                let self = self,
                let cgImage = self.imageView.getClippedCroppedImage(),
                let outputURL = cgImage.storeInTemp(pathExtension: self.url.pathExtension)
            else {
                self?.onDone(nil, NSError(domain: "failed to get the image", code: -1))
                return
            }
#if DEBUG
            print("output edited image url path is: \(outputURL.path())")
#endif
            self.onDone(outputURL, nil)
        }
    }
    
    @objc func croppingDoneTapped() {
        showActionButtons(show: true)
        showBtnCroppingDone(show: false)
        applyCrop()
    }
    
    private func showActionButtons(show: Bool) {
        // From alpha
        buttonsHStack.alpha = show ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            // To alpha
            buttonsHStack.alpha = show ? 1.0 : 0.0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            buttonsHStack.isHidden = !show
            buttonsHStack.isUserInteractionEnabled = show
        }
    }
    
    private func showBtnCroppingDone(show: Bool) {
        // From alpha
        btnDoneCropping.alpha = show ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            // To alpha
            btnDoneCropping.alpha = show ? 1.0 : 0.0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            btnDoneCropping.isHidden = !show
            btnDoneCropping.isUserInteractionEnabled = show
        }
    }
    
    @objc func cropTapped() {
        enterCropMode()
        showActionButtons(show: false)
        showBtnCroppingDone(show: true)
    }
    
    private func enterCropMode() {
        isCropping = true
        cropOverlay.frame = imageView.bounds
        cropOverlay.backgroundColor = .clear
        cropOverlay.isUserInteractionEnabled = true
        imageView.addSubview(cropOverlay)
    }
    
    private func applyCrop() {
        guard let image = imageView.image, let croppedCgImage = cropOverlay.getCropped(bounds: imageView.bounds, image: image) else { return }
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        cropOverlay.removeFromSuperview()
        isCropping = false
        resetScrollView()
    }
    
    private func resetScrollView() {
        scrollView.setZoomScale(1.0, animated: false)
        scrollView.contentOffset = .zero
        imageView.frame = scrollView.bounds
    }
    
    @objc private func resetTapped() {
        imageView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        imageView.image = UIImage(contentsOfFile: url.path())
        showBtnCroppingDone(show: false)
        if isCropping {
            showActionButtons(show: true)
            isCropping = false
        }
    }
}

extension ImageEditorView {
    private func removeAllTextViews() {
        subviews.forEach { view in
            if view is EditableTextView {
                view.removeFromSuperview()
            }
        }
    }

    private func resignAllTextViews() {
        subviews.forEach { view in
            if view is EditableTextView {
                view.resignFirstResponder()
            }
        }
    }
    
    private func addTextViewsToImageLayer() {
        subviews.forEach { view in
            if view is EditableTextView {
                view.removeFromSuperview()
                imageView.addSubview(view)
            }
        }
    }

    private func removeCropOverlays() {
        imageView.subviews.forEach { view in
            if view is CropOverlayView {
                view.removeFromSuperview()
            }
        }
    }
}
