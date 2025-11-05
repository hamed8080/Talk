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
    private let scrollView = DrawingScrollView()
    private let imageView = UIImageView()
    private let btnClose = CircularSymbolButton("xmark")
    private let btnReset = CircularSymbolButton(ImageEditorView.resetIconName)
    private let btnDoneCropping = CircularSymbolButton("checkmark", imageIconSize: 36)
    private let buttonsHStack = UIStackView()
    private let btnDraw = CircularSymbolButton("pencil.and.outline", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnAddText = CircularSymbolButton("t.square", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnFlip = CircularSymbolButton(ImageEditorView.flipIconName, width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnRotate = CircularSymbolButton("rotate.left", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnCrop = CircularSymbolButton("crop", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnDone = UIButton(type: .system)
    private var drawingView: DrawingView?
    private var btnDoneDrawing = UIButton(type: .system)
    private var colorSlider = UIColorSlider()
    
    private let cropOverlay = CropOverlayView()
    private var isCropping = false
    private var isDrawing = false
    
    private var isEdittingText = false {
        didSet{
            if isEdittingText {
                imageView.alpha = 0.4
            } else {
                imageView.alpha = 1.0
            }
        }
    }
    
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
        btnClose.onTap = { [weak self] in self?.onCloseTapped() }
        addSubview(btnClose)
        
        /// Setup btnReset
        btnReset.onTap = { [weak self] in self?.resetTapped() }
        addSubview(btnReset)
        
        /// Setup Done btnDoneCropping
        btnDoneCropping.onTap = { [weak self] in self?.croppingDoneTapped() }
        if let url = Bundle.module.url(forResource: "doneCropping", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            btnDoneCropping.setCustomImage(image: image)
        }
        
        addSubview(btnDoneCropping)
        showBtnCroppingDone(show: false)
        
        /// Setup btnAddText
        btnAddText.onTap = { [weak self] in self?.addTextTapped() }
        
        /// Setup btnFlip
        btnFlip.onTap = { [weak self] in self?.flipTapped() }
        
        /// Setup btnRotate
        btnRotate.onTap = { [weak self] in self?.rotateTapped() }
        
        /// Setup btnCrop
        btnCrop.onTap = { [weak self] in self?.cropTapped() }
        
        /// Setup btnDraw
        btnDraw.onTap = { [weak self] in self?.drawTapped() }
        
        /// Setup btnDone
        btnDone.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        btnDone.setTitle(doneTitle, for: .normal)
        btnDone.setTitleColor(.white, for: .normal)
        btnDone.titleLabel?.font = font
        
        btnDoneDrawing.translatesAutoresizingMaskIntoConstraints = false
        btnDoneDrawing.setTitleColor(.white, for: .normal)
        btnDoneDrawing.backgroundColor = .orange
        btnDoneDrawing.layer.cornerRadius = 19
        btnDoneDrawing.layer.masksToBounds = true
        btnDoneDrawing.addTarget(self, action: #selector(onDoneDrawing), for: .touchUpInside)
        btnDoneDrawing.setTitle(doneTitle, for: .normal)
        btnDoneDrawing.titleLabel?.font = font
        btnDoneDrawing.isHidden = true
        addSubview(btnDoneDrawing)
        
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
        buttonsHStack.addArrangedSubview(btnDraw)
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
            
            btnDoneDrawing.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            btnDoneDrawing.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            btnDoneDrawing.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            btnDoneDrawing.heightAnchor.constraint(equalToConstant: 38)
        ])
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

extension ImageEditorView {
    private func onCloseTapped() {
        if isDrawing {
            isDrawing = false
            showColorSlider(show: false)
            btnDoneDrawing.isHidden = true
            removeDrawingView()
            showActionButtons(show: true)
            scrollView.setMinimumNumberOfTouchesPanGesture(1)
        } else {
            onClose?()
        }
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
        let textView = EditableTextView { [weak self] in
            /// Start Editing completion
            self?.isEdittingText = true
            self?.showActionButtons(show: false)
            self?.btnReset.isHidden = true
        } doneCompletion: { [weak self] in
            self?.isEdittingText = false
            self?.showActionButtons(show: true)
            self?.btnReset.isHidden = false
        }
        textView.frame = CGRect(x: imageView.center.x - 100, y: imageView.center.y - 100, width: 200, height: textView.fontSize + 16)
        textView.imageRectInImageView = imageView.imageFrameInsideImageView()
        addSubview(textView)
        textView.becomeFirstResponder()
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

extension ImageEditorView {
    @objc func drawTapped() {
        isDrawing = true
        showColorSlider(show: true)
        btnDoneDrawing.isHidden = false
        showActionButtons(show: false)
        scrollView.setMinimumNumberOfTouchesPanGesture(2)
        let drawingView = DrawingView(frame: imageView.bounds)
        drawingView.isUserInteractionEnabled = true
        drawingView.backgroundColor = .clear
        imageView.addSubview(drawingView)
        self.drawingView = drawingView
    }
    
    @objc private func onDoneDrawing() {
        guard let drawingView = drawingView else { return }
        isDrawing = false
        showColorSlider(show: false)
        btnDoneDrawing.isHidden = true
        scrollView.setMinimumNumberOfTouchesPanGesture(1)
        
        showActionButtons(show: true)
        removeDrawingView()
        
        /// Firstly, we remove it from the image view and make it nil, to remove reference of it, then we add it as a subview.
        imageView.addSubview(drawingView)
    }
    
    private func removeDrawingView() {
        drawingView?.removeFromSuperview()
        drawingView = nil
    }
    
    private func showColorSlider(show: Bool) {
        if show {
            colorSlider.translatesAutoresizingMaskIntoConstraints = false
            colorSlider.onColorChanged = { [weak self] color in
                self?.drawingView?.setDrawingColor(color: color)
            }
            addSubview(colorSlider)
            NSLayoutConstraint.activate([
                colorSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
                colorSlider.heightAnchor.constraint(equalToConstant: 128),
                colorSlider.widthAnchor.constraint(equalToConstant: 16),
                colorSlider.topAnchor.constraint(equalTo: btnClose.bottomAnchor, constant: 16),
            ])
        } else {
            colorSlider.removeFromSuperview()
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
        cropOverlay.imageRectInImageView = imageView.imageFrameInsideImageView()
        cropOverlay.backgroundColor = .clear
        cropOverlay.isUserInteractionEnabled = true
        imageView.addSubview(cropOverlay)
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    private func applyCrop() {
        guard let image = imageView.image, let croppedCgImage = cropOverlay.getCropped(image: image) else { return }
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
        subviews.forEach { view in
            if view is EditableTextView {
                view.removeFromSuperview()
            }
        }
        imageView.image = UIImage(contentsOfFile: url.path())
        showBtnCroppingDone(show: false)
        if isCropping {
            showActionButtons(show: true)
            isCropping = false
        }
        
        if isDrawing {
            removeDrawingView()
            /// Create a new instance and add it again to the imageView as a subview.
            drawTapped()
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

extension ImageEditorView {
    private static let resetIconName: String = {
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.trianglehead.2.counterclockwise.rotate.90"
        } else {
            return "arrow.2.circlepath"
        }
    }()
    
    private static let flipIconName: String = {
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
        } else {
            return "flip.horizontal"
        }
    }()
}
