//
//  View+.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 12/12/21.
//

import SwiftUI
import TalkModels

extension View {
    @ViewBuilder
    func compatibleConfirmationDialog(_ isPresented: Binding<Bool>, message: String? = nil, title: String? = nil, _ buttons: [DialogButton]) -> some View {
        if #available(iOS 15, *) {
            self.confirmationDialog(title ?? "", isPresented: isPresented, titleVisibility: (title?.isEmpty ?? false) ? .hidden : .visible) {
                ForEach(buttons) { button in
                    Button {
                        withAnimation {
                            button.action()
                        }
                    } label: {
                        Text(button.title)
                    }
                }
            }
        } else {
            actionSheet(isPresented: isPresented) {
                let alertButtons = buttons.map { Alert.Button.default(Text($0.title), action: $0.action) }
                return ActionSheet(title: Text(title ?? ""), message: Text(message ?? ""), buttons: alertButtons)
            }
        }
    }
}

struct DialogButton: Hashable, Identifiable {
    static func == (lhs: DialogButton, rhs: DialogButton) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var title: String
    var action: () -> Void
    var id = UUID().uuidString
}

public extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { view in
            addArrangedSubview(view)
        }
    }
}

public extension Text {
    init(_ key: String) {
        self.init(.init(key), tableName: nil, bundle: Language.preferedBundle, comment: "")
    }
}


public extension UIView {
    // It will give us a lot of performance it won't update the stack/uiview if they are hidden already because isHidden if called twice even with the same value causes a lot of hiccups
    func setIsHidden(_ newState: Bool) {
        if newState != isHidden {
            isHidden = newState
        }
    }

    func setSemanticContent(_ newState: UISemanticContentAttribute) {
        if newState != semanticContentAttribute {
            semanticContentAttribute = newState
        }
    }

    func setBackgroundColor(_ newState: UIColor?) {
        if newState != backgroundColor {
            backgroundColor = newState
        }        
    }

    func showWithAniamtion(_ show: Bool) {
        let hidden = !show
        if isHidden != hidden {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                alpha = show ? 1.0 : 0.0
                setIsHidden(!show)
            }
        }
    }

    func removeFromSuperViewWithAnimation(withAimation: Bool = true, checkAnimationCompletion: Bool = true) {
        if withAimation {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                alpha = 0.0
            } completion: { completed in
                if checkAnimationCompletion, completed {
                    self.removeFromSuperview()
                } else {
                    self.removeFromSuperview()
                }
            }
        } else {
            self.removeFromSuperview()
        }
    }
}

@MainActor
public class FadeInOutAnimator {
    private weak var targetView: UIView?
    private var animator: UIViewPropertyAnimator?
    
    public init(view: UIView) {
        self.targetView = view
    }
    
    public func startAnimation(duration: TimeInterval = 0.2, show: Bool) {
        guard let view = targetView else { return }
        
        view.alpha = show ? 0.0 : 1.0
        animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            view.alpha = show ? 1.0 : 0.0
        }
        
        animator?.addCompletion { [weak self] position in
            if position == .end, !show {
                self?.targetView?.removeFromSuperview()
            }
        }
        
        animator?.startAnimation()
    }
    
    public func cancelAnimation() {
        animator?.stopAnimation(true) // Cancel without triggering the completion block
        animator?.finishAnimation(at: .current) // Keep the current alpha state
    }
}

@MainActor
public class TransformAnimator {
    private weak var targetView: UIView?
    private var animator: UIViewPropertyAnimator?
    
    public init(view: UIView) {
        self.targetView = view
    }
    
    public func startAnimation(duration: TimeInterval = 0.2, show: Bool, completion: @escaping @Sendable (UIViewAnimatingPosition) -> Void) {
        guard let view = targetView else { return }
        
        if show, view.isHidden {
            view.setIsHidden(false)
            view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }
        
        animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            view.transform = show ? .identity : CGAffineTransform(scaleX: 0.01, y: 0.01)
        }
        animator?.addCompletion(completion)
        animator?.startAnimation()
    }
    
    public func cancelAnimation() {
        animator?.stopAnimation(true) // Cancel without triggering the completion block
        animator?.finishAnimation(at: .current) // Keep the current alpha state
    }
}

