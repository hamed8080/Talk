//
//  UILabel+.swift
//
//
//  Created by hamed on 1/2/24.
//

import Foundation
import UIKit

public extension UILabel {
    func addFlipAnimation(text: String?) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.type = .push
        animation.subtype = .fromBottom
        animation.duration = 0.2
        layer.add(animation, forKey: CATransitionType.push.rawValue)


        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        fadeAnimation.fromValue = 0.0
        fadeAnimation.toValue = 1.0
        fadeAnimation.duration = 0.2
        layer.add(fadeAnimation, forKey: CATransitionType.fade.rawValue)
        
        self.text = text
    }
}
