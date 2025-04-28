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
    func reloadItem(indexPath: IndexPath)
}

@MainActor
public final class AttachmentsViewModel: ObservableObject {
    @Published public private(set)var attachments: [AttachmentFile] = []
    public private(set) var isExpanded: Bool = false
    private var selectedFileUrls: [URL] = []
    private weak var viewModel: ThreadViewModel?
    public weak var delegate: AttachmentDelegate?
    
    public init() {}
    
    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }
    
    public func addSelectedPhotos(imageItem: ImageItem) {
        attachments.removeAll(where: {$0.type != .gallery})
        attachments.append(.init(id: imageItem.id, type: .gallery, request: imageItem))
        delegate?.reload()
        animateObjectWillChange() // To enable/disable send button if it was downloading image/video form the iCloud
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
        if let index = attachments.firstIndex(where: {$0.id == attachment.id}) {
            (attachments[index].request as? ImageItem)?.progress?.cancel()
        }
        delegate?.reload()
        resetSendContainerIfIsEmpty()
    }
    
    public func onDocumentPicker(_ urls: [URL]) {
        selectedFileUrls = urls
        addSelectedFile()
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
    
    private func resetSendContainerIfIsEmpty() {
        if viewModel?.sendContainerViewModel.isTextEmpty() == true, attachments.count == 0 {
            viewModel?.sendContainerViewModel.clear()
        }
    }
    
    public func toggleExpandMode() {
        isExpanded.toggle()
        delegate?.reload()
    }
    
    public func prepared(_ data: Data, _ id: UUID, width: CGFloat?, height: CGFloat?, fileExt: String?) {
        if let index = attachments.firstIndex(where: {$0.id == id}) {
            (attachments[index].request as? ImageItem)?.data = data
            (attachments[index].request as? ImageItem)?.width = Int(width ?? 0)
            (attachments[index].request as? ImageItem)?.height = Int(height ?? 0)
            (attachments[index].request as? ImageItem)?.fileExt = fileExt
            delegate?.reloadItem(indexPath: IndexPath(row: index, section: 0))
            animateObjectWillChange() // To enable/diable send button if it was downloading image/video form the iCloud
        }
    }
    
    public func failed(_ error: Error?, _ id: UUID) {
        if let index = attachments.firstIndex(where: {$0.id == id}) {
            (attachments[index].request as? ImageItem)?.failed = true
            delegate?.reloadItem(indexPath: IndexPath(row: index, section: 0))
            animateObjectWillChange() // To enable/diable send button if it was downloading image/video form the iCloud
        }
    }
    
    public var attachementsReady: Bool {
        let imageItems = attachments.compactMap{ $0.request as? ImageItem }
        return imageItems.count(where: { $0.progress?.isFinished == false }) == 0
    }
    
    /// Compress an image to less than two megabytes.
    @AppBackgroundActor
    public func compressImage(image: UIImage, quality: CGFloat) async -> Data? {
        let data = autoreleasepool { image.jpegData(compressionQuality: quality / 100.0) }
        // It means the compression won't work anymore than this.
        if quality == 1 {
            return data
        }
        if let data = data, data.count > 2_000_000 {
            return await compressImage(image: image, quality: max(1, quality - 40.0))
        }
        return data
    }
}
