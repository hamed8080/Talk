//
//  HistoryKeyboarHeightManager.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 2/11/26.
//

import UIKit

// MARK: Keyboard apperance
@MainActor
class HistoryKeyboarHeightManager {
    private let vc: ThreadViewController
    private var keyboardheight: CGFloat = 0
    public private(set) var hasExternalKeyboard = false
    public private(set) var animatingKeyboard = false
    
    private var sendContainer: ThreadBottomToolbar { vc.sendContainer }
    private var tableView: UIHistoryTableView { vc.tableView }
    private var view: UIView { vc.view }
    
    init(controller: ThreadViewController) {
        self.vc = controller
        registerKeyboard()
    }
    
    private func registerKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notif in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.willShowKeyboard(notif: notif)
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notif in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.willHidekeyboard(notif: notif)
            }
        }
    }
    
    private func willShowKeyboard(notif: Notification) {
        if vc.isViewControllerVisible == false { return }
        keyboardAnimationTransaction(notif, show: true)
        
        /// Prevent overlaping with the text container if the thread is empty.
        if vc.viewModel.historyVM.sections.isEmpty == true {
            view.bringSubviewToFront(sendContainer)
        }
    }
    
    private func willHidekeyboard(notif: Notification) {
        if vc.isViewControllerVisible == false { return }
        keyboardAnimationTransaction(notif, show: false)
    }
    
    private func keyboardAnimationTransaction(_ notif: Notification, show: Bool) {
        guard let tuple = extractDurationAndAnimation(notif: notif) else { return }
        hasExternalKeyboard = tuple.rect.height <= 69
        keyboardheight = show ? tuple.rect.height : 0
        vc.sendContainerBottomConstraint?.constant = show ? -keyboardheight : keyboardheight
        
        /// Disable onHeightChanged callback for the send container
        /// to manipulate the content inset during the animation
        animatingKeyboard = true
        let indexPath = vc.delegateObject.lastMessageIndexPathIfVisible()
        
        UIView.animate(withDuration: tuple.duration, delay: 0.0, options: tuple.opt) {
            /// Animate layout sendContainerBottomConstraint changes.
            /// It should be done on it's superView to animate
            self.view.layoutIfNeeded()
            
            // Scroll within the transaction block
            if let indexPath = indexPath {
                /// Animation parameter should be always set to false
                /// unless it won't animate as we expect in a UIView.animate block.
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        } completion: { completed in
            if completed {
                self.animatingKeyboard = false
            }
        }
    }

    @objc func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    public func getKeyboardHeight() -> CGFloat {
        return keyboardheight
    }
    
    func extractDurationAndAnimation(notif: Notification) -> (duration: Double, opt: UIView.AnimationOptions, rect: CGRect)? {
        let userInfo = notif.userInfo
        if let rect = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let animationCurve = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
           let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        {
            let opt = UIView.AnimationOptions(rawValue: animationCurve << 16)
            return (duration, opt, rect)
        }
        return nil
    }
}

extension Notification: @unchecked Sendable {}
