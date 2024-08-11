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
    static let reactionWidth: CGFloat = 320
    static let reactionHeight: CGFloat = 50
    static let scaleDownOnTouch: CGFloat = 0.98
    static let scaleDownAnimationDuration = 0.2
    static let scaleUPAnimationDuration = 0.1
    static let longPressDuration = 0.3
    static let animateToRightVerticalPosition = 0.1
    static let animateToHideOriginalMessageDuration = 0.4

    struct Sizes {
        let rectInNav: CGRect
        let stackBounds: CGRect
        let originalX: CGFloat
        let navFrame: CGRect
        let minTopVertical: CGFloat
        let maxVertical: CGFloat
        let menuX: CGFloat
        let reactionX: CGFloat
    }
}

extension MessageContainerStackView {
    func addMenus() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = Constants.longPressDuration
        addGestureRecognizer(longGesture)
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
        if sender.state == .began, let indexPath = indexpath(), let contentView = makeContextMenuView(indexPath) {
            delegate?.showContextMenu(indexPath, contentView: contentView)
            UIView.animate(withDuration: Constants.animateToHideOriginalMessageDuration) {
                self.alpha = 0.0
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        }
    }

    func makeContextMenuView(_ indexPath: IndexPath) -> UIView? {
        guard let viewModel = viewModel else { return nil }
        let vc = delegate as? ThreadViewController
        guard let vc = vc, let tableView = vc.tableView else { return nil }

        let sizes = calculateRects(tableView, indexPath, vc, isMe: viewModel.calMessage.isMe)

        let scrollViewContainer = createScrollViewContainer(sizes)

        let messageContainer = createCopyStackContainer(viewModel, sizes)
        scrollViewContainer.addSubview(messageContainer)

        let reactionBarView = createReaction(viewModel, sizes, messageContainer)
        scrollViewContainer.addSubview(reactionBarView)

        let menu = createMenu(viewModel, indexPath, messageContainer, sizes)
        scrollViewContainer.addSubview(menu)

        scrollViewContainer.bringSubviewToFront(reactionBarView) // Expand mode in reactions
        animateToRightVerticalPosition(sizes, reactionBarView, messageContainer, menu)

        return scrollViewContainer
    }

    private func calculateRects(_ tableView: UIHistoryTableView, _ indexPath: IndexPath, _ vc: ThreadViewController, isMe: Bool) -> Constants.Sizes {
        let rectIntableView = tableView.rectForRow(at: indexPath)
        let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell
        let messageStack = cell?.messageContainer
        let viewInNav = vc.navigationController?.view
        let stackBounds = messageStack?.bounds ?? .zero
        let rectInContentView = messageStack?.convert(stackBounds, to: cell?.contentView) ?? .zero
        let rectInView = tableView.convert(rectIntableView, to: vc.view)
        var rectInNav = vc.navigationController?.view.convert(rectInView, to: viewInNav) ?? .zero
        rectInNav.origin.x = rectInContentView.origin.x
        let originalX = frame.origin.x
        let navFrame = viewInNav?.frame ?? .zero
        let minTopVertical = vc.topThreadToolbar.frame.height + 64
        let maxVertical = vc.sendContainer.frame.height


        let stackWidthWithMargin = stackBounds.width + Constants.margin
        let rightXForLargerStack = navFrame.width - stackWidthWithMargin

        let isStackLargerThanReactoinPicker = stackBounds.width > Constants.reactionWidth
        let rightXForReactionPickerLarger = navFrame.width - (Constants.reactionWidth + Constants.margin)
        let xForReaction = isStackLargerThanReactoinPicker ? rightXForLargerStack : rightXForReactionPickerLarger
        let reactionX: CGFloat = isMe ? xForReaction : originalX

        let isStackLargerThanMenu = stackBounds.width > Constants.menuWidth
        let rightXForMenuLarger = navFrame.width - (Constants.menuWidth + Constants.margin)
        let xForMenu = isStackLargerThanMenu ? rightXForLargerStack : rightXForMenuLarger
        let menuX: CGFloat = isMe ? xForMenu : originalX

        return Constants.Sizes(rectInNav: rectInNav,
                               stackBounds: stackBounds,
                               originalX: originalX,
                               navFrame: navFrame,
                               minTopVertical: minTopVertical,
                               maxVertical: maxVertical,
                               menuX: menuX,
                               reactionX: reactionX
        )
    }

