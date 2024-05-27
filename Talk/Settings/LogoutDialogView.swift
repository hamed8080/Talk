//
//  LogoutDialogView.swift
//  Talk
//
//  Created by hamed on 11/4/23.
//

import SwiftUI
import TalkViewModels
import Chat
import TalkUI

struct LogoutDialogView: View {
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Settings.logoutFromAccount")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldSubtitle)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("Settings.areYouSureToLogout")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    Task {
                        await onLogoutTapped()
                    }
                } label: {
                    Text("Settings.logout")
                        .foregroundStyle(Color.App.accent)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }

    private func onLogoutTapped() async {
        container.appOverlayVM.dialogView = nil
        ChatManager.activeInstance?.user.logOut()
        TokenManager.shared.clearToken()
        UserConfigManagerVM.instance.logout(delegate: ChatDelegateImplementation.sharedInstance)
        await container.reset()
    }
}

struct LogoutDialogView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutDialogView()
    }
}
