//
//  GallleryViewController.swift
//  Talk
//
//  Created by hamed on 6/17/24.
//

import Foundation
import PhotosUI
import TalkViewModels
import TalkModels

@MainActor
public final class GallleryViewController: NSObject, PHPickerViewControllerDelegate {
    public weak var viewModel: ThreadViewModel?

    public func present(vc: UIViewController?) {
        let library = PHPhotoLibrary.shared()
        var config = PHPickerConfiguration(photoLibrary: library)
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .livePhotos, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        vc?.present(picker, animated: true)
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProviders = results.map(\.itemProvider)
        processProviders(itemProviders)
        viewModel?.delegate?.onItemsPicked()
    }

    private func processProviders(_ itemProviders: [NSItemProvider]) {
        itemProviders.forEach { provider in
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                let name = provider.suggestedName ?? "unknown"
                _ = provider.loadDataRepresentation(for: .movie) { data, error in
                    Task {
                        DispatchQueue.main.async {
                            if let data = data {
                                let item = ImageItem(isVideo: true,
                                                     data: data,
                                                     width: 0,
                                                     height: 0,
                                                     originalFilename: name)
                                self.viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
                            }
                        }
                    }
                }
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                let suggestedName = provider.suggestedName ?? "unknown"
                provider.loadObject(ofClass: UIImage.self) { item, error in
                    if let image = item as? UIImage {
                        let item = ImageItem(data: image.pngData() ?? Data(),
                                             width: Int(image.size.width),
                                             height: Int(image.size.height),
                                             originalFilename: suggestedName)
                        Task { @MainActor in
                            self.viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
                        }
                    }
                }
            }
        }
    }
}
