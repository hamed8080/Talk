//
//  SplitViewController.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/7/25.
//

import Foundation
import UIKit
import TalkModels
import SwiftUI
import TalkUI

public class SplitViewController: UISplitViewController {
    
    public override init(style: UISplitViewController.Style) {
        super.init(style: style)
        AppState.shared.objectsContainer.navVM.rootVC = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        view.backgroundColor = Color.App.bgPrimaryUIColor
        
        // Use .displace for correct layout behavior
        preferredSplitBehavior = .tile
        preferredDisplayMode = .oneBesideSecondary
        presentsWithGesture = false
        preferredPrimaryColumnWidth = 420
        maximumPrimaryColumnWidth = 420
        
        // Wrap tab bar in a navigation controller (but hide nav bar)
        let primaryNav = FastNavigationController(rootViewController: PrimaryTabBarViewController())

        // Set both controllers
        setViewController(primaryNav, for: .primary)
//        setViewController(detailNav, for: .secondary)
        
    }
}
