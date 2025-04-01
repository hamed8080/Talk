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
    private let btnClose = UIButton(type: .system)
    private let btnReset = UIButton(type: .system)
    private let buttonsHStack = UIStackView()
    private let btnAddText = UIButton(type: .system)
    private let btnFlip = UIButton(type: .system)
    private let btnRotate = UIButton(type: .system)
    private let btnCrop = UIButton(type: .system)
    
    private let url: URL
    private let padding: CGFloat = 16
    
    public init(url: URL) {
        self.url = url
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        /// Setup scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        addSubview(scrollView)
        
        /// Setup imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .green
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(contentsOfFile: url.path())
        scrollView.addSubview(imageView)
        
        /// Setup btnClose
        btnClose.translatesAutoresizingMaskIntoConstraints = false
        btnClose.setTitle("close", for: .normal)
        btnClose.titleLabel?.textColor = .red
        btnClose.backgroundColor = .red
        addSubview(btnClose)
        
        /// Setup btnReset
        btnReset.translatesAutoresizingMaskIntoConstraints = false
        btnReset.setTitle("reset", for: .normal)
        btnReset.titleLabel?.textColor = .red
        btnReset.backgroundColor = .red
        addSubview(btnReset)
        
        /// Setup btnAddText
        btnAddText.translatesAutoresizingMaskIntoConstraints = false
        btnAddText.setTitle("AddText", for: .normal)
        btnAddText.titleLabel?.textColor = .red
        btnAddText.addTarget(self, action: #selector(addTextTapped), for: .touchUpInside)
        
        /// Setup btnFlip
        btnFlip.translatesAutoresizingMaskIntoConstraints = false
        btnFlip.setTitle("Flip", for: .normal)
        btnFlip.titleLabel?.textColor = .red
        btnFlip.addTarget(self, action: #selector(flipTapped), for: .touchUpInside)
        
        /// Setup btnRotate
        btnRotate.translatesAutoresizingMaskIntoConstraints = false
        btnRotate.setTitle("Rotate", for: .normal)
        btnRotate.titleLabel?.textColor = .red
        btnRotate.addTarget(self, action: #selector(rotateTapped), for: .touchUpInside)
        
        /// Setup btnCrop
        btnCrop.translatesAutoresizingMaskIntoConstraints = false
        btnCrop.setTitle("Crop", for: .normal)
        btnCrop.titleLabel?.textColor = .red
        btnCrop.addTarget(self, action: #selector(cropTapped), for: .touchUpInside)
                
        /// Setup buttonsHStack
        buttonsHStack.axis = .horizontal
        buttonsHStack.spacing = 4
        buttonsHStack.distribution = .fillEqually
        buttonsHStack.alignment = .center
        buttonsHStack.translatesAutoresizingMaskIntoConstraints = false
        buttonsHStack.backgroundColor = .red
        buttonsHStack.layer.cornerRadius = 8
        addSubview(buttonsHStack)
        
        buttonsHStack.addArrangedSubview(btnAddText)
        buttonsHStack.addArrangedSubview(btnFlip)
        buttonsHStack.addArrangedSubview(btnRotate)
        buttonsHStack.addArrangedSubview(btnCrop)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            btnClose.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            btnClose.topAnchor.constraint(equalTo: topAnchor),
            btnClose.heightAnchor.constraint(equalToConstant: 48),
            btnClose.widthAnchor.constraint(equalToConstant: 48),
            
            btnReset.trailingAnchor.constraint(equalTo: btnClose.leadingAnchor, constant: -padding),
            btnReset.topAnchor.constraint(equalTo: topAnchor),
            btnReset.heightAnchor.constraint(equalToConstant: 48),
            btnReset.widthAnchor.constraint(equalToConstant: 48),
            
            btnAddText.heightAnchor.constraint(equalToConstant: 48),
            btnAddText.widthAnchor.constraint(equalToConstant: 48),
            
            btnFlip.heightAnchor.constraint(equalToConstant: 48),
            btnFlip.widthAnchor.constraint(equalToConstant: 48),
            
            btnRotate.heightAnchor.constraint(equalToConstant: 48),
            btnRotate.widthAnchor.constraint(equalToConstant: 48),
            
            btnCrop.heightAnchor.constraint(equalToConstant: 48),
            btnCrop.widthAnchor.constraint(equalToConstant: 48),
            
            buttonsHStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            buttonsHStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            buttonsHStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            buttonsHStack.heightAnchor.constraint(equalToConstant: 48),
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

public extension ImageEditorView {
    func getCGImage() -> CGImage? {
        return nil
    }
}

extension ImageEditorView {
    @objc func rotateTapped() {
        guard let image = imageView.image?.cgImage else { return }
        let ciImage = CIImage(cgImage: image)
        let size = UIImage(contentsOfFile: url.path())?.size ?? .zero
        
        /// Rotate horizontally
        let transform = CGAffineTransform(translationX: size.height, y: 0)
            .rotated(by: .pi / 2)
        let rotatedCIImage = ciImage.transformed(by: transform)
        let context = CIContext()
        if let cgImage = context.createCGImage(rotatedCIImage, from: rotatedCIImage.extent) {
            let rotatedImage = UIImage(cgImage: cgImage)
            imageView.image = rotatedImage
        }
    }
}

extension ImageEditorView {
    @objc func addTextTapped() {
        
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
            imageView.image = flippedImage
        }
    }
}

extension ImageEditorView {
    @objc func cropTapped() {
        
    }
}

struct ImageEditorWrapper: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UIView {
        let view = ImageEditorView(url: url)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
}

#if DEBUG
#Preview {
    if let url = Bundle.module.url(forResource: "test", withExtension: "png") {
        ImageEditorWrapper(url: url)
    }
}
#endif
