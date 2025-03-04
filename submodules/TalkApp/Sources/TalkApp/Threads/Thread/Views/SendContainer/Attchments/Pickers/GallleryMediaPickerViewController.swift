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
import OSLog

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
                let progress = provider.loadDataRepresentation(for: .movie) { data, error in
                    Task { [weak self] in
                        guard let self = self else { return }
                        if let data = data {
                            await onVideoItemPrepared(data: data, id: id, error: error)
                        } else if let error = error {
                            await log("Error load movie: \(error.localizedDescription)")
                        }
                    }
                }
                item.progress = progress
                viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            }
            
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                let id = UUID()
                let item = placeholderImageItem(item: provider, id: id)
                
                
                /// First we try to load `loadFileRepresentation` the chance of loading the image is close to 70%
                /// However the final file size is equal to it's actual size, and unlike `loadObject` it won't increase the final size
                let progress = provider.loadFileRepresentation(for: .image) { [weak self] url, openInPlace, error in
                    Task { @AppBackgroundActor [weak self] in
                        guard let self = self else { return }
                        if let url = url {
                            do {
                                let data = try Data(contentsOf: url)
                                await self.onImageItemPrepared(data: data, id: id, error: error)
                            } catch {
                                await self.log("Error loadFileRepresentation: \(error.localizedDescription)")
                                await self.loadImageObject(provider, id)
                            }
                        } else if let error = error {
                            await self.log("Image url is nil and error: \(error.localizedDescription)")
                            await self.loadImageObject(provider, id)
                        }
                    }
                }
                item.progress = progress
                viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            }
        }
    }

    /// Fallback to loadObject to get the image.
    /// The final size will be larger; however, the chance of getting the image is close to 100%.
    private func loadImageObject(_ provider: NSItemProvider, _ id: UUID) {
        log("Load image object fallback")
        let _ = provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            let image = image as? UIImage
            Task { @MainActor [weak self] in
                await self?.onImageItemPrepared(image: image, id: id, error: error)
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
    
    private func onImageItemPrepared(data: Data?, id: UUID, error: Error?) async {
        if let data = data {
            let image = UIImage(data: data)
            viewModel?.attachmentsViewModel.prepared(data, id, width: image?.size.width, height: image?.size.height ?? 0)
        } else if let error = error {
            viewModel?.attachmentsViewModel.failed(error, id)
        }
    }
    
    private func onImageItemPrepared(image: UIImage?, id: UUID, error: Error?) async {
        if let data = image?.jpegData(compressionQuality: 0.7) {
            let image = UIImage(data: data)
            viewModel?.attachmentsViewModel.prepared(data, id, width: image?.size.width, height: image?.size.height ?? 0)
        } else if let error = error {
            viewModel?.attachmentsViewModel.failed(error, id)
        }
    }
    
    private func log(_ message: String) {
        #if DEBUG
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Talk-App")
        logger.debug("\(message)")
        #endif
    }
}

extension NSItemProvider: @retroactive @unchecked Sendable {
    
}
