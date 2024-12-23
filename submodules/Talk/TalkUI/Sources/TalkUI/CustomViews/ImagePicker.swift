//
//  ImagePicker.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import Foundation
import PhotosUI
import SwiftUI
public struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: @Sendable (UIImage, [PHAssetResource]?) -> Void

    public init(sourceType: UIImagePickerController.SourceType, onImagePicked: @escaping @Sendable (UIImage, [PHAssetResource]?) -> Void) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status != .authorized {
            PHPhotoLibrary.requestAuthorization {_ in }
        }
    }

    final public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding private var presentationMode: PresentationMode
        private let sourceType: UIImagePickerController.SourceType
        private let onImagePicked: @Sendable (UIImage, [PHAssetResource]?) -> Void

        public init(presentationMode: Binding<PresentationMode>, sourceType: UIImagePickerController.SourceType, onImagePicked: @escaping @Sendable (UIImage, [PHAssetResource]?) -> Void) {
            _presentationMode = presentationMode
            self.sourceType = sourceType
            self.onImagePicked = onImagePicked
        }

        public func imagePickerController(_: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
        {
            guard let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
            var assetResource: [PHAssetResource]?
            if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                assetResource = PHAssetResource.assetResources(for: asset)
            }

            onImagePicked(uiImage, assetResource)
            presentationMode.dismiss()
        }

        public func imagePickerControllerDidCancel(_: UIImagePickerController) {
            presentationMode.dismiss()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(presentationMode: presentationMode,
                    sourceType: sourceType,
                    onImagePicked: onImagePicked)
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_: UIImagePickerController, context _: UIViewControllerRepresentableContext<ImagePicker>) {}
}
