//
//  SettingProfileButton.swift
//  Talk
//
//  Created by hamed on 11/1/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import Chat

struct SettingProfileButton: View {
    @EnvironmentObject var imageLoader: ImageLoaderViewModel
    @State var isSelected = false

    var body: some View {
        Image(systemName: "gear")
            .resizable()
            .scaledToFit()
            .overlay {
                let isImageReady = imageLoader.isImageReady == true
                Image(uiImage: imageLoader.image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(x: isImageReady ? 1 : 0.001, y: isImageReady ? 1 : 0.001, anchor: .center)
                    .animation(.interpolatingSpring(mass: 1.0, stiffness: 0.3, damping: 0.5, initialVelocity: 0).speed(15), value: isImageReady)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius:(12)))
                    .overlay {
                        Circle()
                            .strokeBorder(isSelected ? Color.App.accent : Color.App.bgPrimary, lineWidth: isImageReady ? 1 : 0)
                            .animation(.easeInOut, value: isSelected)
                    }
            }            
            .onReceive(NotificationCenter.selectTab.publisher(for: .selectTab)) { notification in
                if let selectedTab = notification.object as? String, selectedTab == "Tab.settings" {
                    isSelected = true
                } else {
                    isSelected = false
                }
            }
    }
}


struct SettingProfileButton_Previews: PreviewProvider {
    static var previews: some View {
        SettingProfileButton()
    }
}
