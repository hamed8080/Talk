//
//  DarkModeSection.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/15/24.
//

import SwiftUI
import TalkViewModels

struct DarkModeSection: View {
    @Environment(\.colorScheme) var currentSystemScheme
    @State var isDarkModeEnabled = AppSettingsModel.restore().isDarkModeEnabled ?? false

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "circle.righthalf.filled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
                    .background(Color.App.color1)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))

                Text("Settings.darkModeEnabled".bundleLocalized())
                    .padding(.leading, 8)
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity)

            Spacer()
            Toggle("", isOn: $isDarkModeEnabled)
                .tint(Color.App.accent)
                .frame(maxWidth: 64)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listSectionSeparator(.hidden)
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
        .onChange(of: isDarkModeEnabled) { value in
            var model = AppSettingsModel.restore()
            model.isDarkModeEnabled = value
            AppState.shared.objectsContainer.navVM.splitVC?.view.window?.overrideUserInterfaceStyle = value ? .dark : .light
            model.save()
        }
        .onAppear {
            if AppSettingsModel.restore().isDarkModeEnabled == nil {
                isDarkModeEnabled = currentSystemScheme == .dark
            }
        }
    }
}
#Preview {
    DarkModeSection()
}
