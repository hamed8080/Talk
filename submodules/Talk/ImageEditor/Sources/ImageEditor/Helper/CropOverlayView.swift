//
//  CropOverlayView.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/23/25.
//

import UIKit

final class CropOverlayView: UIView {
    public var imageRectInImageView = CGRect()
    
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

            // Clamp move within image bounds
            if newCropRect.minX < imageRectInImageView.minX {
                newCropRect.origin.x = imageRectInImageView.minX
            }
            if newCropRect.maxX > imageRectInImageView.maxX {
                newCropRect.origin.x = imageRectInImageView.maxX - newCropRect.width
            }
            if newCropRect.minY < imageRectInImageView.minY {
                newCropRect.origin.y = imageRectInImageView.minY
            }
            if newCropRect.maxY > imageRectInImageView.maxY {
                newCropRect.origin.y = imageRectInImageView.maxY - newCropRect.height
            }

        case .left:
            let newX = max(cropRect.origin.x + dx, imageRectInImageView.minX)
            let delta = cropRect.origin.x - newX
            newCropRect.origin.x = newX
            newCropRect.size.width += delta

        case .right:
            let newWidth = min(cropRect.width + dx, imageRectInImageView.maxX - cropRect.origin.x)
            newCropRect.size.width = newWidth

        case .top:
            let newY = max(cropRect.origin.y + dy, imageRectInImageView.minY)
            let delta = cropRect.origin.y - newY
            newCropRect.origin.y = newY
            newCropRect.size.height += delta

        case .bottom:
            let newHeight = min(cropRect.height + dy, imageRectInImageView.maxY - cropRect.origin.y)
            newCropRect.size.height = newHeight

        case .none:
            break
        }

        // Prevent inverted width/height or too small
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
    public func getCropped(image: UIImage) -> CGImage? {
        let cropRect = cropRect
        // Step 1: Convert crop rect to image coordinate space
        let normalizedX = (cropRect.origin.x - imageRectInImageView.origin.x) / imageRectInImageView.width
        let normalizedY = (cropRect.origin.y - imageRectInImageView.origin.y) / imageRectInImageView.height
        let normalizedWidth = cropRect.size.width / imageRectInImageView.width
        let normalizedHeight = cropRect.size.height / imageRectInImageView.height
        
        let cropZone = CGRect(
            x: normalizedX * image.size.width,
            y: normalizedY * image.size.height,
            width: normalizedWidth * image.size.width,
            height: normalizedHeight * image.size.height
        )
        
        // Step 2: Perform cropping
        return image.cgImage?.cropping(to: cropZone)
    }
}
