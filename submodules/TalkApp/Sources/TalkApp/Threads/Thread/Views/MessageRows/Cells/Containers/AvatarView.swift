//
//  AvatarView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import SwiftUI
import TalkViewModels

final class AvatarView: UIImageView {
    private let label = UILabel()
    private weak var viewModel: MessageRowViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = true
        backgroundColor = Color.App.color1UIColor?.withAlphaComponent(0.4)
        layer.cornerRadius = ConstantSizes.messageAvatarViewSize / 2
        layer.masksToBounds = true
        contentMode = .scaleAspectFill
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.normal(.caption)
        label.textColor = Color.App.whiteUIColor
        label.textAlignment = .center
        label.backgroundColor = Color.App.color1UIColor?.withAlphaComponent(0.4)
        label.layer.cornerRadius = ConstantSizes.messageAvatarViewSize / 2
        label.layer.masksToBounds = true
        label.accessibilityIdentifier = "labelAvatarView"
        addSubview(label)
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: ConstantSizes.messageAvatarViewSize),
            heightAnchor.constraint(equalToConstant: ConstantSizes.messageAvatarViewSize),
            label.widthAnchor.constraint(equalToConstant: ConstantSizes.messageAvatarViewSize),
            label.heightAnchor.constraint(equalToConstant: ConstantSizes.messageAvatarViewSize),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let avManager = viewModel.threadVM?.avatarManager
        label.setIsHidden(true) // reset
        if hiddenView(viewModel) {
            backgroundColor = nil
            image = nil
            isUserInteractionEnabled = false
            setIsHidden(true)
        } else if viewModel.calMessage.isLastMessageOfTheUser {
            Task { [weak self] in
                guard let self = self else { return }
                if let image = await avManager?.getImage(viewModel) {
                    setImage(image: image)
                } else {
                    backgroundColor = viewModel.calMessage.avatarColor
                    image = nil
                    label.isHidden = false
                    label.text = viewModel.calMessage.avatarSplitedCharaters
                }
                isUserInteractionEnabled = true
                setIsHidden(false)
            }
        } else if !viewModel.calMessage.isLastMessageOfTheUser {
            image = nil
            backgroundColor = nil
            label.isHidden = true
            isUserInteractionEnabled = false
            setIsHidden(false)
        }
    }

    private func hiddenView(_ viewModel: MessageRowViewModel) -> Bool {
        let isChannel = viewModel.threadVM?.thread.type?.isChannelType == true
        if isChannel { return true }
        let isInSelectMode = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == true
        return isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false
    }

    @objc func onTap(_ sender: UIGestureRecognizer) {
        if let participant = viewModel?.message.participant {
            AppState.shared.objectsContainer.navVM.resetNavigationProperties()
            Task {
                try await AppState.shared.objectsContainer.navVM.openThread(participant: participant)
            }
        }
    }

    public func updateSelectionMode() {
        if viewModel?.threadVM?.thread.group == false { return }
        let isInSelectionMode = viewModel?.threadVM?.selectedMessagesViewModel.isInSelectMode == true
        if isInSelectionMode {
            setIsHidden(true)
        } else if !isInSelectionMode {
            setIsHidden(false)
        }
    }

    public func setImage(image: UIImage) {
        guard viewModel?.calMessage.isLastMessageOfTheUser == true else { return }
        self.image = image
        label.isHidden = true
    }
}
