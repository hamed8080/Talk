//
//  AttachmentsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Chat
import UniformTypeIdentifiers
import UIKit
import TalkModels

public protocol AttachmentDelegate: AnyObject {
    func reload()
}

@MainActor
public final class AttachmentsViewModel {
    public private(set)var attachments: [AttachmentFile] = []
    public private(set) var isExpanded: Bool = false
    private var allImageItems: ContiguousArray<ImageItem> = []
    private var selectedFileUrls: [URL] = []
    private weak var viewModel: ThreadViewModel?
    public weak var delegate: AttachmentDelegate?

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    public func addSelectedPhotos(imageItem: ImageItem) {
        attachments.removeAll(where: {$0.type != .gallery})
        allImageItems.append(imageItem)
        attachments.append(.init(id: imageItem.id, type: .gallery, request: imageItem))
        delegate?.reload()
        resetSendContainerIfIsEmpty()
    }

    public func addSelectedFile() {
        attachments.removeAll(where: {$0.type != .file})
        selectedFileUrls.forEach { fileItem in
            attachments.append(.init(type: .file, request: fileItem))
        }
        delegate?.reload()
        resetSendContainerIfIsEmpty()
    }

    public func addFileURL(url: URL) {
        attachments.removeAll(where: {$0.type != .file})
        attachments.append(.init(type: .file, request: url))
        delegate?.reload()
        resetSendContainerIfIsEmpty()
    }

    public func clear() {
        allImageItems.removeAll()
        selectedFileUrls.removeAll()
        attachments.removeAll()
        delegate?.reload()
        resetSendContainerIfIsEmpty()
    }

    public func append(attachments: [AttachmentFile]) {
        self.attachments.removeAll(where: {$0.type != attachments.first?.type})
        self.attachments.append(contentsOf: attachments)
        delegate?.reload()
    }

    public func remove(_ attachment: AttachmentFile) {
        attachments.removeAll(where: {$0.id == attachment.id})
        allImageItems.removeAll(where: {$0.id == attachment.id})
        delegate?.reload()
        resetSendContainerIfIsEmpty()
    }

    public func onDocumentPicker(_ urls: [URL]) {
        selectedFileUrls = urls
        addSelectedFile()
    }

    public func onPickerResult(_ itemProviders: [NSItemProvider]) {
        processItemProviders(itemProviders)
    }

    private func processItemProviders(_ itemProviders: [NSItemProvider]) {
        itemProviders.forEach { provider in
            let name = provider.suggestedName ?? "unknown"
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                _ = provider.loadDataRepresentation(for: .movie) { data, error in
                    if let data = data {
                        Task { [weak self] in
                            await self?.processVideo(data: data, name: name)
                        }
                    }
                }
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadObject(ofClass: UIImage.self) { item, error in
                    if let image = item as? UIImage {
                        Task { [weak self] in
                            await self?.processImage(image: image, name: name)
                        }
                    }
                }
            }
        }
    }

    private func processImage(image: UIImage, name: String) async {
        let data = await lessThanTwoMegabyteImage(image: image, quality: 100) ?? .init()
        let image = UIImage(data: data) ?? .init()
        let item = ImageItem(data: data,
                             width: Int(image.size.width),
                             height: Int(image.size.height),
                             originalFilename: name)
        await MainActor.run {
            addSelectedPhotos(imageItem: item)
        }
    }

    private func processVideo(data: Data, name: String) async {
        let item = ImageItem(isVideo: true,
                             data: data,
                             width: 0,
                             height: 0,
                             originalFilename: name)
        await MainActor.run {
            addSelectedPhotos(imageItem: item)
        }
    }

    private func lessThanTwoMegabyteImage(image: UIImage, quality: CGFloat) async -> Data? {
        let data = autoreleasepool { image.jpegData(compressionQuality: quality / 100.0) }
        // It means the compression won't work anymore than this.
        if quality == 1 {
            return data
        }
        if let data = data, data.count > 2_000_000 {
            return await lessThanTwoMegabyteImage(image: image, quality: max(1, quality - 40.0))
        }
        return data
    }

    private func resetSendContainerIfIsEmpty() {
        if viewModel?.sendContainerViewModel.isTextEmpty() == true, attachments.count == 0 {
            viewModel?.delegate?.showSendButton(false)
            viewModel?.delegate?.showMicButton(true)
            viewModel?.delegate?.showCameraButton(false)
        }
    }

    public func toggleExpandMode() {
        isExpanded.toggle()
        delegate?.reload()
    }
}
