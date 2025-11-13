//
//  UIApplication+.swift
//  TalkExtensions
//
//  Created by hamed on 3/14/23.
//

import Foundation
import SwiftUI
import UIKit

public enum WindowMode {
    case iPhone
    case ipadFullScreen
    case ipadSlideOver
    case ipadOneThirdSplitView
    case ipadHalfSplitView
    case ipadTwoThirdSplitView
    case unknown
    /// A mode that detect if the deveice is one column mode such as iPhone/ipadOneThirdSplitView/ipadSlideOver.
    public var isInSlimMode: Bool {
        return self == .iPhone || self == .ipadSlideOver || self == .ipadOneThirdSplitView
    }
}

public extension UIApplication {
    var screenRect: CGRect { UIScreen.main.bounds }
    var activeWindowScene: UIWindowScene? { UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).first as? UIWindowScene }
    var inactiveWindowScene: UIWindowScene? { UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundInactive}).first as? UIWindowScene }
    var activeSceneRect: CGRect { (activeWindowScene ?? inactiveWindowScene)?.windows.first?.bounds ?? .zero }

    func windowMode() -> WindowMode {
        let isInHalfThreshold = isInThereshold(a: activeSceneRect.width, b: abs(screenRect.width - (screenRect.width / 2)))
        let isInOneThirdThreshold = isInThereshold(a: activeSceneRect.width, b: abs(screenRect.width - (screenRect.width / (8/10))))
        let isInTwoThirdThreshold = isInThereshold(a: activeSceneRect.width, b: abs(screenRect.width - (screenRect.width * (3/10))))
        if (UIDevice.current.userInterfaceIdiom == .phone) {
            return .iPhone
        } else if (screenRect == activeSceneRect) {
            return .ipadFullScreen
        } else if (activeSceneRect.size.height < screenRect.size.height) {
            return .ipadSlideOver
        } else if isInHalfThreshold {
            return .ipadHalfSplitView
        } else if isInTwoThirdThreshold {
            return .ipadTwoThirdSplitView
        } else if isInOneThirdThreshold {
            return .ipadOneThirdSplitView
        } else {
            return .unknown
        }
    }

    private func isInThereshold(a: CGFloat, b: CGFloat) -> Bool {
        let threshold = 0.1 // 10% threshold
        if abs(a - b) / ((a + b) / 2) < threshold {
            return true
        } else {
            return false
        }
    }
}
