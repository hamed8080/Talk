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

@MainActor
public final class AttachmentFileCell: UITableViewCell {
    public var viewModel: ThreadViewModel!
    public var attachment: AttachmentFile!
    private let hStack = UIStackView()
    private let imgIcon = PaddingUIImageView()
    private let lblTitle = UILabel()
    private let lblSubtitle = UILabel()
    private let imgIcloudDonwloading = PaddingUIImageView()
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

        lblTitle.font = UIFont.fBoldBody
        lblTitle.textColor = Color.App.textPrimaryUIColor
        lblTitle.accessibilityIdentifier = "lblTitleAttachmentFileCell"

        lblSubtitle.font = UIFont.fCaption3
        lblSubtitle.textColor = Color.App.textSecondaryUIColor
        lblSubtitle.accessibilityIdentifier = "lblSubtitleAttachmentFileCell"

        btnRemove.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "xmark")
        btnRemove.setImage(image, for: .normal)
        btnRemove.tintColor = Color.App.textSecondaryUIColor
        btnRemove.accessibilityIdentifier = "btnRemoveAttachmentFileCell"
        btnRemove.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        
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
}
