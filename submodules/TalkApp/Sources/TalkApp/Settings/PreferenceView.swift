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
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            DarkModeSection()
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            StickyHeaderSection(header: "", height: 10)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            ManageSessionsSection()
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)            
            if EnvironmentValues.isTalkTest {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                    .sandboxLabel()
                Section("Tab.contacts") {
                    VStack(alignment: .leading, spacing: 2) {
                        Toggle("Contacts.Sync.sync".bundleLocalized(), isOn: $model.isSyncOn)
                        Text("Contacts.Sync.subtitle")
                            .foregroundColor(.gray)
                            .font(.fCaption3)
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
        .onChange(of: model) { _ in
            model.save()
        }
        .normalToolbarView(title: "Settings.title", type: PreferenceNavigationValue.self)
    }
}

#Preview {
    PreferenceView()
}
