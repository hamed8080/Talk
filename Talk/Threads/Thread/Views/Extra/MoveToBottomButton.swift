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

public final class MoveToBottomButton: UIButton {
    public weak var viewModel: ThreadViewModel?
    private let imgCenter = UIImageView()
    private let lblUnreadCount = PaddingUILabel(frame: .zero, horizontal: 4, vertical: 4)

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
        layer.backgroundColor = Color.App.bgPrimaryUIColor?.cgColor
        backgroundColor = Color.App.bgPrimaryUIColor
        layer.cornerRadius = 20
        layer.shadowRadius = 5
        layer.shadowColor = Color.App.accentUIColor?.cgColor
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        layer.shadowOffset = .init(width: 0.0, height: 1.0)
        let readAllMeessges = viewModel?.thread.lastMessageVO?.id ?? -1 == viewModel?.thread.lastSeenMessageId ?? 0
        isHidden = readAllMeessges

        imgCenter.image = UIImage(systemName: "chevron.down")
        imgCenter.translatesAutoresizingMaskIntoConstraints = false
        imgCenter.contentMode = .scaleAspectFit
        imgCenter.tintColor = Color.App.accentUIColor
        addSubview(imgCenter)

        lblUnreadCount.translatesAutoresizingMaskIntoConstraints = false
        lblUnreadCount.textColor = Color.App.whiteUIColor
        lblUnreadCount.font = .uiiransansBoldCaption
        lblUnreadCount.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        lblUnreadCount.layer.cornerRadius = 12
        lblUnreadCount.textAlignment = .center
        lblUnreadCount.numberOfLines = 1

        addSubview(lblUnreadCount)

        NSLayoutConstraint.activate([
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

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        setIsHidden(true)
        viewModel?.scrollVM.scrollToBottom()
    }

    public func updateUnreadCount() {
        lblUnreadCount.isHidden = viewModel?.thread.unreadCount == 0 || viewModel?.thread.unreadCount == nil
        lblUnreadCount.text = viewModel?.thread.unreadCountString ?? ""
    }

    public func setVisibility(visible: Bool) {
        DispatchQueue.main.async {
            if visible {
                self.setIsHidden(false)
            }
            self.transform = CGAffineTransform(scaleX: visible ? 0.01 : 1.0, y: visible ? 0.01 : 1.0)
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.transform = CGAffineTransform(scaleX: visible ? 1.0 : 0.01, y: visible ? 1.0 : 0.01)
            } completion: { completed in
                if completed {
                    self.setIsHidden(!visible)
                }
            }
        }
    }
}
