//
//  FastNavigationController.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/7/25.
//

import Foundation
import UIKit
import TalkModels

final class FastNavigationController: UINavigationController, UINavigationControllerDelegate {
    // MARK: - Private Properties
    
    fileprivate var duringPushAnimation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        interactivePopGestureRecognizer?.delegate = self
        /// It is essential for correct direction of the pop gesture 
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return FastNavigationAnimator(operation: operation)
    }
}

extension FastNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == interactivePopGestureRecognizer else {
            return true // default value
        }
        // Disable pop gesture in two situations:
        // 1) when user swipes quickly a couple of times and animations don't have time to be performed
        return viewControllers.count > 1
    }
}

final class FastNavigationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let operation: UINavigationController.Operation

    init(operation: UINavigationController.Operation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.20 // Telegram-style speed
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard
            let fromView = ctx.view(forKey: .from),
            let toView = ctx.view(forKey: .to)
        else { return }

        let container = ctx.containerView
        let width = container.bounds.width

        if operation == .push {
            toView.transform = CGAffineTransform(translationX: width, y: 0)
            container.addSubview(toView)
            UIView.animate(withDuration: transitionDuration(using: ctx), delay: 0, options: .curveEaseInOut, animations: {
                fromView.transform = CGAffineTransform(translationX: -width * 0.3, y: 0)
                toView.transform = .identity
            }, completion: { finished in
                fromView.transform = .identity
                ctx.completeTransition(finished)
            })
        } else if operation == .pop {
            container.insertSubview(toView, belowSubview: fromView)
            toView.transform = CGAffineTransform(translationX: -width * 0.3, y: 0)
            UIView.animate(withDuration: transitionDuration(using: ctx), delay: 0, options: .curveEaseInOut, animations: {
                fromView.transform = CGAffineTransform(translationX: width, y: 0)
                toView.transform = .identity
            }, completion: { finished in
                fromView.transform = .identity
                ctx.completeTransition(finished)
            })
        } else {
            ctx.completeTransition(true)
        }
    }
}
