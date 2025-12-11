//
//  CameraCapturer.swift
//  Talk
//
//  Created by hamed on 4/2/24.
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CoreServices

class CameraCapturer: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let isVideo: Bool
    let onImagePicked: (UIImage?, URL?, [PHAssetResource]?) -> Void
    public var vc: UIImagePickerController

    init(isVideo: Bool, onImagePicked: @escaping (UIImage?, URL?, [PHAssetResource]?) -> Void) {
        self.isVideo = isVideo
        self.onImagePicked = onImagePicked
        vc = UIImagePickerController()
        super.init()
        vc.delegate = self
        vc.sourceType = .camera
        if isVideo {
            if #available(iOS 15.0, *) {
                vc.mediaTypes = [UTType.movie.identifier, UTType.image.identifier]
            } else {
                vc.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        var assetResource: [PHAssetResource]?
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            assetResource = PHAssetResource.assetResources(for: asset)
        }
        if let image = uiImage, picker.cameraDevice == .front {
            onImagePicked(image.horizontallyFlipped(), videoURL, assetResource)
        } else {
            onImagePicked(uiImage, videoURL, assetResource)
        }
        picker.dismiss(animated: true)
    }
    
    
    public func isCameraAccessDenied() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .denied || status == .restricted
    }
}

fileprivate extension UIImage {
    func horizontallyFlipped() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        draw(in: CGRect(origin: .zero, size: size))
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage
    }
}
