//
//  MessageLocationView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import Chat

@MainActor
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
        layer.cornerRadius = ConstantSizes.messageLocationCornerRadius
        layer.masksToBounds = true
        contentMode = .scaleAspectFill
        
        mapViewHeightConstraint = heightAnchor.constraint(equalToConstant: 0)
        mapViewHeightConstraint.identifier = "mapViewHeightConstraintMessageLocationView"
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onTap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: ConstantSizes.messageLocationViewMinWidth),
            mapViewHeightConstraint
        ])
    }
    
    @objc private func onTap(_ sender: UIGestureRecognizer) {
        let message = viewModel?.message
        if let url = message?.neshanURL(basePath: AppState.shared.spec.server.neshan), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let mapLink = message?.fileMetaData?.mapLink, let url = URL(string: mapLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        if let fileURL = viewModel.calMessage.fileURL {
            Task { [weak self] in
                guard let self = self else { return }
                await self.setImage(fileURL: fileURL)
            }
        } else {
            self.image = viewModel.fileState.preloadImage ?? DownloadFileStateMediator.mapPlaceholder
        }
        
        if viewModel.fileState.state != .completed {
            automaticDownloadImage()
        }
        
        tintColor = viewModel.fileState.state == .completed ? .clear : .gray
        
        if mapViewHeightConstraint.constant != ConstantSizes.messageLocationHeight {
            mapViewHeightConstraint.constant = ConstantSizes.messageLocationHeight
        }
    }
    
    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isMap { return }
        Task { [weak self] in
            guard let self = self else { return }
            await setImage(fileURL: viewModel.calMessage.fileURL, withAnimation: true)
        }
    }
    
    private func setImage(fileURL: URL?, withAnimation: Bool = false) async {
        if let fileURL = fileURL, let scaledImage = await scaledImage(url: fileURL) {
            if withAnimation {
                self.alpha = 0.0
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                    self.alpha = 1.0
                }
            }
            self.image = scaledImage
        }
    }
    
    @AppBackgroundActor
    private func scaledImage(url: URL) async -> UIImage? {
        if let scaledImage = url.imageScale(width: 800)?.image {
            return UIImage(cgImage: scaledImage)
        }
        return nil
    }
    
    private func automaticDownloadImage() {
        if let message = viewModel?.message as? Message {
            AppState.shared.objectsContainer.downloadsManager.toggleDownloading(message: message)
        }
    }
}
