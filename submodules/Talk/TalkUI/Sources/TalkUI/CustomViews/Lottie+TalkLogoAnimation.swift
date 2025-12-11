//
//  Lottie+TalkLogoAnimation.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 11/12/25.
//

import Foundation
import Lottie
import SwiftUI

public extension LottieAnimationView {
    public convenience init(fileName: String = "talk_logo_animation.json", color: UIColor = Color.App.accentUIColor ?? .orange) {
        self.init(name: fileName)
        loopMode = .loop
        let keypath = AnimationKeypath(keypath: "**.Fill 1.Color")
        let colorProvider = ColorValueProvider(color.lottieColorValue)
        setValueProvider(colorProvider, keypath: keypath)
    }
}
