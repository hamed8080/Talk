//
//  UIImageView+.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/27/25.
//

import UIKit

extension UIImageView {
    func getClippedCroppedImage() -> CGImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
        
        // 2. Get the actual image frame inside the imageView
        guard let originalImage = self.image else { return nil }
        
        let imageSize = originalImage.size
        let viewSize = bounds.size
        
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
            // Handle other contentModes if needed
            drawnImageFrame = bounds
        }
        
        // 3. Crop the rendered image to the actual image area
        guard let cgImage = image.cgImage else { return nil }
        
        let scale = image.scale
        let croppingRect = CGRect(
            x: drawnImageFrame.origin.x * scale,
            y: drawnImageFrame.origin.y * scale,
            width: drawnImageFrame.size.width * scale,
            height: drawnImageFrame.size.height * scale
        )
        
        return cgImage.cropping(to: croppingRect)
    }
}
