//
//  UIImage+.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/12/25.
//

import UIKit

extension UIImage {
    static func tabbarRoundedImage(image: UIImage, size: CGSize = CGSize(width: 28, height: 28)) -> UIImage? {
        let image = image.withRenderingMode(.alwaysOriginal)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            // Create a circular or rounded path
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 12) // Half of width/height = perfect circle
            path.addClip() // Apply mask
            
            image.draw(in: rect)
        }
        
        return resized
    }
}
