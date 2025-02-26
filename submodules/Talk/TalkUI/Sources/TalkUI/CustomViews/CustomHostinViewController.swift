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

// Custom hosting controller that update status bar style
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
