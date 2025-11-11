//
// ImageEditorView.swift
// Copyright (c) 2022 ImageEditor
//
// Created by Hamed Hosseini on 12/14/22

import UIKit
import SwiftUI
import CoreImage

@MainActor
public final class ImageEditorView: UIView, UIScrollViewDelegate, MainButtonsDelegate {
    private let scrollView = DrawingScrollView()
    private let imageView = UIImageView()
    private let mainButtonsStack: MainButtonsStack
    private let closeOrResetStack = CloseOrResetStack()
    private let btnDoneCropping = CircularSymbolButton("checkmark", imageIconSize: 36)
    private var drawingButtonsStack: UIStackView?
    private var drawingView: DrawingView?
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
    private let cancelTitle: String
    private let font: UIFont
    private let padding: CGFloat = 16
    
    public var onDone: (URL?, Error?) -> Void
    public var onClose: (() -> Void)?
    
    public init(url: URL, font: UIFont = .systemFont(ofSize: 16), doneTitle: String, cancelTitle: String, onDone: @escaping (URL?, Error?) -> Void) {
        self.url = url
        self.doneTitle = doneTitle
        self.cancelTitle = cancelTitle
        self.font = font
        self.onDone = onDone
        mainButtonsStack = .init(font: font, dontTitle: doneTitle)
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
        closeOrResetStack.translatesAutoresizingMaskIntoConstraints = false
        closeOrResetStack.onClose = { [weak self] in self?.onCloseTapped() }
        closeOrResetStack.onReset = { [weak self] in self?.resetTapped() }
        addSubview(closeOrResetStack)
        
        /// Setup Done btnDoneCropping
        btnDoneCropping.onTap = { [weak self] in self?.croppingDoneTapped() }
        if let url = Bundle.module.url(forResource: "doneCropping", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            btnDoneCropping.setCustomImage(image: image)
        }
        
        addSubview(btnDoneCropping)
        showBtnCroppingDone(show: false)
        
        mainButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        mainButtonsStack.delegate = self
        addSubview(mainButtonsStack)
        
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
            
            closeOrResetStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            closeOrResetStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            
            btnDoneCropping.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            btnDoneCropping.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            
            mainButtonsStack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            mainButtonsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            mainButtonsStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding),
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
            showDrawingButtonsStack(show: false)
            removeDrawingView()
            showActionButtons(show: true)
            closeOrResetStack.isHidden = false
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
        let rotatedImage = imageView.rotate()
        
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = rotatedImage
        }
    }
}

extension ImageEditorView {
    @objc func addTextTapped() {
        let textView = EditableTextView { [weak self] in
            /// Start Editing completion
            self?.isEdittingText = true
            self?.showActionButtons(show: false)
            self?.closeOrResetStack.isHidden = true
        } doneCompletion: { [weak self] in
            self?.isEdittingText = false
            self?.showActionButtons(show: true)
            self?.closeOrResetStack.isHidden = false
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
        showDrawingButtonsStack(show: true)
        showActionButtons(show: false)
        closeOrResetStack.isHidden = true
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
        showDrawingButtonsStack(show: false)
        closeOrResetStack.isHidden = false
        scrollView.setMinimumNumberOfTouchesPanGesture(1)
        
        showActionButtons(show: true)
        removeDrawingView()
        
        /// Firstly, we remove it from the image view and make it nil, to remove reference of it, then we add it as a subview.
        drawingView.finished = true
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
                colorSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                colorSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
                colorSlider.heightAnchor.constraint(equalToConstant: 48 + 24),
            ])
        } else {
            colorSlider.removeFromSuperview()
        }
    }
    
    private func showDrawingButtonsStack(show: Bool) {
        if show {
            let drawingTopStack = ResetOrUndoStack()
            drawingTopStack.onUndo = { [weak self] in
                self?.drawingView?.undo()
            }
            
            drawingTopStack.onReset = { [weak self] in
                self?.drawingView?.reset()
            }
            drawingTopStack.translatesAutoresizingMaskIntoConstraints = false
            addSubview(drawingTopStack)
            
            let stack = DoneOrCancelStack(font: font, doneTitle: doneTitle, cancelTitle: cancelTitle)
            stack.onDone = { [weak self] in
                self?.onDoneDrawing()
            }
            stack.onCancel = { [weak self] in
                self?.onCloseTapped()
            }
            addSubview(stack)
            drawingButtonsStack = stack
            
            bringSubviewToFront(stack)
            
            NSLayoutConstraint.activate([
                drawingTopStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
                drawingTopStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                
                stack.centerXAnchor.constraint(equalTo: centerXAnchor),
                stack.heightAnchor.constraint(equalToConstant: 46),
                stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -38),
                
                colorSlider.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -8),
            ])
        } else {
            if let view = subviews.first(where: { $0 is ResetOrUndoStack }) {
                view.removeFromSuperview()
            }
            drawingButtonsStack?.removeFromSuperview()
            drawingButtonsStack = nil
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
        mainButtonsStack.alpha = show ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            // To alpha
            mainButtonsStack.alpha = show ? 1.0 : 0.0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            mainButtonsStack.isHidden = !show
            mainButtonsStack.isUserInteractionEnabled = show
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
    static let resetIconName: String = {
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.trianglehead.2.counterclockwise.rotate.90"
        } else {
            return "arrow.2.circlepath"
        }
    }()
    
    static let flipIconName: String = {
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
        } else {
            return "flip.horizontal"
        }
    }()
}