    private func createScrollViewContainer(_ sizes: Constants.Sizes) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = sizes.navFrame
        return view
    }

    private func createCopyStackContainer(_ viewModel: MessageRowViewModel, _ sizes: Constants.Sizes) -> MessageContainerStackView {
        let messageContainer = MessageContainerStackView(frame: .zero, isMe: viewModel.calMessage.isMe)
//        messageContainer.frame = .init(origin: sizes.rectInNav.origin, size: sizes.stackBounds.size)
        messageContainer.frame = .init(origin: .init(x: sizes.rectInNav.origin.x, y: 0), size: sizes.stackBounds.size)
        messageContainer.set(viewModel)
        messageContainer.prepareForContextMenu(userInterfaceStyle: traitCollection.userInterfaceStyle)
        messageContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(faketapGesture)))

        addAnimation(messageContainer)
        return messageContainer
    }

    private func createMenu(_ viewModel: MessageRowViewModel, _ indexPath: IndexPath, _ messageContainer: MessageContainerStackView, _ sizes: Constants.Sizes) -> CustomMenu {
        let menu = menu(model: .init(viewModel: viewModel), indexPath: indexPath, onMenuClickedDismiss: resetOnDismiss)
        menu.frame.origin.y = messageContainer.frame.maxY + Constants.margin
        menu.frame.origin.x = sizes.menuX
        menu.frame.size.width = Constants.menuWidth
        menu.frame.size.height = menu.height()

        addAnimation(menu)
        return menu
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

    private func createReaction(_ viewModel: MessageRowViewModel, _ sizes: Constants.Sizes, _ messageContainer: MessageContainerStackView) -> UIReactionsPickerScrollView {

        let reactionsView = UIReactionsPickerScrollView(size: Constants.reactionHeight)
        reactionsView.frame = .init(x: sizes.reactionX,
                                    y: messageContainer.frame.origin.y - (Constants.reactionHeight + 8),
                                    width: Constants.reactionWidth,
                                    height: reactionViewInitialHeight())
        reactionsView.setup(viewModel)
        reactionsView.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle

        let canReact = viewModel.canReact()
        reactionsView.isUserInteractionEnabled = canReact
        reactionsView.isHidden = !canReact

        addAnimation(reactionsView)
        return reactionsView
    }

    private func reactionViewInitialHeight() -> CGFloat {
        return Constants.reactionHeight + (allowedReactions().count < 4 ? 4.0 : 0.0)
    }

    private func allowedReactions() -> [Sticker] {
        if viewModel?.threadVM?.thread.reactionStatus == .enable { return Sticker.allCases.filter({ $0 != .unknown}) }
        return viewModel?.threadVM?.reactionViewModel.allowedReactions ?? []
    }

    private func getRightY(_ sizes: Constants.Sizes, _ messageContainer: MessageContainerStackView, _ menu: CustomMenu) -> CGFloat {
        var calculatedY: CGFloat = 0
        let menuHeight = menu.height()

        if messageContainer.frame.minY < (sizes.minTopVertical - Constants.reactionHeight) {
            calculatedY = Constants.reactionHeight
        } else if messageContainer.frame.maxY > sizes.navFrame.height - (menuHeight + Constants.space) {
            calculatedY = -((messageContainer.frame.maxY + menuHeight + sizes.maxVertical) - sizes.navFrame.height)
        }

        return calculatedY
    }

    private func animateToRightVerticalPosition(_ sizes: Constants.Sizes, _ reactionView: UIReactionsPickerScrollView, _ messageContainer: MessageContainerStackView, _ menu: CustomMenu) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: Constants.animateToRightVerticalPosition) {
                let y = self.getRightY(sizes, messageContainer, menu)
                messageContainer.frame.origin.y += y
                reactionView.frame.origin.y += y
                menu.frame.origin.y += y
            }
        }
    }

    private var delegate: ThreadViewDelegate? {
        return viewModel?.threadVM?.delegate
    }

    private func indexpath() -> IndexPath? {
        guard
            let vm = viewModel,
            let indexPath = viewModel?.threadVM?.historyVM.sections.indexPath(for: vm)
        else { return nil }
        return indexPath
    }

    @objc private func faketapGesture(_ sender: UIGestureRecognizer) {
        sender.cancelsTouchesInView = true
    }

    public func resetOnDismiss() {
        UIView.animate(withDuration: Constants.scaleUPAnimationDuration) {
            self.alpha = 1.0
        }
    }
}
