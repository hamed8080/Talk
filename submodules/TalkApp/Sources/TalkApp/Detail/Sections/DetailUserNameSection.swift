//
//  DetailUserNameSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailUserNameSection: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let participantName = viewModel.participant.username.validateString {
            SectionRowContainer(key: "Settings.userName", value: participantName)
                .onTapGesture {
                    UIPasteboard.general.string = participantName
                    let icon = Image(systemName: "person")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.App.textPrimary)
                    let key = "Settings.userNameCopied".bundleLocalized()
                    AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: key, messageColor: Color.App.textPrimary)
                }
        }
    }
}

struct DetailUserNameSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailUserNameSection()
    }
}
