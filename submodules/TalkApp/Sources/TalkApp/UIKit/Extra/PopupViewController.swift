//
//  PopupViewController.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/31/25.
//

import UIKit
import SwiftUI

@MainActor
class PopupViewController {
    private init() {}
    
    private static var popupVC: UIViewController?
    
    public static func showPopup(view: some View, anchorView: UIView, parentVCView: UIView?) {
        let vc = UIViewController()
        self.popupVC = vc
        vc.modalPresentationStyle = .overCurrentContext
        vc.definesPresentationContext = true
        vc.view.backgroundColor = .clear
        vc.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissAndRemovePopup)))
        vc.view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let hostVC = UIHostingController(rootView: view)
        hostVC.view.backgroundColor = .clear
        hostVC.view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        hostVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        vc.addChild(hostVC)
        hostVC.didMove(toParent: vc)
        vc.view.addSubview(hostVC.view)
        
        let moreButtonPositionInVC = anchorView.convert(anchorView.bounds, to: parentVCView)
        let x = abs(moreButtonPositionInVC.origin.x)
        let btnWidth = anchorView.frame.width
        let leadingConstant = Language.isRTL ? x + (btnWidth / 2) : x - 246 + btnWidth
        
        NSLayoutConstraint.activate([
            hostVC.view.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: moreButtonPositionInVC.origin.y + anchorView.frame.height + 8),
            hostVC.view.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: leadingConstant)
        ])
        
        let splitVC = AppState.shared.objectsContainer.navVM.splitVC
        let secondaryVC = splitVC?.viewController(for: .secondary) ?? splitVC
        secondaryVC?.present(vc, animated: false)
    }
    
    @objc static public func dismissAndRemovePopup() {
        popupVC?.dismiss(animated: false)
        popupVC = nil
    }
}
