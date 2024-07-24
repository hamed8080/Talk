//
//  DeleteThreadDialog.swift
//  Talk
//
//  Created by hamed on 11/25/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct DeleteThreadDialog: View {
    let threadId: Int?
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Thread.Delete.footer")
                .foregroundStyle(Color.App.textPrimary)
                .font(.fSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack {

                Button {
                    container.threadsVM.delete(threadId)
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.delete")
                        .foregroundStyle(Color.App.accent)
                        .font(.fBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    container.appOverlayVM.dialogView = nil
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
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct DeleteThreadView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteThreadDialog(threadId: 1)
    }
}
