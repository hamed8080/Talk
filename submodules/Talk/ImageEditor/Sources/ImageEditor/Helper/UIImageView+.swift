//
//  UIImageView+.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/27/25.
//

import UIKit

extension UIImageView {
    func getClippedCroppedImage() -> CGImage? {
        guard let originalImage = self.image else { return nil }
        
        let imageSize = originalImage.size
        let imageScale = originalImage.scale
        let viewSize = bounds.size

        // Create a renderer that matches the original image size
        let format = UIGraphicsImageRendererFormat()
        format.scale = imageScale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: viewSize, format: format)
        
        let renderedImage = renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
        
        guard let cgImage = renderedImage.cgImage else { return nil }

        // Figure out the actual area where the image is drawn (in view coordinates)
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height
        
        var drawnImageFrame = CGRect.zero
        if contentMode == .scaleAspectFit {
            if imageAspect > viewAspect {
                // Image is wider
                let scaledHeight = viewSize.width / imageAspect
                drawnImageFrame = CGRect(
                    x: 0,
                    y: (viewSize.height - scaledHeight) / 2,
                    width: viewSize.width,
                    height: scaledHeight
                )
            } else {
                // Image is taller
                let scaledWidth = viewSize.height * imageAspect
                drawnImageFrame = CGRect(
                    x: (viewSize.width - scaledWidth) / 2,
                    y: 0,
                    width: scaledWidth,
                    height: viewSize.height
                )
            }
        } else {
            drawnImageFrame = bounds
        }
        
        let croppingRect = CGRect(
            x: drawnImageFrame.origin.x * imageScale,
            y: drawnImageFrame.origin.y * imageScale,
            width: drawnImageFrame.size.width * imageScale,
            height: drawnImageFrame.size.height * imageScale
        )

        return cgImage.cropping(to: croppingRect)
    }
}
