//
//  InjectAllSwiftUI.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 10/14/25.
//

import SwiftUI
import TalkModels

public extension View {
    func injectAllObjects() -> some View {
        let container = AppState.shared.objectsContainer!
        let injected = self
        .environmentObject(container.navVM)
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        .environmentObject(AppState.shared)        
        .environmentObject(container)
        .environmentObject(container.searchVM)
        .environmentObject(container.navVM)
        .environmentObject(container.settingsVM)
        .environmentObject(container.contactsVM)
        .environmentObject(container.threadsVM)
        .environmentObject(container.loginVM)
        .environmentObject(container.tokenVM)
        .environmentObject(container.tagsVM)
        .environmentObject(container.userConfigsVM)
        .environmentObject(container.logVM)
        .environmentObject(container.audioPlayerVM)
        .environmentObject(container.conversationBuilderVM)
        .environmentObject(container.userProfileImageVM)
        .environmentObject(container.banVM)
        .environmentObject(container.sizeClassObserver)
        .environmentObject(container.appOverlayVM)
        .environmentObject(container.downloadsManager)
        .environmentObject(container.uploadsManager)
        .environmentObject(container.contextMenuModel)
        return injected
    }
}
