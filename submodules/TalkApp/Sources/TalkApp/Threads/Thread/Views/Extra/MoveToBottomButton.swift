//
//  MoveToBottomButton.swift
//  Talk
//
//  Created by hamed on 7/7/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkExtensions
import TalkModels

@MainActor
public final class MoveToBottomButton: UIButton {
    public weak var viewModel: ThreadViewModel?
    private let imgCenter = UIImageView()
    private let lblUnreadCount = PaddingUILabel(frame: .zero, horizontal: 4, vertical: 4)
    private var animator: TransformAnimator?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
        updateUnreadCount()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        accessibilityIdentifier = "moveToBottomThreadViewController"
        layer.backgroundColor = Color.App.bgPrimaryUIColor?.cgColor
        backgroundColor = Color.App.bgPrimaryUIColor
        layer.cornerRadius = 20
        layer.shadowRadius = 5
        layer.shadowColor = Color.App.accentUIColor?.cgColor
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        layer.shadowOffset = .init(width: 0.0, height: 1.0)
        setIsHidden(true)

        imgCenter.image = UIImage(systemName: "chevron.down")
        imgCenter.translatesAutoresizingMaskIntoConstraints = false
        imgCenter.contentMode = .scaleAspectFit
        imgCenter.tintColor = Color.App.accentUIColor
        imgCenter.accessibilityIdentifier = "imgCenterMoveToBottomButton"
        addSubview(imgCenter)

        lblUnreadCount.translatesAutoresizingMaskIntoConstraints = false
        lblUnreadCount.label.textColor = Color.App.whiteUIColor
        lblUnreadCount.label.font = .fBoldCaption
        lblUnreadCount.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        lblUnreadCount.layer.cornerRadius = 12
        lblUnreadCount.label.textAlignment = .center
        lblUnreadCount.label.numberOfLines = 1
        lblUnreadCount.accessibilityIdentifier = "lblUnreadCountMoveToBottomButton"

        addSubview(lblUnreadCount)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 40),
            imgCenter.centerXAnchor.constraint(equalTo: centerXAnchor),
            imgCenter.centerYAnchor.constraint(equalTo: centerYAnchor),
            imgCenter.widthAnchor.constraint(equalToConstant: 20),
            imgCenter.heightAnchor.constraint(equalToConstant: 20),
            lblUnreadCount.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            lblUnreadCount.heightAnchor.constraint(equalToConstant: 24),
            lblUnreadCount.topAnchor.constraint(equalTo: topAnchor, constant: -16),
            lblUnreadCount.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        setIsHidden(true)
        viewModel?.historyVM.handleJumpToButtom()
    }

    public func updateUnreadCount() {
        let isArchive = viewModel?.thread.isArchive == true
        let threads = isArchive ?AppState.shared.objectsContainer.archivesVM.archives : viewModel?.threadsViewModel?.threads ?? []
        let thread = threads.first(where: {$0.id == viewModel?.threadId})
        let unreadCount = thread?.unreadCount ?? 0
        
        lblUnreadCount.setIsHidden(unreadCount == 0)
        self.lblUnreadCount.label.addFlipAnimation(text: thread?.unreadCountString)
    }
    
    public func show(_ show: Bool) {
        animator?.cancelAnimation()
        animator = TransformAnimator(view: self)
        animator?.startAnimation(show: show) { @Sendable [weak self] position in
            if position == .end {
                Task { @MainActor [weak self] in
                    if let self = self {
                        self.setIsHidden(!show)
                        self.isUserInteractionEnabled = show
                    }
                }
            }
        }
    }
}
