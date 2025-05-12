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
        
        // Prevent crop rect from getting bigger than the original image.
        if newCropRect.width > imageRectInImageView.width || newCropRect.height > imageRectInImageView.height { return }
        
        // Prevent crop rect position is outside of the original image on x axis.
        if newCropRect.origin.x < imageRectInImageView.origin.x || newCropRect.origin.x + newCropRect.width > imageRectInImageView.origin.x + imageRectInImageView.width { return }
        
        // Prevent crop rect position is outside of the original image on y axis.
        if newCropRect.origin.y < imageRectInImageView.origin.y || newCropRect.origin.y + newCropRect.height > imageRectInImageView.origin.y + imageRectInImageView.height { return }
        
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
