//
//  DeleteContactView.swift
//  Talk
//
//  Created by hamed on 11/25/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct DeleteContactView: View {
    @EnvironmentObject var contactViewModel: ContactsViewModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Contacts.deleteSelectedTitle")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subtitle))
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("Contacts.deleteSelectedSubTitle")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.normal(.subheadline))
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    contactViewModel.deleteSelectedItems()
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.delete")
                        .foregroundStyle(Color.App.red)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct DeleteContactView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteContactView()
    }
}
