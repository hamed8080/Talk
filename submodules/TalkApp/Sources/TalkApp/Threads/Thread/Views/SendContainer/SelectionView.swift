//
//  SelectionView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

public final class SelectionView: UIStackView {
    // Views
    private let btnDelete = UIImageButton(imagePadding: .init(all: 10))
    private let lblCount = UILabel()
    private let lblStatic = UILabel()
    let btnForward = UIImageButton(imagePadding: .init(all: 10))
    
    // Models
    private weak var viewModel: ThreadViewModel?

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
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        let image = UIImage(systemName: "arrow.turn.up.right")
        btnForward.imageView.image = image
        btnForward.imageView.image = image
        btnForward.imageView.contentMode = .scaleAspectFit
        btnForward.imageView.tintColor = Color.App.accentUIColor
        btnForward.translatesAutoresizingMaskIntoConstraints = false
        btnForward.accessibilityIdentifier = "btnForwardSelectionView"
        btnForward.action = { [weak self] in
            self?.forwardSelectedMessageTapped()
        }
        addArrangedSubview(btnForward)

        lblCount.font = UIFont.fBoldBody
        lblCount.textColor = Color.App.accentUIColor
        lblCount.accessibilityIdentifier = "lblCountSelectionView"
        addArrangedSubview(lblCount)

        lblStatic.text = "General.selected".bundleLocalized()
        lblStatic.font = UIFont.fBody
        lblStatic.textColor = Color.App.textPrimaryUIColor
        lblStatic.accessibilityIdentifier = "lblStaticSelectionView"
        addArrangedSubview(lblStatic)

        let spacer = UIView(frame: .init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))
        spacer.accessibilityIdentifier = "spacerSelectionView"
        addArrangedSubview(spacer)

        btnDelete.translatesAutoresizingMaskIntoConstraints = false
        btnDelete.imageView.image = UIImage(named: "ic_delete")
        btnDelete.imageView.contentMode = .scaleAspectFit
        btnDelete.imageView.tintColor = Color.App.iconSecondaryUIColor
        btnDelete.accessibilityIdentifier = "btnDeleteSelectionView"
        btnDelete.action = { [weak self] in
            self?.deleteSelectedMessageTapped()
        }
        addArrangedSubview(btnDelete)

        let closeButton = CloseButtonView()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.accessibilityIdentifier = "closeButtonSelectionView"
        closeButton.action = { [weak self] in
            self?.onClose()
        }
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            btnForward.widthAnchor.constraint(equalToConstant: 42),
            btnForward.heightAnchor.constraint(equalToConstant: 42),
            btnDelete.widthAnchor.constraint(equalToConstant: 42),
            btnDelete.heightAnchor.constraint(equalToConstant: 42),
            closeButton.widthAnchor.constraint(equalToConstant: 42),
            closeButton.heightAnchor.constraint(equalToConstant: 42),
        ])
    }

    private func forwardSelectedMessageTapped() {
        viewModel?.delegate?.openForwardPicker()
    }

    private func deleteSelectedMessageTapped() {
        guard let viewModel = viewModel else { return }
        Task { [weak self] in
            guard let self = self else { return }
            let deleteVM = DeleteMessagesViewModelModel()
            await deleteVM.setup(viewModel: viewModel)
            let dialog = DeleteMessageDialog(viewModel: deleteVM)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
        }
    }

    private func set(stack: UIStackView) {
        guard let viewModel = viewModel else { return }
        stack.insertArrangedSubview(self, at: 0)
        setIsHidden(false)
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
        btnDelete.setIsHidden(viewModel.thread.disableSend)
        updateCount()
    }

    private func updateCount() {
        guard let viewModel = viewModel else { return }
        let count = viewModel.selectedMessagesViewModel.getSelectedMessages().count
        lblCount.addFlipAnimation(text: count.localNumber(locale: Language.preferredLocale) ?? "")
        btnForward.isUserInteractionEnabled = count > 0
        btnForward.alpha = count > 0 ? 1.0 : 0.5
        btnDelete.isUserInteractionEnabled = count > 0
        btnDelete.alpha = count > 0 ? 1.0 : 0.5
    }

    private func onClose() {
        lblCount.text = ""
        viewModel?.delegate?.setSelection(false)
        viewModel?.selectedMessagesViewModel.clearSelection()
        removeFromSuperViewWithAnimation()
    }

    public func update(stack: UIStackView) {
        if self.superview == nil {
            set(stack: stack) // attach it to the view
        }
        updateCount()
    }

    public func show(show: Bool, stack: UIStackView) {
        if show {
            alpha = 1.0
            set(stack: stack)
        } else {
            removeFromSuperViewWithAnimation()
        }
    }
}
