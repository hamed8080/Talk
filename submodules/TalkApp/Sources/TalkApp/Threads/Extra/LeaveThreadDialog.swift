//
//  LeaveThreadDialog.swift
//  Talk
//
//  Created by hamed on 11/25/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import Chat

struct LeaveThreadDialog: View {
    let conversation: Conversation
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Thread.leave.footer")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.normal(.subheadline))
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    container.threadsVM.leave(conversation)
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("Thread.leaveButton")
                        .foregroundStyle(Color.App.accent)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct LeaveThreadDialog_Previews: PreviewProvider {
    static var previews: some View {
        LeaveThreadDialog(conversation: .init(id: 1))
    }
}
