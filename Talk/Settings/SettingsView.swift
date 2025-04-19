//
//  SettingsView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

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
                SettingNotificationSection()
                    .listRowSeparator(.hidden)
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                SettingLanguageSection()
                SettingSettingSection()
                SettingArchivesSection()
                if EnvironmentValues.isTalkTest {
                    SettingLogSection()
                        .sandboxLabel()
                    BlockedMessageSection()
                        .sandboxLabel()
                    // SettingCallHistorySection()
                    // SettingSavedMessagesSection()
                    // SettingCallSection()
                    AutomaticDownloadSection()
                        .sandboxLabel()
                    SettingAssistantSection()
                        .sandboxLabel()
                }
            }

            Group {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)

                SupportSection()

                VersionNumberView()
                if EnvironmentValues.isTalkTest {
                    TokenExpireTimeSection()
                        .sandboxLabel()
                    LoadTestsSection()
                        .sandboxLabel()
                    ManualConnectionManagementSection()
                        .sandboxLabel()
                }
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
                Task {
                    await container.reset()
                    showLoginSheet.toggle()
                }
            }
        }
    }

    @ViewBuilder var leadingViews: some View {
        if EnvironmentValues.isTalkTest {
            ToolbarButtonItem(imageName: "qrcode", hint: "General.edit", padding: 10)
                .sandboxLabel()
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
            .sandboxLabel()
            ToolbarButtonItem(imageName: "magnifyingglass", hint: "General.search", padding: 10) {}
                .sandboxLabel()
        }
    }
}

struct SettingSettingSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "gearshape.fill", title: "Settings.title", color: .gray, showDivider: false) {
            let value = PreferenceNavigationValue()
            navModel.append(value: value)
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
            .contentShape(Rectangle())
            .onTapGesture {
                let icon = Image(systemName: "person")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.App.textPrimary)
                let key = "General.copied".bundleLocalized()
                let message = "\(key) \(userName) "
                AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: message, messageColor: Color.App.textPrimary)
                UIPasteboard.general.string = userName
            }
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

                if case .setProfile(_) = event {
                    updateUI(user: AppState.shared.user)
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
        ListSectionButton(imageName: "doc.text.fill", title: "Settings.logs", color: .brown, showDivider: false) {
            let value = LogNavigationValue()
            navModel.append(value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct SettingArchivesSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "archivebox.fill", title: "Tab.archives", color: Color.App.color5, showDivider: false) {
            let value = ArchivesNavigationValue()
            navModel.append(value: value)
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
            navModel.append(value: value)
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

struct BlockedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "hand.raised.slash", title: "General.blocked", color: Color.App.red, showDivider: false) {
            withAnimation {
                let value = BlockedContactsNavigationValue()
                navModel.append(value: value)
            }
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct SupportSection: View {
    @EnvironmentObject var navModel: NavigationModel
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        ListSectionButton(imageName: "exclamationmark.bubble.fill", title: "Settings.about", color: Color.App.color2, showDivider: false) {
            let value = SupportNavigationValue()
            navModel.append(value: value)
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
    }
}

struct TokenExpireTimeSection: View {
    @EnvironmentObject var tokenManagerVM: TokenManager
    
    var body: some View {
        let secondToExpire = tokenManagerVM.secondToExpire.formatted(.number.precision(.fractionLength(0)))
        ListSectionButton(imageName: "key.fill", title: "The token will expire in \(secondToExpire) seconds", color: Color.App.color3, showDivider: false, shownavigationButton: false)
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.clear)
            .onAppear {
#if DEBUG
                tokenManagerVM.startTokenTimer()
#endif
            }
    }
}

struct SettingAssistantSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "person.fill", title: "Settings.assistants", color: Color.App.color1, showDivider: false) {
            let value = AssistantNavigationValue()
            navModel.append(value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct ManualConnectionManagementSection: View {
    @EnvironmentObject var navModel: NavigationModel
    
    var body: some View {
        ListSectionButton(imageName: "rectangle.connected.to.line.below", title: "Settings.manageConnection", color: Color.App.color3, showDivider: false) {
            let value = ManageConnectionNavigationValue()
            navModel.append(value: value)
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
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: AppState.shared.user?.name ?? "")))
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .padding(.trailing, 16)

            Text(verbatim: user?.name ?? "")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansSubheadline)
            Spacer()

            Button {
                let value = EditProfileNavigationValue()
                AppState.shared.objectsContainer.navVM.append(value: value)
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
                navModel.append(value: value)
            }
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
            .sandboxLabel()
        }
    }
}

struct VersionNumberView: View {

    var body: some View {
        HStack(spacing: 2) {
            Spacer()
            Text("Support.title")
            Text(String(format: String(localized: "Support.version", bundle: Language.preferedBundle), localVersionNumber))
            Spacer()
        }
        .foregroundStyle(Color.App.textSecondary)
        .font(.iransansCaption2)
        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        .listRowBackground(Color.App.bgSecondary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }

    private var localVersionNumber: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let splited = version.split(separator: ".")
        let numbers = splited.compactMap({Int($0)})
        let localStr = numbers.compactMap{$0.localNumber(locale: Language.preferredLocale)}
        return localStr.joined(separator: ".")
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
