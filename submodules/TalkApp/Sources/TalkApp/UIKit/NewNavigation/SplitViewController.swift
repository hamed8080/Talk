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
import Combine

public class SplitViewController: UISplitViewController {
    private var cancellableSet = Set<AnyCancellable>()
    private var overlayVC: UIViewController?
    
    public override init(style: UISplitViewController.Style) {
        super.init(style: style)
        AppState.shared.objectsContainer.navVM.rootVC = self
        registerOverlay()
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
    
    private func registerOverlay() {
        AppState.shared.objectsContainer.appOverlayVM.$isPresented.sink { [weak self] isPresented in
            self?.onOverlayPresentChange(isPresented)
        }
        .store(in: &cancellableSet)
    }
    
    private func onOverlayPresentChange(_ isPresented: Bool) {
        if isPresented {
            let injected = AppOverlayView() { [weak self] in
                self?.onDismiss()
            } content: {
                AppOverlayFactory()
            }.injectAllObjects()
            let overlayVC = UIHostingController(rootView: injected)
            overlayVC.view.translatesAutoresizingMaskIntoConstraints = false
            addChild(overlayVC)
            overlayVC.didMove(toParent: self)
            view.addSubview(overlayVC.view)
            
            NSLayoutConstraint.activate([
                overlayVC.view.topAnchor.constraint(equalTo: view.topAnchor),
                overlayVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                overlayVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlayVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            
            self.overlayVC = overlayVC
        } else {
            overlayVC?.view.removeFromSuperview()
        }
    }
    
    private func onDismiss() {
        AppState.shared.objectsContainer.appOverlayVM.clear()
    }
}
