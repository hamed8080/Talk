//
//  PreferenceView.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/15/24.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct PreferenceView: View {
    @State var isSyncOn = false

    var body: some View {
        List {
            SettingNotificationSection()
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            DarkModeSection()
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            StickyHeaderSection(header: "", height: 10)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            ManageSessionsSection()
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            DoubleTapSection()
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            SaveScrollPositionSection()
            if EnvironmentValues.isTalkTest {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                    .sandboxLabel()
                Section("Tab.contacts") {
                    VStack(alignment: .leading, spacing: 2) {
                        Toggle("Contacts.Sync.sync".bundleLocalized(), isOn: $isSyncOn)
                        Text("Contacts.Sync.subtitle")
                            .foregroundColor(.gray)
                            .font(Font.normal(.caption3))
                    }
                    .sandboxLabel()
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
                .sandboxLabel()
            }
        }
        .environment(\.defaultMinListRowHeight, 8)
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .font(Font.normal(.body))
        .onChange(of: isSyncOn) { newValue in
            var model = AppSettingsModel.restore()
            model.isSyncOn = newValue
            model.save()
        }
        .normalToolbarView(title: "Settings.title", type: String.self)
    }
}

#Preview {
    PreferenceView()
}
