//
//  HistoryTapGestureManager.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 2/11/26.
//

import UIKit

@MainActor
class HistoryTapGestureManager {
    private let tapGetsure = UITapGestureRecognizer()
    private let vc: ThreadViewController
    
    private var view: UIView { vc.view }
    
    init(controller: ThreadViewController) {
        self.vc = controller
    }
    
    func addTapGesture() {
        tapGetsure.addTarget(self, action: #selector(vc.keyboardManager.hideKeyboard))
        tapGetsure.isEnabled = true
        view.addGestureRecognizer(tapGetsure)
    }
    
    func setEnable(_ enable: Bool) {
        tapGetsure.isEnabled = enable
    }
}
