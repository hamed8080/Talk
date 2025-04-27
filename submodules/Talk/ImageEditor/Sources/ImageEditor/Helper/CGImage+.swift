//
//  CGImage+.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/27/25.
//

import UIKit

extension CGImage {
    func storeInTemp() -> URL? {
        let image =  UIImage(cgImage: self)
        // 1. Get the temp directory
        let tempDirectory = FileManager.default.temporaryDirectory
        
        // 2. Create a full file URL
        let fileName = UUID().uuidString + ".png"
        let fileURL = tempDirectory.appending(component: fileName, directoryHint: .notDirectory)
        
        // 3. Convert UIImage to Data (you can choose PNG or JPEG)
        guard let imageData = image.pngData() else { return nil }
        // 4. Write data to file
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
