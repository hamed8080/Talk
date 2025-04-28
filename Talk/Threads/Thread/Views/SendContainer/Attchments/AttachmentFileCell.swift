//
//  AttachmentFileCell.swift
//  Talk
//
//  Created by hamed on 4/3/24.
//

import UIKit
import TalkViewModels
import TalkUI
import TalkModels
import SwiftUI
import ImageEditor

@MainActor
public final class AttachmentFileCell: UITableViewCell {
    public var viewModel: ThreadViewModel!
    public var attachment: AttachmentFile!
    private let hStack = UIStackView()
    private let imgIcon = PaddingUIImageView()
    private let lblTitle = UILabel()
    private let lblSubtitle = UILabel()
    private let imgIcloudDonwloading = PaddingUIImageView()
    private let btnEditImage = UIButton(type: .system)
    private let btnRemove = UIButton(type: .system)
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.layoutMargins = .init(horizontal: 16, vertical: 4)
        hStack.isLayoutMarginsRelativeArrangement = true
        hStack.accessibilityIdentifier = "hStackAttachmentFileCell"
        
        lblTitle.font = UIFont.uiiransansBoldBody
        lblTitle.textColor = Color.App.textPrimaryUIColor
        lblTitle.accessibilityIdentifier = "lblTitleAttachmentFileCell"
        
        lblSubtitle.font = UIFont.uiiransansCaption3
        lblSubtitle.textColor = Color.App.textSecondaryUIColor
        lblSubtitle.accessibilityIdentifier = "lblSubtitleAttachmentFileCell"
        
        btnRemove.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "xmark")
        btnRemove.setImage(image, for: .normal)
        btnRemove.tintColor = Color.App.textSecondaryUIColor
        btnRemove.accessibilityIdentifier = "btnRemoveAttachmentFileCell"
        btnRemove.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        
        btnEditImage.translatesAutoresizingMaskIntoConstraints = false
        let editImage = UIImage(systemName: "pencil.line")
        btnEditImage.setImage(editImage, for: .normal)
        btnEditImage.tintColor = Color.App.textSecondaryUIColor
        btnEditImage.accessibilityIdentifier = "btnEidtImageAttachmentFileCell"
        btnEditImage.addTarget(self, action: #selector(editImageTapped), for: .touchUpInside)
        
        imgIcloudDonwloading.translatesAutoresizingMaskIntoConstraints = false
        imgIcloudDonwloading.layer.cornerRadius = 6
        imgIcloudDonwloading.layer.masksToBounds = true
        imgIcloudDonwloading.accessibilityIdentifier = "imgIcloudDonwloadingAttachmentFileCell"
        imgIcloudDonwloading.tintColor = Color.App.accentUIColor
        imgIcloudDonwloading.set(image: UIImage(systemName: "icloud") ?? .init(), inset: .init(all: 2))
        imgIcloudDonwloading.isHidden = true
        
        imgIcon.translatesAutoresizingMaskIntoConstraints = false
        imgIcon.layer.cornerRadius = 6
        imgIcon.layer.masksToBounds = true
        imgIcon.accessibilityIdentifier = "imgIconAttachmentFileCell"
        imgIcon.backgroundColor = Color.App.bgInputUIColor
        
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.accessibilityIdentifier = "vStackAttachmentFileCell"
        
        vStack.addArrangedSubview(lblTitle)
        vStack.addArrangedSubview(lblSubtitle)
        
        hStack.addArrangedSubview(imgIcon)
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(imgIcloudDonwloading)
        hStack.addArrangedSubview(btnEditImage)
        hStack.addArrangedSubview(btnRemove)
        
        contentView.addSubview(hStack)
        
        NSLayoutConstraint.activate([
            hStack.heightAnchor.constraint(equalToConstant: 48),
            imgIcon.widthAnchor.constraint(equalToConstant: 32),
            imgIcon.heightAnchor.constraint(equalToConstant: 32),
            imgIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            imgIcloudDonwloading.trailingAnchor.constraint(equalTo: btnRemove.leadingAnchor, constant: -8),
            imgIcloudDonwloading.widthAnchor.constraint(equalToConstant: 28),
            imgIcloudDonwloading.heightAnchor.constraint(equalToConstant: 28),
            btnEditImage.widthAnchor.constraint(equalToConstant: 28),
            btnEditImage.heightAnchor.constraint(equalToConstant: 28),
            btnRemove.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            btnRemove.widthAnchor.constraint(equalToConstant: 28),
            btnRemove.heightAnchor.constraint(equalToConstant: 28),
        ])
    }
    
    public func set(attachment: AttachmentFile) {
        self.attachment = attachment
        lblTitle.text = attachment.title
        lblSubtitle.text = attachment.subtitle
        let imageItem = attachment.request as? ImageItem
        let isVideo = imageItem?.isVideo == true
        let icon = attachment.icon
        let showIcouldDownloadImage = imageItem?.progress?.isFinished == false && imageItem != nil
        
        if icon != nil || isVideo {
            let image = UIImage(systemName: isVideo ? "film.fill" : icon ?? "")
            imgIcon.set(image: image ?? .init(), inset: .init(all: 6))
        } else if !isVideo {
            Task {
                if let scaledImage = await scaledImage(data: imageItem?.data) {
                    imgIcon.set(image: scaledImage, inset: .init(all: 0))
                }
            }
        }
        imgIcloudDonwloading.isHidden = !showIcouldDownloadImage
        btnEditImage.isHidden = attachment.type != .gallery
        btnEditImage.isUserInteractionEnabled = attachment.type == .gallery
    }
    
    @AppBackgroundActor
    private func scaledImage(data: Data?) async -> UIImage? {
        if let cgImage = data?.imageScale(width: 28)?.image {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    @objc private func removeTapped(_ sender: UIButton) {
        viewModel.attachmentsViewModel.remove(attachment)
    }
    
    @objc private func editImageTapped(_ sender: UIButton) {
        guard let data = (attachment.request as? ImageItem)?.data else { return }
        let fileExt = (attachment.request as? ImageItem)?.fileExt ?? "png"
        let fileName = UUID().uuidString + ".\(fileExt)"
        let tmpDir = FileManager.default.temporaryDirectory
        let url = tmpDir.appending(path: fileName, directoryHint: .notDirectory)
        do {
            try data.write(to: url)
            openEditor(url)
        } catch {
            // handle error
        }
    }
    
    private func openEditor(_ url: URL) {
        guard let vc = contentView.window?.rootViewController else { return }
        let font = UIFont.uiiransansBody ?? .systemFont(ofSize: 14)
        let editorVC = ImageEditorViewController(url: url, font: font, doneTitle: "General.submit".bundleLocalized())
        
        editorVC.onDone = { [weak self, weak editorVC] outputURL, error in
            guard let self = self,
                  let outputURL = outputURL,
                  let data = try? Data(contentsOf: outputURL)
            else { return }
            (self.attachment.request as? ImageItem)?.data = data
            self.lblSubtitle.text = self.attachment.subtitle
            Task {
                if let scaledImage = await self.scaledImage(data: data) {
                    self.imgIcon.set(image: scaledImage, inset: .init(all: 0))
                }
            }
            editorVC?.dismiss(animated: true)
        }
        
        editorVC.onClose = { [weak editorVC] in
            editorVC?.dismiss(animated: true)
        }
        editorVC.modalPresentationStyle = .fullScreen
        vc.present(editorVC, animated: true)
    }
}
