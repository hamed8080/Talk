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
    @State private var limitHistorySelectedDate: Date? = nil
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
                .font(.iransansCaption3)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            toggleLimitHistory
            actionButtons
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }

    private var actionButtons: some View {
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
                if let limitHistorySelectedDate = limitHistorySelectedDate {
                    completion(UInt(limitHistorySelectedDate.millisecondsSince1970))
                } else {
                    completion(nil)
                }
            } label: {
                Text("General.submit".bundleLocalized())
                    .foregroundStyle(Color.App.textPrimary)
                    .font(.iransansBody)
                    .frame(minWidth: 48, minHeight: 48)
                    .fontWeight(.medium)
            }
        }
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
                        .font(.iransansBody)
                        .foregroundStyle(Color.App.textSecondary)

                    Text("AdminLimitHistoryTimeDialog.chooseDate".bundleLocalized())
                }
                Spacer()
                Toggle("", isOn: $isLimitTimeOn)
                    .tint(Color.App.accent)
                    .scaleEffect(x: 0.8, y: 0.8, anchor: .center)
                    .offset(x: 8)
                    .labelsHidden()
            }
            limitTimePicker
        }
        .animation(.easeInOut.speed(2), value: isLimitTimeOn)
        .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
        .listSectionSeparator(.hidden)
        .listRowBackground(Color.App.bgSecondary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
        .font(.iransansBody)
    }

    @ViewBuilder
    private var limitTimePicker: some View {
        DatePickerWrapper() { date in
            limitHistorySelectedDate = date
        }
        .frame(maxHeight: 420)
        .disabled(!isLimitTimeOn)
        .opacity(isLimitTimeOn ? 1.0 : 0.3)
    }
}

struct AdminLimitHistoryTimeDialog_Previews: PreviewProvider {
    static var previews: some View {
        AdminLimitHistoryTimeDialog(threadId: 1) { historyTime in

        }
    }
}
