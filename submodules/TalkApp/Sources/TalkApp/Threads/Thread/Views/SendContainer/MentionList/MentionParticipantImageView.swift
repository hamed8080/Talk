//
//  MentionParticipantImageView.swift
//  Talk
//
//  Created by hamed on 6/8/24.
//

import Foundation
import UIKit
import TalkViewModels
import SwiftUI
import Chat

public final class MentionParticipantImageView: UIView {
    public var imageLoaderVM: ImageLoaderViewModel?
    private let participantLabel = UILabel()
    private let imageIconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.masksToBounds = true

        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.contentMode = .scaleAspectFill
        imageIconView.accessibilityIdentifier = "imageIconViewMentionParticipantImageView"

        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.textAlignment = .center
        participantLabel.accessibilityIdentifier = "participantLabelMentionParticipantImageView"
        participantLabel.font = UIFont.normal(.caption3)
        backgroundColor = Color.App.bgIconUIColor

        addSubview(imageIconView)
        addSubview(participantLabel)

        NSLayoutConstraint.activate([
            imageIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            participantLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            participantLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageIconView.widthAnchor.constraint(equalTo: widthAnchor),
            imageIconView.heightAnchor.constraint(equalTo: heightAnchor),
            participantLabel.widthAnchor.constraint(equalTo: widthAnchor),
            participantLabel.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    public func setValues(vm: ImageLoaderViewModel?, participant: Participant) {
        self.imageLoaderVM = vm
        let isImageReady = imageLoaderVM?.isImageReady == true
        let userNameString = vm?.config.userName ?? ""

        imageIconView.image = imageLoaderVM?.image
        participantLabel.text = String(userNameString)
        participantLabel.setIsHidden(isImageReady)
        
        if !isImageReady {
            let color = String.getMaterialColorByCharCode(str: userNameString)
            imageIconView.backgroundColor = color
            imageIconView.image = nil
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}
