//
//  MessageLocationView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import Chat

final class MessageLocationView: UIImageView {
    private weak var viewModel: MessageRowViewModel?
    private var mapViewHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 6
        layer.masksToBounds = true
        contentMode = .scaleAspectFill

        mapViewHeightConstraint = heightAnchor.constraint(equalToConstant: 0)
        mapViewHeightConstraint.identifier = "mapViewHeightConstraintMessageLocationView"

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onTap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 340),
            mapViewHeightConstraint
        ])
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        let message = viewModel?.message
        if let url = message?.neshanURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        if let fileURL = viewModel.calMessage.fileURL {
            self.setImage(fileURL: fileURL)
        } else {
            self.image = viewModel.fileState.preloadImage ?? DownloadFileManager.mapPlaceholder
        }
        tintColor = viewModel.fileState.state == .completed ? .clear : .gray

        if mapViewHeightConstraint.constant != viewModel.calMessage.sizes.mapHeight {
            mapViewHeightConstraint.constant = viewModel.calMessage.sizes.mapHeight
        }
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        setImage(fileURL: viewModel.calMessage.fileURL, withAnimation: true)
    }

    private func setImage(fileURL: URL?, withAnimation: Bool = false) {
        Task { @AppBackgroundActor in
            if let scaledImage = fileURL?.imageScale(width: 800)?.image {
                await MainActor.run {
                    if withAnimation {
                        self.alpha = 0.0
                        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                            self.alpha = 1.0
                        }
                    }
                    self.image = UIImage(cgImage: scaledImage)
                }
            }
        }
    }
}
