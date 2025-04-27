//
//  CropOverlayView.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/23/25.
//

import UIKit

final class CropOverlayView: UIView {
    private var leftRect = CGRect(x: 0, y: 100, width: 24, height: 24)
    private var rightRect = CGRect(x: 200, y: 100, width: 24, height: 24)
    private var topRect = CGRect(x: 100, y: 0, width: 24, height: 24)
    private var bottomRect = CGRect(x: 100, y: 200, width: 24, height: 24)
    private enum DragHandle {
        case none
        case left, right, top, bottom
        case move
    }
    
    private var cropRect: CGRect {
        didSet {
            calculatePoints()
            setNeedsDisplay()
        }
    }

    private var initialTouchPoint: CGPoint = .zero
    private var draggingHandle: DragHandle = .none

    override init(frame: CGRect) {
        cropRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        isUserInteractionEnabled = true
        calculatePoints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(bounds)

        context.clear(cropRect)

        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2)
        context.stroke(cropRect)
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: leftRect)
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: rightRect)
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: topRect)
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: bottomRect)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        
        if leftRect.contains(point) {
            draggingHandle = .left
        } else if rightRect.contains(point) {
            draggingHandle = .right
        } else if topRect.contains(point) {
            draggingHandle = .top
        } else if bottomRect.contains(point) {
            draggingHandle = .bottom
        } else if cropRect.contains(point) {
            draggingHandle = .move
        } else {
            draggingHandle = .none
        }
        
        initialTouchPoint = point
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard draggingHandle != .none, let point = touches.first?.location(in: self) else { return }
        
        let dx = point.x - initialTouchPoint.x
        let dy = point.y - initialTouchPoint.y
        
        var newCropRect = cropRect
        
        switch draggingHandle {
        case .move:
            newCropRect = newCropRect.offsetBy(dx: dx, dy: dy)
        case .left:
            newCropRect.origin.x += dx
            newCropRect.size.width -= dx
        case .right:
            newCropRect.size.width += dx
        case .top:
            newCropRect.origin.y += dy
            newCropRect.size.height -= dy
        case .bottom:
            newCropRect.size.height += dy
        case .none:
            break
        }
        
        // Prevent inverted width/height
        if newCropRect.width >= 50, newCropRect.height >= 50 {
            cropRect = newCropRect
            initialTouchPoint = point
        }
    }
    
    private func calculatePoints() {
        let width: CGFloat = 24
        let half: CGFloat = 12
        leftRect = CGRect(x: cropRect.minX - half, y: cropRect.midY - half, width: width, height: width)
        rightRect = CGRect(x: cropRect.maxX - half, y: cropRect.midY - half, width: width, height: width)
        topRect = CGRect(x: cropRect.midX - half, y: cropRect.minY - half, width: width, height: width)
        bottomRect = CGRect(x: cropRect.midX - half, y: cropRect.maxY - half, width: width, height: width)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingHandle = .none
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        /// Initial position of the cropRect on the center of the screen
        cropRect = CGRect(x: bounds.midX - 100, y: bounds.midY - 100, width: 200, height: 200)
    }
}

extension CropOverlayView {
    public func getCropped(bounds: CGRect, image: UIImage) -> CGImage? {
        let cropRect = cropRect
        
        // Step 1: Get size ratios
        let imageSize = image.size
        let imageViewSize = bounds.size
        
        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let scale = min(scaleWidth, scaleHeight) // Maintain aspect ratio (like .scaleAspectFit)
        
        // Step 2: Calculate image's displayed frame inside imageView
        let imageDisplaySize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let imageOrigin = CGPoint(x: (imageViewSize.width - imageDisplaySize.width) / 2,
                                  y: (imageViewSize.height - imageDisplaySize.height) / 2)
        let imageFrameInImageView = CGRect(origin: imageOrigin, size: imageDisplaySize)
        
        // Step 3: Convert crop rect to image coordinate space
        let normalizedX = (cropRect.origin.x - imageFrameInImageView.origin.x) / imageFrameInImageView.width
        let normalizedY = (cropRect.origin.y - imageFrameInImageView.origin.y) / imageFrameInImageView.height
        let normalizedWidth = cropRect.size.width / imageFrameInImageView.width
        let normalizedHeight = cropRect.size.height / imageFrameInImageView.height
        
        let cropZone = CGRect(
            x: normalizedX * imageSize.width,
            y: normalizedY * imageSize.height,
            width: normalizedWidth * imageSize.width,
            height: normalizedHeight * imageSize.height
        )
        
        // Step 4: Perform cropping
        guard let croppedCgImage = image.cgImage?.cropping(to: cropZone) else { return nil }
        return croppedCgImage
    }
}
