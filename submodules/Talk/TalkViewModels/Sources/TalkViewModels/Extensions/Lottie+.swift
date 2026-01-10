import Lottie
import SwiftUI

@MainActor
public extension ColorValueProvider {
    static var defaultColorProvider: ColorValueProvider {
        let isDarkMode = AppSettingsModel.restore().isDarkMode
        let lottieColor = isDarkMode ? UIColor.white.lottieColorValue : UIColor.black.lottieColorValue
        let provider = ColorValueProvider(lottieColor)
        return provider
    }
}

@MainActor
public extension LottieView {
    func defaultColor() -> Self {
        self.valueProvider(
            ColorValueProvider.defaultColorProvider,
            for: AnimationKeypath(keypath: "**.Fill 1.Color")
        )
    }
}
