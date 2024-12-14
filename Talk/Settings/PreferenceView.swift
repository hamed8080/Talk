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
            StickyHeaderSection(header: "", height: 10)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            Section("Tab.contacts") {
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Contacts.Sync.sync".bundleLocalized(), isOn: $model.isSyncOn)
                    Text("Contacts.Sync.subtitle")
                        .foregroundColor(.gray)
                        .font(.iransansCaption3)
                }
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)
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
