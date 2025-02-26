//
//  RevealAnimation.swift
//  Talk
//
//  Created by Hamed Hosseini on 1/1/25.
//

import Foundation
import UIKit

// MARK: Reveal animation
class RevealAnimation {
    private var shouldAnimateCellsOnAppear = true
    private var revealTimer: Timer?
    
    init() {
        
    }
    
    func reveal(for view: UIView) {
        if !shouldAnimateCellsOnAppear { return }
        view.layer.opacity = 0.0
        UIView.animate(
            withDuration: 0.25,
            delay: 0.4,
            options: .curveEaseInOut,
            animations: {
                view.layer.opacity = 1.0
            }
        )
        
        if revealTimer == nil {
            revealTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.shouldAnimateCellsOnAppear = false // stop to reanimate
                    self?.revealTimer = nil
                }
            }
        }
    }
}
