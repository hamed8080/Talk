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

final class MessageImageView: UIImageView {
    // Views
    private let stack = UIStackView()
    private let fileSizeLabel = UILabel()
    private var effectView: UIVisualEffectView!
    private let progressView = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                    iconTint: Color.App.whiteUIColor,
                                                    iconSize: .init(width: 12, height: 12),
                                                    margin: 2)

    // Models
    private weak var viewModel: MessageRowViewModel?

    // Constraints
    private var widthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!

    // Sizes
    private let progessSize: CGFloat = 20

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
        contentMode = .scaleAspectFit
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.accessibilityIdentifier = "progressViewMessageImageView"
        progressView.setContentHuggingPriority(.required, for: .horizontal)
        progressView.setContentHuggingPriority(.required, for: .vertical)

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.frame = bounds
        effectView.isUserInteractionEnabled = false
        effectView.accessibilityIdentifier = "effectViewMessageImageView"

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.uiiransansFootnote
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageImageView"

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.addArrangedSubview(progressView)
        stack.addArrangedSubview(fileSizeLabel)
        stack.backgroundColor = .white.withAlphaComponent(0.2)
        stack.layoutMargins = .init(horizontal: 4, vertical: 4)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layer.cornerRadius = 14
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
            progressView.widthAnchor.constraint(equalToConstant: progessSize),
            progressView.heightAnchor.constraint(equalToConstant: progessSize),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let state = viewModel.fileState.state
        let canShow = state != .completed
        if let fileURL = viewModel.calMessage.fileURL {
            setImage(fileURL: fileURL)
        } else {
            setPreloadImage(viewModel: viewModel)
        }

        attachOrDetachEffectView(canShow: canShow)
        attachOrDetachProgressView(canShow: canShow)
        updateProgress(viewModel: viewModel)
        if viewModel.calMessage.computedFileSize != fileSizeLabel.text {
            fileSizeLabel.text = viewModel.calMessage.computedFileSize
        }

        widthConstraint.constant = (viewModel.calMessage.sizes.imageWidth ?? 128) - 8 // -8 for parent stack view margin
        heightConstraint.constant = viewModel.calMessage.sizes.imageHeight ?? 128
    }

    private func attachOrDetachEffectView(canShow: Bool) {
        if canShow, effectView.superview == nil {
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

    private func attachOrDetachProgressView(canShow: Bool) {
        if canShow, stack.superview == nil {
            addSubview(stack)
            stack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            stack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        } else if !canShow {
            stack.removeFromSuperview()
        }
    }

    private func setImage(fileURL: URL) {
        Task { @HistoryActor in
            if let scaledImage = fileURL.imageScale(width: 300)?.image {
                let image = scaledImage
                await MainActor.run {
                    self.image = UIImage(cgImage: image)
                }
            }
        }
    }

    // Thumbnail or placeholder image
    private func setPreloadImage(viewModel: MessageRowViewModel) {
        if viewModel.fileState.state == .undefined {
            self.image = DownloadFileManager.emptyImage
        }
        guard let image = viewModel.fileState.preloadImage else { return }
        self.image = image
    }

    @objc func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.fileState.progress
        progressView.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        progressView.setProgressVisibility(visible: canShowProgress)
    }

    public func updateThumbnail(viewModel: MessageRowViewModel) {
        setPreloadImage(viewModel: viewModel)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if let fileURL = viewModel.calMessage.fileURL {
            updateProgress(viewModel: viewModel)
            attachOrDetachProgressView(canShow: false)
            attachOrDetachEffectView(canShow: false)
            setImage(fileURL: fileURL)
        }
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        if let fileURL = viewModel.calMessage.fileURL {
            updateProgress(viewModel: viewModel)
            attachOrDetachProgressView(canShow: false)
            attachOrDetachEffectView(canShow: false)
            setImage(fileURL: fileURL)
        }
    }

    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }
}
