//
//  MessageImageView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import Chat

@MainActor
final class MessageImageView: UIImageView {
    // Views
    private let stack = UIStackView()
    private let fileSizeLabel = UILabel()
    private var effectView: UIVisualEffectView!
    private let progressView = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                    iconTint: Color.App.whiteUIColor,
                                                    iconSize: .init(width: 14, height: 14),
                                                    margin: 2)

    // Models
    private weak var viewModel: MessageRowViewModel?

    // Constraints
    private var widthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!

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
        layer.cornerRadius = ConstantSizes.messageImageViewCornerRadius
        layer.masksToBounds = true
        contentMode = .scaleAspectFit
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.accessibilityIdentifier = "progressViewMessageImageView"
        progressView.setContentHuggingPriority(.required, for: .horizontal)
        progressView.setContentHuggingPriority(.required, for: .vertical)

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.frame = bounds
        effectView.isUserInteractionEnabled = false
        effectView.accessibilityIdentifier = "effectViewMessageImageView"

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.fBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageImageView"

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = ConstantSizes.messageImageViewStackSpacing
        stack.addArrangedSubview(progressView)
        stack.addArrangedSubview(fileSizeLabel)
        stack.backgroundColor = .white.withAlphaComponent(0.2)
        stack.layoutMargins = .init(horizontal: ConstantSizes.messageImageViewStackLayoutMarginSize, vertical: ConstantSizes.messageImageViewStackLayoutMarginSize)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layer.cornerRadius = ConstantSizes.messageImageViewStackCornerRadius
        stack.isUserInteractionEnabled = false
        stack.accessibilityIdentifier = "stackMessageImageView"

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tapGesture)

        widthConstraint = widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.identifier = "widthConstraintMessageImageView"
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.identifier = "heightConstraintMessageImageView"

        NSLayoutConstraint.activate([
            widthConstraint,
            heightConstraint,
            progressView.widthAnchor.constraint(equalToConstant: ConstantSizes.messageImageViewProgessSize),
            progressView.heightAnchor.constraint(equalToConstant: ConstantSizes.messageImageViewProgessSize),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let canShow = viewModel.fileState.state != .completed
        if let fileURL = viewModel.calMessage.fileURL {
            Task { [weak self] in
                guard let self = self else { return }
                await setImage(fileURL: fileURL)
            }
        } else {
            setPreloadImage(viewModel: viewModel)
        }

        attachOrDetachEffectView(canShow: canShow)
        attachOrDetachProgressView(canShow: canShow)
        updateProgress(viewModel: viewModel)
        if viewModel.calMessage.computedFileSize != fileSizeLabel.text {
            fileSizeLabel.text = viewModel.calMessage.computedFileSize
        }

        widthConstraint.constant = (viewModel.calMessage.sizes.imageWidth ?? 0) - 8 // -8 for parent stack view margin
        heightConstraint.constant = viewModel.calMessage.sizes.imageHeight ?? 128
    }

    private func attachOrDetachEffectView(canShow: Bool) {
        if canShow, effectView.superview == nil {
            effectView.layer.opacity = 1.0
            addSubview(effectView)
            bringSubviewToFront(effectView)
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            effectView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            effectView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            effectView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        } else if !canShow {
            effectView.removeFromSuperview()
        }
    }
    
    private func removeEffectViewByHidingAnimation() {
        effectView.layer.opacity = 1.0
        UIView.animate(withDuration: 0.5) {
            self.effectView.layer.opacity = 0.0
        } completion: { completed in
            if completed {
                self.effectView.removeFromSuperview()
            }
        }
    }
    
    private func removeProgressViewByHidingAnimation() {
        stack.layer.opacity = 1.0
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut]) {
            self.stack.layer.opacity = 0.0
        } completion: { completed in
            if completed {
                self.stack.removeFromSuperview()
            }
        }
    }

    private func attachOrDetachProgressView(canShow: Bool) {
        if canShow, stack.superview == nil {
            stack.layer.opacity = 1.0
            addSubview(stack)
            stack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            stack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        } else if !canShow {
            stack.removeFromSuperview()
        }
    }

    private func setImage(fileURL: URL, animate: Bool = false) async {
        if let scaledImage = await scaledImage(url: fileURL) {
            let image = scaledImage
            if animate {
                UIView.transition(with: self, duration: 0.5, options: .transitionCrossDissolve) {
                    self.image = image
                }
            } else {
                self.image = image
            }
        }
    }
    
    @AppBackgroundActor
    private func scaledImage(url: URL) async -> UIImage? {
        if let scaledImage = url.imageScale(width: 300)?.image {
            return UIImage(cgImage: scaledImage)
        }
        return nil
    }

    // Thumbnail or placeholder image
    private func setPreloadImage(viewModel: MessageRowViewModel) {
        if viewModel.fileState.state == .undefined {
            self.image = DownloadFileStateMediator.emptyImage
        }
        
        if let image = viewModel.fileState.preloadImage {
            self.image = image
        } else {
            Task { [weak self] in
                guard let self = self else { return }
                let image = await viewModel.downloadThumbnailImage()
                self.image = image
            }
        }
        attachOrDetachEffectView(canShow: true)
        attachOrDetachProgressView(canShow: true)
    }

    @objc func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isImage { return }
        let progress = viewModel.fileState.progress
        progressView.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        progressView.setProgressVisibility(visible: canShowProgress)
        progressView.showRotation(show: canShowProgress)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isImage { return }
        if let fileURL = viewModel.calMessage.fileURL {
            updateProgress(viewModel: viewModel)
            removeProgressViewByHidingAnimation()
            removeEffectViewByHidingAnimation()
            Task { [weak self] in
                guard let self = self else { return }
                await setImage(fileURL: fileURL, animate: true)
            }
        }
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isImage { return }
        if let fileURL = viewModel.calMessage.fileURL {
            updateProgress(viewModel: viewModel)
            removeProgressViewByHidingAnimation()
            removeEffectViewByHidingAnimation()
            Task { [weak self] in
                guard let self = self else { return }
                await setImage(fileURL: fileURL)
            }
        }
    }

    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }
}
