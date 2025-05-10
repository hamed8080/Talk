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

extension UIImageView {
    func rotate() -> UIImage? {
        guard let image = image else { return nil }
        let radians: CGFloat = .pi / 2
        var newSize = CGRect(origin: CGPoint.zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size

        /// Get the next largest integer less than or equal to the size for width and height
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        /// A new bitmap-based graphics context is created with the new image size, allowing for high-quality image manipulation
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        
        /// The context's origin is translated to the new image's center, ensuring the rotation occurs around the center point
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        
        /// The context is rotated by the specified number of radians, setting the stage for the new image rendering
        context.rotate(by: CGFloat(radians))
        
        /// The original image is drawn onto the rotated context, resulting in a rotated image
        image.draw(in: CGRect(x: -image.size.width/2, y: -image.size.height/2, width: image.size.width, height: image.size.height))
        
        /// The rotated image is extracted from the context and prepared for return
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        /// The graphics context is closed, ensuring that all resources are properly released
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
