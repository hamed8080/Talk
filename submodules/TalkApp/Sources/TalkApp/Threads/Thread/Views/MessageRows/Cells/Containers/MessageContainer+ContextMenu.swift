//
//  MessageContainerStackView+ContextMenu.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import TalkViewModels
import Chat

fileprivate struct Constants {
    static let space: CGFloat = 8
    static let margin: CGFloat = 8
    static let menuWidth: CGFloat = 256
    static let reactionHeight: CGFloat = 50
    static let scaleDownOnTouch: CGFloat = 0.98
    static let scaleDownAnimationDuration = 0.2
    static let scaleUPAnimationDuration = 0.1
    static let longPressDuration = 0.3
    static let animateToRightVerticalPosition = 0.1
    static let animateToHideOriginalMessageDuration = 0.4
}

@MainActor
extension MessageContainerStackView {
    func addMenus() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = Constants.longPressDuration
        addGestureRecognizer(longGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTapped))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func onDoubleTapped() {
        if let action = AppSettingsModel.restore().doubleTapAction {
            switch action {
            case .reply:
                viewModel?.threadVM?.delegate?.openReplyMode(viewModel?.message)
                break
            case .specialEmoji(let sticker):
                if let messageId = viewModel?.message.id {
                    let myRow = viewModel?.reactionsModel.rows.first(where: {$0.isMyReaction})
                    viewModel?.threadVM?.reactionViewModel.reaction(sticker, messageId: messageId, myReactionId: myRow?.myReactionId, myReactionSticker: myRow?.sticker)
                }
                break
            default:
                break
            }
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: Constants.scaleDownAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: Constants.scaleDownOnTouch, y: Constants.scaleDownOnTouch)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: Constants.scaleUPAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: Constants.scaleUPAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
    
    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        if viewModel?.threadVM?.thread.closed == true { return }
        let isBegin = sender.state == .began
        openContextAsync(isBegin)
    }
    
    private func openContextAsync(_ isBegin: Bool)  {
        if isBegin, let indexPath = indexpath(), let contentView = makeContextMenuView(indexPath) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            viewModel?.threadVM?.delegate?.showContextMenu(indexPath, contentView: contentView)
            UIView.animate(withDuration: Constants.animateToHideOriginalMessageDuration) {
                self.alpha = 0.0
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        }
    }
    
    func makeContextMenuView(_ indexPath: IndexPath) -> UIView? {
        guard let viewModel = viewModel else { return nil }
        let messsageStackContainer =  MessageContextMenuContentView(frame: .zero,
                                             messageWidth: cell?.messageContainer.bounds.width ?? 0,
                                             viewModel: viewModel,
                                             indexPath: indexPath,
                                             cell: cell,
                                             resetOnDismiss: resetOnDismiss,
                                             userInterfaceStyle: traitCollection.userInterfaceStyle)

        return messsageStackContainer
    }
    
    private func indexpath() -> IndexPath? {
        guard
            let vm = viewModel,
            let indexPath = viewModel?.threadVM?.historyVM.sectionsHolder.sections.indexPath(for: vm)
        else { return nil }
        return indexPath
    }
    
    public func resetOnDismiss() {
        UIView.animate(withDuration: Constants.scaleUPAnimationDuration) {
            self.alpha = 1.0
        }
    }
}

