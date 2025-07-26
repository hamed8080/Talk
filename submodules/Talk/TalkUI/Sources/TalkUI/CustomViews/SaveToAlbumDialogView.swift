//
//  SaveToAlbumDialogView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 7/26/25.
//

import SwiftUI
import TalkModels
import TalkViewModels

public struct SaveToAlbumDialogView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("SaveToAlbumAccessDialog.title")
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.App.red)
                Text("SaveToAlbumAccessDialog.message")
            }
            HStack(spacing: 24) {
                Button {
                    openAppSettings()
                } label: {
                    Text("Tab.settings")
                        .foregroundStyle(Color.blue)
                        .font(.fBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
                
                Button {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.accent)
                        .font(.fBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320, alignment: .center)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .background(MixMaterialBackground())
    }
    
    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}
