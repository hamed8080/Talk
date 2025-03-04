//
//  ColorSchemeModifier.swift
//  Talk
//
//  Created by hamed on 1/9/24.
//

import SwiftUI
import TalkViewModels

struct ColorSchemeModifier: ViewModifier {
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @State var isAppDarkModeEnabled: Bool? = AppSettingsModel.restore().isDarkModeEnabled

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(isAppDarkModeEnabled == nil ? nil : isAppDarkModeEnabled == true ? .dark : .light)
            .onReceive(NotificationCenter.appSettingsModel.publisher(for: .appSettingsModel), perform: { onSettingNotif($0)} )
    }

    private func onSettingNotif(_ notification: Notification) {
        if (notification.object as? AppSettingsModel)?.isDarkModeEnabled != isAppDarkModeEnabled {
            withAnimation {
                self.isAppDarkModeEnabled = AppSettingsModel.restore().isDarkModeEnabled
                statusBarStyle.currentStyle = isAppDarkModeEnabled == true ? .lightContent : .darkContent
            }
        }
    }
}
