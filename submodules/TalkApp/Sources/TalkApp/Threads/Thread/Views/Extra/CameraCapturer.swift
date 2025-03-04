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
                vc.mediaTypes = [UTType.movie.identifier]
            } else {
                vc.mediaTypes = [kUTTypeMovie as String]
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
        onImagePicked(uiImage, videoURL, assetResource)
        picker.dismiss(animated: true)
    }
}
