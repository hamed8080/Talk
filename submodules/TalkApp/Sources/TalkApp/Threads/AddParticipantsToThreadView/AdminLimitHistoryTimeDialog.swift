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
import TalkModels

struct AdminLimitHistoryTimeDialog: View {
    let threadId: Int?
    let completion: (UInt?) -> Void
    @State private var isLimitTimeOn = false
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("AdminLimitHistoryTimeDialog.header")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subheadline))
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("AdminLimitHistoryTimeDialog.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.normal(.caption3))
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            toggleLimitHistory
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }

    @ViewBuilder
    private var toggleLimitHistory: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "calendar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipped()
                        .font(Font.normal(.body))
                        .foregroundStyle(Color.App.textSecondary)

                    Text("AdminLimitHistoryTimeDialog.chooseDate".bundleLocalized())
                }
                Spacer()
                Toggle("", isOn: $isLimitTimeOn)
                    .tint(Color.App.accent)
                    .labelsHidden()
            }
            limitTimePicker
        }
        .animation(.easeInOut.speed(2), value: isLimitTimeOn)
        .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
        .listSectionSeparator(.hidden)
        .listRowBackground(Color.App.bgSecondary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
        .font(Font.normal(.body))
    }

    @ViewBuilder
    private var limitTimePicker: some View {
        DatePickerWrapper(hideControls: false, enableDatePicker: isLimitTimeOn) { date in
            container.appOverlayVM.dialogView = nil
            if isLimitTimeOn {
                completion(UInt(date.millisecondsSince1970))
            } else {
                completion(nil)
            }
        }
        .id(isLimitTimeOn) // To refresh SwiftUI and disable the datePicker
        .frame(maxHeight: 420)
    }
}

struct AdminLimitHistoryTimeDialog_Previews: PreviewProvider {
    static var previews: some View {
        AdminLimitHistoryTimeDialog(threadId: 1) { historyTime in

        }
    }
}
