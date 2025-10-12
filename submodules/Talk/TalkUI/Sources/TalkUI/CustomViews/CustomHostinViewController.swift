//
//  CustomUIHostinViewController.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI

public final class LocalStatusBarStyle { // style proxy to be stored in Environment
    fileprivate var getter: () -> UIStatusBarStyle = { .default }
    fileprivate var setter: (UIStatusBarStyle) -> Void = { _ in }

    public var currentStyle: UIStatusBarStyle {
        get { getter() }
        set { setter(newValue) }
    }
}

// Custom Environment key, as it is set once, it can be accessed from anywhere
// of SwiftUI view hierarchy
@MainActor
public struct LocalStatusBarStyleKey: @preconcurrency EnvironmentKey {
    public static let defaultValue: LocalStatusBarStyle = .init()
}

public extension EnvironmentValues { // Environment key path variable
    var localStatusBarStyle: LocalStatusBarStyle {
        self[LocalStatusBarStyleKey.self]
    }
}

/// Custom hosting controller that update status bar style,
/// and prevent swipe back at the root view controller.
public class CustomUIHostinViewController<Content>: UIHostingController<Content> where Content: View {
    private var internalStyle = UIStatusBarStyle.default

    @objc override open dynamic var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            internalStyle
        }
        set {
            internalStyle = newValue
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    public override init(rootView: Content) {
        super.init(rootView: rootView)

        LocalStatusBarStyleKey.defaultValue.getter = { self.preferredStatusBarStyle }
        LocalStatusBarStyleKey.defaultValue.setter = { self.preferredStatusBarStyle = $0 }
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

struct UINavigationControllerState {
    @MainActor static var shared = UINavigationControllerState()
    var allowsSwipeBack: Bool = true
}

//extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//    }
//
//    /// This code will prevent a bug in SwiftUI or UIKit where user tries to pop with left to right gesture
//    /// where there is no more view controller to pop.
//    /// By removing these lines, after swipe over the edge of the screen where there is nothing to pop
//    /// no more clicks will work.
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        guard UINavigationControllerState.shared.allowsSwipeBack else { return false }
//        return viewControllers.count > 1
//    }
//}
