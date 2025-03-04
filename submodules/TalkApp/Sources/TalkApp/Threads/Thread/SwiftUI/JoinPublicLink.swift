//
//  JoinPublicLink.swift
//  Talk
//
//  Created by hamed on 12/4/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import TalkUI
import Chat

public struct JoinToPublicConversationDialog: View {
    let publicGroupName: String
    var appOverlayVM: AppOverlayViewModel {AppState.shared.objectsContainer.appOverlayVM}

    public init(publicGroupName: String) {
        self.publicGroupName = publicGroupName
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Thread.Join.question")
                .foregroundStyle(Color.App.textPrimary)
                .font(.fBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Button {
                    AppState.shared.objectsContainer.threadsVM.joinPublicGroup(publicGroupName)
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("Thread.join")
                        .foregroundStyle(Color.App.accent)
                        .font(.fBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(.fBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}
