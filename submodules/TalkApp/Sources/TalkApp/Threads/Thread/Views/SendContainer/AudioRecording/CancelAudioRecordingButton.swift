//
//  CancelAudioRecordingButton.swift
//  Talk
//
//  Created by hamed on 7/21/24.
//

import Foundation
import TalkViewModels
import UIKit
import TalkUI
import SwiftUI

final class CancelAudioRecordingButton: UIView {
    private let btnCancel = UIImageButton(imagePadding: .init(all: 8))
    private weak var viewModel: ThreadViewModel?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configure()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        btnCancel.translatesAutoresizingMaskIntoConstraints = false
        btnCancel.imageView.image = UIImage(systemName: "xmark")
        btnCancel.imageView.contentMode = .scaleAspectFit
        btnCancel.imageView.tintColor = Color.App.accentUIColor
        btnCancel.backgroundColor = Color.App.bgPrimaryUIColor
        btnCancel.layer.cornerRadius = 16
        btnCancel.layer.masksToBounds = true
        btnCancel.action = { [weak self] in
            self?.viewModel?.audioRecoderVM.cancel()
            self?.viewModel?.delegate?.showRecording(false)
        }
        addSubview(btnCancel)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 32),
            heightAnchor.constraint(equalToConstant: 32),
            btnCancel.leadingAnchor.constraint(equalTo: leadingAnchor),
            btnCancel.trailingAnchor.constraint(equalTo: trailingAnchor),
            btnCancel.topAnchor.constraint(equalTo: topAnchor),
            btnCancel.bottomAnchor.constraint(equalTo: bottomAnchor),
            btnCancel.widthAnchor.constraint(equalToConstant: 32),
            btnCancel.heightAnchor.constraint(equalToConstant: 32),
        ])
    }
}
