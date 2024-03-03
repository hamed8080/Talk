//
//  SettingsView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import Additive
import ChatCore

struct SettingsView: View {
    let container: ObjectsContainer
    @State private var showLoginSheet = false
    
    var body: some View {
        List {
            Group {
                UserProfileView()
                    .listRowBackground(Color.App.bgPrimary)
            }
            .listRowSeparator(.hidden)

            UserInformationSection()
                .listRowSeparator(.hidden)

            Group {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                SavedMessageSection()
                DarkModeSection()
                SettingLanguageSection()
                SettingLogSection()
                if EnvironmentValues.isTalkTest {
                    SettingSettingSection()
                    BlockedMessageSection()
                    // SettingCallHistorySection()
                    // SettingSavedMessagesSection()
                    // SettingCallSection()
                    SettingArchivesSection()
                    AutomaticDownloadSection()
                    SettingAssistantSection()
                }
                SettingNotificationSection()
                    .listRowSeparator(.hidden)
                LoadTestsSection()
            }

            Group {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)

                SupportSection()
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .background(Color.App.bgPrimary.ignoresSafeArea())
        .environment(\.defaultMinListRowHeight, 8)
        .font(.iransansSubheadline)
        .safeAreaInset(edge: .top, spacing: 0) {
            ToolbarView(
                title: "Tab.settings",
                leadingViews: leadingViews,
                centerViews: centerViews,
                trailingViews: trailingViews
            )
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginNavigationContainerView {
                container.reset()
                showLoginSheet.toggle()
            }
        }
    }

    @ViewBuilder var leadingViews: some View {
        if EnvironmentValues.isTalkTest {
            ToolbarButtonItem(imageName: "qrcode", hint: "General.edit", padding: 10)
        } else {
            Rectangle()
                .fill(Color.clear)
                .frame(width: 48, height: 48)
        }
    }

    var centerViews: some View {
        ConnectionStatusToolbar()
    }

    @ViewBuilder
    var trailingViews: some View {
        if EnvironmentValues.isTalkTest {
            ToolbarButtonItem(imageName: "plus.app", hint: "General.add", padding: 10) {
                withAnimation {
                    container.loginVM.resetState()
                    showLoginSheet.toggle()
                }
            }
            ToolbarButtonItem(imageName: "magnifyingglass", hint: "General.search", padding: 10) {}
        }
    }
}

struct SettingSettingSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "gearshape.fill", title: "Settings.title", color: .gray, showDivider: false) {
            let value = PreferenceNavigationValue()
            navModel.append(type: .preference(value), value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct UserInformationSection: View {
    @State var phone = ""
    @State var userName = ""
    @State var bio = ""

    var body: some View {
        if !userName.isEmpty || !phone.isEmpty || !bio.isEmpty {
            StickyHeaderSection(header: "", height: 10)
                .listRowInsets(.zero)
        }

        if !phone.isEmpty {
            VStack(alignment: .leading) {
                Text("Settings.phoneNumber")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption)
                TextField("", text: $phone)
                    .foregroundColor(Color.App.textPrimary)
                    .font(.iransansSubheadline)
                    .disabled(true)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }

        if !userName.isEmpty {
            VStack(alignment: .leading) {
                Text("Settings.userName")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption)
                TextField("", text: $userName)
                    .foregroundColor(Color.App.textPrimary)
                    .font(.iransansSubheadline)
                    .disabled(true)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }

        if !bio.isEmpty {
            VStack(alignment: .leading) {
                Text("Settings.bio")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption)
                Text(bio)
                    .foregroundColor(Color.App.textPrimary)
                    .font(.iransansSubheadline)
                    .disabled(true)
                    .lineLimit(20)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.clear)
        }
        EmptyView()
            .frame(width: 0, height: 0)
            .listRowSeparator(.hidden)
            .onAppear {
                updateUI(user: AppState.shared.user)
            }
            .onReceive(NotificationCenter.user.publisher(for: .user)) { notif in
                let event = notif.object as? UserEventTypes
                if case let .user(response) = event, response.result != nil {
                    updateUI(user: response.result)
                }
            }
            .onReceive(NotificationCenter.connect.publisher(for: .connect)) { notif in
                /// We use this to fetch the user profile image once the active instance is initialized.
                if let status = notif.object as? ChatState, status == .connected {
                    updateUI(user: AppState.shared.user)
                }
            }
    }

    private func updateUI(user: User?) {
        phone = user?.cellphoneNumber ?? ""
        userName = user?.username ?? ""
        bio = user?.chatProfileVO?.bio ?? ""
    }
}


struct PreferenceView: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Section("Tab.contacts") {
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Contacts.Sync.sync", isOn: $model.isSyncOn)
                    Text("Contacts.Sync.subtitle")
                        .foregroundColor(.gray)
                        .font(.iransansCaption3)
                }
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)
        }
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .onChange(of: model) { _ in
            model.save()
        }
        .normalToolbarView(title: "Settings.title", type: PreferenceNavigationValue.self)        
    }
}

struct SettingCallHistorySection: View {
    var body: some View {
        Section {
            NavigationLink {} label: {
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.green)
                    Text("Settings.calls")
                }
            }
        }
    }
}

struct SettingSavedMessagesSection: View {
    var body: some View {
        NavigationLink {} label: {
            HStack {
                Image(systemName: "bookmark")
                    .foregroundColor(.purple)
                Text("Settings.savedMessage")
            }
        }
    }
}

