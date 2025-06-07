//
//  ManuallyConnectionManagerView.swift
//  Talk
//
//  Created by hamed on 11/28/23.
//

import SwiftUI
import TalkUI
import Chat
import TalkViewModels
import Logger
import TalkModels

struct ManuallyConnectionManagerView: View {
    @FocusState var isFocused
    @State var recreate: Bool = false
    @State var token: String = ""

    var body: some View {
        List {
            TextField("token".bundleLocalized(), text: $token)
                .focused($isFocused)
                .keyboardType(.phonePad)
                .submitLabel(.done)
                .font(.fBody)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "token", isFocused: isFocused) {
                    isFocused.toggle()
                }
            Toggle(isOn: $recreate) {
                Label("Recreate", systemImage: "repeat")
            }
            .tint(Color.App.accent)
            
            VStack {
                SubmitBottomButton(text: "Revoke Token", color: Color.App.red) {
                    Task { @ChatGlobalActor in
                        await ChatManager.activeInstance?.setToken(newToken: "revoked_token", reCreateObject: false)
                    }
                }
                
                SubmitBottomButton(text: "Refresh Token", color: Color.App.red) {
                    Logger.log(title: "ManuallyConnectionManagerView", message: "Start a new Task in ManuallyConnectionManagerView method")
                    Task { @MainActor in
                        try? await TokenManager.shared.getNewTokenWithRefreshToken()
                    }
                }

                SubmitBottomButton(text: "Destroy token", color: Color.App.red) {
                    UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenKey)
                    UserDefaults.standard.removeObject(forKey: TokenManager.ssoTokenCreateDate)
                    UserDefaults.standard.synchronize()
                }

                SubmitBottomButton(text: "Close connections", color: Color.App.red) {
                    Task { @ChatGlobalActor in
                        await ChatManager.activeInstance?.dispose()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: "Coneect", color: Color.App.color2) {
                let recreate = recreate
                let token = token
                Task { @ChatGlobalActor in
                    await ChatManager.activeInstance?.dispose()
                    await ChatManager.activeInstance?.setToken(newToken: token, reCreateObject: recreate)
                }
            }
        }
    }
}

struct ManuallyConnectionManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ManuallyConnectionManagerView()
    }
}