fileprivate class MessageContextMenuContentView: UIView {
    private var reactionsView = UIReactionsPickerScrollView(size: Constants.reactionHeight)
    private let messageContainer: MessageContainerStackView
    private var menu = CustomMenu()
    private let viewModel: MessageRowViewModel
    private let indexPath: IndexPath
    private let messageWidth: CGFloat
    private weak var cell: MessageBaseCell?
    private var reactionHeightConstraint = NSLayoutConstraint()
    private let userInterfaceStyle: UIUserInterfaceStyle
    private var topConstraint: NSLayoutConstraint?
    
    init(frame: CGRect,
         messageWidth: CGFloat,
         viewModel: MessageRowViewModel,
         indexPath: IndexPath,
         cell: MessageBaseCell?,
         resetOnDismiss: @escaping () -> Void,
         userInterfaceStyle: UIUserInterfaceStyle) {
        self.indexPath = indexPath
        self.viewModel = viewModel
        self.messageWidth = messageWidth
        self.cell = cell
        let messageContainer = MessageContainerStackView(frame: .zero, isMe: viewModel.calMessage.isMe)
        messageContainer.cell = cell
        self.menu = messageContainer.menu(model: .init(viewModel: viewModel), indexPath: indexPath, onMenuClickedDismiss: resetOnDismiss)
        self.messageContainer = messageContainer
        self.userInterfaceStyle = userInterfaceStyle
        super.init(frame: frame)
        configureView()
    }
    
    private func configureReactionView()  {
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        reactionsView.setup(viewModel)
        reactionsView.overrideUserInterfaceStyle = userInterfaceStyle
        let canReact = viewModel.canReact()
        reactionsView.isUserInteractionEnabled = canReact
        reactionsView.isHidden = !canReact
        reactionsView.onExpandModeChanged = { [weak self] expandMode in
            guard let self = self else { return }
             UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1) { [weak self] in
                 guard let self = self else { return }
                 reactionHeightConstraint.constant = expandMode ? reactionsView.expandHeight() : reactionViewInitialHeight()
                 layoutIfNeeded()
            }
        }
        addSubview(reactionsView)
    }
    
    private func configureMessageStackContainer() {
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.set(viewModel)
        messageContainer.prepareForContextMenu(userInterfaceStyle: userInterfaceStyle)
        messageContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(faketapGesture)))
        addSubview(messageContainer)
    }
    
    private func configureMenu() {
        menu.translatesAutoresizingMaskIntoConstraints = false
        addSubview(menu)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        bringSubviewToFront(reactionsView) // Expand mode in reactions
        
        configureReactionView()
        configureMessageStackContainer()
        configureMenu()
        
        reactionHeightConstraint = reactionsView.heightAnchor.constraint(equalToConstant: reactionViewInitialHeight())
        
        /// This delay will fix a crash when a user opens up the context menu fast.
        /// Do not use safeAreaLayoutGuide.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.topConstraint?.constant = self.safeAreaInsets.top + 16
        }
        topConstraint = reactionsView.topAnchor.constraint(equalTo: topAnchor, constant: 28)
        topConstraint?.isActive = true
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: menu.bottomAnchor, constant: 46),
            
            // ReactionsView
            reactionsView.widthAnchor.constraint(equalToConstant: 320),
            reactionHeightConstraint,
            
            // MessageContainerView
            messageContainer.widthAnchor.constraint(equalToConstant: messageWidth),
            messageContainer.topAnchor.constraint(equalTo: reactionsView.bottomAnchor, constant: 8),
            
            // Menu
            menu.widthAnchor.constraint(equalToConstant: Constants.menuWidth),
            menu.heightAnchor.constraint(equalToConstant: menu.height()),
            menu.topAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: 8)
        ])
        
        let myConstraints = [
            messageContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            reactionsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            menu.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
        ]
        let partnerConstraints: [NSLayoutConstraint] = [
            reactionsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            menu.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ]
        
        NSLayoutConstraint.activate(viewModel.calMessage.isMe ? myConstraints : partnerConstraints)
        
        addAnimation(reactionsView)
        addAnimation(messageContainer)
        addAnimation(menu)
    }
    
    private func addAnimation(_ view: UIView) {
        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.fromValue = 0.2
        fadeAnim.toValue = 1.0
        fadeAnim.duration = 0.25
        fadeAnim.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        view.layer.add(fadeAnim, forKey: "opacity")
        
        let springAnim = CASpringAnimation(keyPath: "transform.scale")
        springAnim.mass = 0.8
        springAnim.damping = 10
        springAnim.stiffness = 100
        springAnim.duration = 0.25
        springAnim.fromValue = 0
        springAnim.toValue = 1
        view.layer.add(springAnim, forKey: "springAnim")
    }
    
    @objc private func faketapGesture(_ sender: UIGestureRecognizer) {
        sender.cancelsTouchesInView = true
    }
    
    private func reactionViewInitialHeight() -> CGFloat {
        return Constants.reactionHeight + (allowedReactions().count < 4 ? 4.0 : 0.0)
    }
    
    private func allowedReactions() -> [Sticker] {
        if viewModel.threadVM?.thread.reactionStatus == .enable { return Sticker.allCases.filter({ $0 != .unknown}) }
        return viewModel.threadVM?.reactionViewModel.allowedReactions ?? []
    }
}
