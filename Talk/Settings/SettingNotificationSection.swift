//
//  SettingNotificationSection.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct SettingNotificationSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "bell.fill", title: "Settings.notifictionSettings", color: .red, showDivider: false) {
            let value = NotificationSettingsNavigationValue()
            navModel.append(value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct NotificationSettings: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Group {
                Toggle("Notification.Sound".bundleLocalized(), isOn: $model.notificationSettings.soundEnable)
                    .tint(Color.App.accent)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)
                if EnvironmentValues.isTalkTest {
                    Toggle("Notification.ShowDetails".bundleLocalized(), isOn: $model.notificationSettings.showDetails)
                        .tint(Color.App.accent)
                        .listRowBackground(Color.App.bgPrimary)
                        .listRowSeparatorTint(Color.App.dividerPrimary)
                        .sandboxLabel()
                }
                if EnvironmentValues.isTalkTest {
                    Toggle("Notification.Vibration".bundleLocalized(), isOn: $model.notificationSettings.vibration)
                        .tint(Color.App.accent)
                        .listRowBackground(Color.App.bgPrimary)
                        .listSectionSeparator(.hidden)
                        .sandboxLabel()
                }
            }
            .listSectionSeparator(.hidden)

            if EnvironmentValues.isTalkTest {
                Group {
                    StickyHeaderSection(header: "", height: 10)
                        .listRowInsets(.zero)
                        .listRowSeparator(.hidden)
                        .sandboxLabel()

                    NavigationLink {
                        PrivateNotificationSetting()
                    } label: {
                        SectionNavigationLabel(imageName: "person.fill",
                                               title: "Notification.PrivateSettings",
                                               color: Color.App.color5)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)
                    .sandboxLabel()

                    NavigationLink {
                        GroupNotificationSetting()
                    } label: {
                        SectionNavigationLabel(imageName: "person.3.fill",
                                               title: "Notification.GroupSettings",
                                               color: Color.App.color2)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)
                    .sandboxLabel()

                    NavigationLink {
                        ChannelNotificationSetting()
                    } label: {
                        SectionNavigationLabel(imageName: "megaphone.fill",
                                               title: "Notification.ChannelSettings",
                                               color: Color.App.color3)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listSectionSeparator(.hidden)
                    .sandboxLabel()
                }
                .listRowSeparatorTint(Color.clear)
            }
        }
        .environment(\.defaultMinListRowHeight, 8)
        .font(.fSubheadline)
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .onChange(of: model) { _ in
            model.save()
        }
        .normalToolbarView(title: "Settings.notifictionSettings", type: PreferenceNavigationValue.self)
    }
}

struct PrivateNotificationSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Notification.Sound".bundleLocalized(), isOn: $model.notificationSettings.privateChat.sound)
                .tint(Color.App.accent)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
        .normalToolbarView(title: "Notification.PrivateSettings")
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct GroupNotificationSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Notification.Sound".bundleLocalized(), isOn: $model.notificationSettings.group.sound)
                .tint(Color.App.accent)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
        .normalToolbarView(title: "Notification.GroupSettings")
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct ChannelNotificationSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Notification.Sound".bundleLocalized(), isOn: $model.notificationSettings.channel.sound)
                .tint(Color.App.accent)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
        .normalToolbarView(title: "Notification.ChannelSettings")
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct SettingNotificationSection_Previews: PreviewProvider {
    static var previews: some View {
        SettingNotificationSection()
    }
}
