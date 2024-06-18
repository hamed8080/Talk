//
//  EditMessagePlaceholderView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import ChatModels
import Combine

public final class EditMessagePlaceholderView: UIStackView {
    private let messageImageView = UIImageView()
    private let messageLabel = UILabel()
    private let nameLabel = UILabel()

    private weak var viewModel: ThreadViewModel?
    private var sendVM: SendContainerViewModel { viewModel?.sendContainerViewModel ?? .init() }
    private var cancellable: AnyCancellable?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 8)
        isLayoutMarginsRelativeArrangement = true

        nameLabel.font = UIFont.uiiransansBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1

        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.alignment = .leading
        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(messageLabel)

        let staticImageReply = UIImageButton(imagePadding: .init(all: 8))
        staticImageReply.isUserInteractionEnabled = false
        staticImageReply.imageView.image = UIImage(systemName: "pencil")
        staticImageReply.translatesAutoresizingMaskIntoConstraints = false
        staticImageReply.imageView.tintColor = Color.App.accentUIColor
        staticImageReply.contentMode = .scaleAspectFit

        messageImageView.layer.cornerRadius = 4
        messageImageView.layer.masksToBounds = true
        messageImageView.contentMode = .scaleAspectFit
        messageImageView.translatesAutoresizingMaskIntoConstraints = true
        messageImageView.isHidden = true

        let closeButton = CloseButtonView()
        closeButton.action = { [weak self] in
            self?.close()
        }

        addArrangedSubview(staticImageReply)
        addArrangedSubview(messageImageView)
        addArrangedSubview(vStack)
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            messageImageView.widthAnchor.constraint(equalToConstant: 36),
            messageImageView.heightAnchor.constraint(equalToConstant: 36),
            staticImageReply.widthAnchor.constraint(equalToConstant: 36),
            staticImageReply.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    public func set() {
        let editMessage = sendVM.getEditMessage()
        let showEdit = editMessage != nil
        alpha = showEdit ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) {
            self.alpha = showEdit ? 1.0 : 0.0
            self.isHidden = !showEdit
        }

        let iconName = editMessage?.iconName
        let isFileType = editMessage?.isFileType == true
        let isImage = editMessage?.isImage == true
        messageImageView.layer.cornerRadius = isImage ? 4 : 16
        messageLabel.text = editMessage?.message ?? ""
        nameLabel.text = editMessage?.participant?.name
        nameLabel.isHidden = editMessage?.participant?.name == nil

        if isImage, let image = viewModel?.historyVM.sections.messageViewModel(for: editMessage?.uniqueId ?? "")?.calMessage.fileURL?.imageScale(width: 36)?.image {
            messageImageView.image = UIImage(cgImage: image)
            messageImageView.isHidden = false
        } else if isFileType, let iconName = iconName {
            messageImageView.image = UIImage(systemName: iconName)
            messageImageView.isHidden = false
        } else {
            messageImageView.image = nil
            messageImageView.isHidden = true
        }
    }

    private func animateEditPlaceholderIfNeeded() {
        let isInEditMode = viewModel?.sendContainerViewModel.isInEditMode == true
        if isInEditMode {
            set()
        }

        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.isHidden = !isInEditMode
        }
    }

    private func close() {
        viewModel?.sendContainerViewModel.setEditMessage(message: nil)
        viewModel?.delegate?.openEditMode(nil) // close the UI and show normal send buttons
        viewModel?.scrollVM.disableExcessiveLoading()
        sendVM.clear()
    }
}

struct EditMessagePlaceholderView_Previews: PreviewProvider {
    struct EditMessagePlaceholderViewWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel
        func makeUIView(context: Context) -> some UIView { EditMessagePlaceholderView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.sendContainerViewModel.setEditMessage(message: .init(threadId: 1,
                                                                 message: "Test message", messageType: .text,
                                                                 participant: .init(name: "John Doe")))
            return viewModel
        }

        var body: some View {
            EditMessagePlaceholderViewWrapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
