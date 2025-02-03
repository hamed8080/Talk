//
//  GallleryMediaPickerViewController.swift
//  Talk
//
//  Created by hamed on 6/17/24.
//

import Foundation
import PhotosUI
import TalkViewModels
import TalkModels

/// Image or Video picker handler.
@MainActor
public final class GallleryMediaPickerViewController: NSObject, PHPickerViewControllerDelegate {
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
    }
    
    private func processProviders(_ itemProviders: [NSItemProvider]) {
        itemProviders.forEach { provider in
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                let id = UUID()
                let item = placeholderVideoItem(item: provider, id: id)
                //                provider.loadFileRepresentation(for: .movie) { url, openInPlace, error in
                //                    print("video url is: \(url)")
                //                }
                
                let progress = provider.loadDataRepresentation(for: .movie) { [weak self] data, error in
                    Task { [weak self] in
                        await self?.onVideoItemPrepared(data: data, id: id, error: error)
                    }
                }
                item.progress = progress
                viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            }
            
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                let id = UUID()
                let item = placeholderImageItem(item: provider, id: id)
                //                provider.loadFileRepresentation(for: .image) { url, openInPlace, error in
                //                    print("image url is: \(url)")
                //                }
                
                let progress = provider.loadObject(ofClass: UIImage.self) { [weak self] item, error in
                    Task { [weak self] in
                        await self?.onImageItemPrepared(image: item as? UIImage, id: id, error: error)
                    }
                }
                item.progress = progress
                viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            }
        }
    }
    
    private func placeholderVideoItem(item: NSItemProvider, id: UUID) -> ImageItem {
        return ImageItem(id: id,
                         isVideo: true,
                         data: Data(),
                         width: 0,
                         height: 0,
                         originalFilename: item.suggestedName ?? "unknown",
                         progress: nil)
    }
    
    private func onVideoItemPrepared(data: Data?, id: UUID, error: Error?) {
        if let data = data {
            viewModel?.attachmentsViewModel.prepared(data, id, width: 0, height: 0)
        } else if let error = error {
            viewModel?.attachmentsViewModel.failed(error, id)
        }
    }
    
    private func placeholderImageItem(item: NSItemProvider, id: UUID) -> ImageItem {
        return ImageItem(id: id,
                         data: Data(),
                         width: 0,
                         height: 0,
                         originalFilename: item.suggestedName ?? "unknown",
                         progress: nil)
    }
    
    private func onImageItemPrepared(image: UIImage?, id: UUID, error: Error?) async {
        if let data = image?.pngData() {
            viewModel?.attachmentsViewModel.prepared(data, id, width: image?.size.width, height: image?.size.height ?? 0)
        } else if let error = error {
            viewModel?.attachmentsViewModel.failed(error, id)
        }
    }
}
