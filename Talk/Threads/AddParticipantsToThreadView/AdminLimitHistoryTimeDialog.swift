//
//  AdminLimitHistoryTimeDialog.swift
//  Talk
//
//  Created by hamed on 10/14/24.
//

import SwiftUI
import Chat
import TalkViewModels
import TalkUI

struct AdminLimitHistoryTimeDialog: View {
    let threadId: Int?
    let completion: (UInt?) -> Void
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("AdminLimitHistoryTimeDialog.header")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("AdminLimitHistoryTimeDialog.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBody)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            VStack {
                Text("AdminLimitHistoryTimeDialog.chooseDate")
                    .foregroundStyle(Color.App.textPrimary)
                    .font(.iransansCaption2)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                datePickerContainer
            }
            HStack {
                Button {
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel".bundleLocalized())
                        .foregroundStyle(Color.App.textSecondary.opacity(0.8))
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    container.threadsVM.delete(threadId)
                    container.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.submit".bundleLocalized())
                        .foregroundStyle(Color.App.textPrimary)
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

    private var datePickerContainer: some View {
        Button {

        } label: {
            HStack {
                Text("۱۴ شهریور ۱۴۰۲")
                    .foregroundStyle(Color.App.textPrimary)

                Spacer()
                Image(systemName: "chevron.down")
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.App.textPrimary.opacity(0.2))
            }
        }
        .font(.iransansBody)
        .frame(minHeight: 32)
        .padding(8)
        .fontWeight(.medium)
        .background(Color.App.bgPrimary)
        .cornerRadius(8, corners: .allCorners)
    }
}

struct AdminLimitHistoryTimeDialog_Previews: PreviewProvider {
    static var previews: some View {
        AdminLimitHistoryTimeDialog(threadId: 1) { historyTime in

        }
    }
}