struct SettingLogSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        if EnvironmentValues.isTalkTest {
            ListSectionButton(imageName: "doc.text.fill", title: "Settings.logs", color: .brown, showDivider: false) {
                let value = LogNavigationValue()
                navModel.append(type: .log(value), value: value)
            }
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }
    }
}

struct SettingArchivesSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "archivebox.fill", title: "Tab.archives", color: Color.App.color5, showDivider: false) {
            let value = ArchivesNavigationValue()
            navModel.append(type: .archives(value), value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct SettingLanguageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "globe", title: "Settings.language", color: Color.App.red, showDivider: false, trailingView: selectedLanguage) {
            let value = LanguageNavigationValue()
            navModel.append(type: .language(value), value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }

    var selectedLanguage: AnyView {
        let selectedLanguage = Language.languages.first(where: {$0.language == Locale.preferredLanguages[0]})?.text ?? ""
        let view = Text(selectedLanguage)
            .foregroundStyle(Color.App.accent)
            .font(.iransansBoldBody)
        return AnyView(view)
    }
}

struct SavedMessageSection: View {

    var body: some View {
        ListSectionButton(imageName: "bookmark.fill", title: "Settings.savedMessage", color: Color.App.color5, showDivider: false) {
            AppState.shared.openSelfThread()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

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
                    .foregroundColor(.white)
            }
            .frame(width: 28, height: 28)
            .background(Color.App.color1)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            Toggle("Settings.darkModeEnabled", isOn: $isDarkModeEnabled)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }
        .padding(.horizontal)
        .toggleStyle(MyToggleStyle())
        .listSectionSeparator(.hidden)
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
        .onChange(of: isDarkModeEnabled) { value in
            var model = AppSettingsModel.restore()
            model.isDarkModeEnabled = value
            model.save()
        }
        .onAppear {
            isDarkModeEnabled = currentSystemScheme == .dark
        }
    }
}

struct BlockedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "hand.raised.slash", title: "General.blocked", color: Color.App.red, showDivider: false) {
            withAnimation {
                let value = BlockedContactsNavigationValue()
                navModel.append(type: .blockedContacts(value), value: value)
            }
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct SupportSection: View {
    @EnvironmentObject var tokenManagerVM: TokenManager
    @EnvironmentObject var navModel: NavigationModel
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        ListSectionButton(imageName: "exclamationmark.bubble.fill", title: "Settings.about", color: Color.App.color2, showDivider: false) {
            let value = SupportNavigationValue()
            navModel.append(type: .support(value), value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)

        ListSectionButton(imageName: "arrow.backward.circle", title: "Settings.logout", color: Color.App.red, showDivider: false) {
            container.appOverlayVM.dialogView = AnyView(LogoutDialogView())
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)

        if EnvironmentValues.isTalkTest {
            let secondToExpire = tokenManagerVM.secondToExpire.formatted(.number.precision(.fractionLength(0)))
            ListSectionButton(imageName: "key.fill", title: "The token will expire in \(secondToExpire) seconds", color: Color.App.color3, showDivider: false, shownavigationButton: false)
                .listRowInsets(.zero)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.clear)
                .onAppear {
                    tokenManagerVM.startTokenTimer()
                }
        }
    }
}

struct SettingAssistantSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "person.fill", title: "Settings.assistants", color: Color.App.color1, showDivider: false) {
            let value = AssistantNavigationValue()
            navModel.append(type: .assistant(value), value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct UserProfileView: View {
    @EnvironmentObject var container: ObjectsContainer
    var userConfig: UserConfig? { container.userConfigsVM.currentUserConfig }
    var user: User? { userConfig?.user }
    @EnvironmentObject var viewModel: SettingViewModel
    @EnvironmentObject var imageLoader: ImageLoaderViewModel

    var body: some View {
        HStack(spacing: 0) {
            Image(uiImage: imageLoader.image)
                .resizable()
                .id("\(userConfig?.user.image ?? "")\(userConfig?.user.id ?? 0)")
                .scaledToFill()
                .frame(width: 64, height: 64)
                .background(String.getMaterialColorByCharCode(str: AppState.shared.user?.name ?? ""))
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .padding(.trailing, 16)

            Text(verbatim: user?.name ?? "")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansSubheadline)
            Spacer()

            Button {
                let value = EditProfileNavigationValue()
                AppState.shared.objectsContainer.navVM.append(type: .editProfile(value), value: value)
            } label: {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 48, height: 48)
                    .background(.ultraThickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
                    .overlay(alignment: .center) {
                        Image("ic_edit")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.App.textSecondary)
                    }
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        .frame(height: 70)
    }
}

struct LoadTestsSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        if EnvironmentValues.isTalkTest {
            ListSectionButton(imageName: "testtube.2", title: "Load Tests", color: Color.App.color4, showDivider: false) {
                let value = LoadTestsNavigationValue()
                navModel.append(type: .loadTests(value), value: value)
            }
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }
    }
}

struct SettingsMenu_Previews: PreviewProvider {
    @State static var dark: Bool = false
    @State static var show: Bool = false
    @State static var showBlackView: Bool = false
    @StateObject static var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
    static var vm = SettingViewModel()

    static var previews: some View {
        SettingsView(container: container)
            .environmentObject(vm)
            .environmentObject(container)
            .environmentObject(TokenManager.shared)
            .environmentObject(AppState.shared)
            .onAppear {
                let user = User(
                    cellphoneNumber: "+98 936 916 1601",
                    email: "h.hosseini.co@gmail.com",
                    image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png",
                    name: "Hamed Hosseini",
                    username: "hamed8080"
                )
                container.userConfigsVM.onUser(user)
            }
    }
}
