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
            navModel.appendPreference()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct UserInformationSection: View {
    @EnvironmentObject var navModel: NavigationModel
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
                TextField("", text: $phone)
                    .foregroundColor(Color.App.textPrimary)
                    .font(.iransansSubheadline)
                    .disabled(true)
                Text("Settings.phoneNumber")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }

        if !userName.isEmpty {
            VStack(alignment: .leading) {
                TextField("", text: $userName)
                    .foregroundColor(Color.App.textPrimary)
                    .font(.iransansSubheadline)
                    .disabled(true)
                Text("Settings.userName")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }

        if !bio.isEmpty {
            VStack(alignment: .leading) {
                Text(bio)
                    .foregroundColor(Color.App.textPrimary)
                    .font(.iransansSubheadline)
                    .disabled(true)
                    .lineLimit(20)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                Text("Settings.bio")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.clear)
        }
        EmptyView()
            .frame(width: 0, height: 0)
            .listRowSeparator(.hidden)
            .onAppear {
                let user = AppState.shared.user
                phone = user?.cellphoneNumber ?? ""
                userName = user?.username ?? ""
                bio = user?.chatProfileVO?.bio ?? ""
            }
            .onReceive(NotificationCenter.default.publisher(for: .connect)) { notification in
                /// We use this to fetch the user profile image once the active instance is initialized.
                if let status = notification.object as? ChatState, status == .connected {
                    let user = AppState.shared.user
                    phone = user?.cellphoneNumber ?? ""
                    userName = user?.username ?? ""
                    bio = user?.chatProfileVO?.bio ?? ""
                }
            }
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
        .navigationTitle("Settings.title")
        .navigationBarBackButtonHidden(true)
        .onChange(of: model) { _ in
            model.save()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: PreferenceNavigationValue.self)
                }
            }
        }
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
                navModel.appendLog()
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
            navModel.appendArhives()
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
            navModel.appendLanguage()
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
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "bookmark.fill", title: "Settings.savedMessage", color: Color.App.color5, showDivider: false) {
            ChatManager.activeInstance?.conversation.create(.init(title: String(localized: .init("Thread.selfThread")), type: .selfThread))
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
                navModel.appendBlockedContacts()
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
        ListSectionButton(imageName: "exclamationmark.bubble.fill", title: "Settings.support", color: Color.App.color2, showDivider: false) {
            navModel.appendSupport()
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
            navModel.appendAssistant()
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
    @State var imageLoader: ImageLoaderViewModel?

    var body: some View {
        HStack(spacing: 0) {
            let config = ImageLoaderConfig(url: user?.image ?? "", userName: AppState.shared.user?.name)
            ImageLoaderView(imageLoader: imageLoader ?? .init(config: config))
                .id("\(userConfig?.user.image ?? "")\(userConfig?.user.id ?? 0)")
                .frame(width: 64, height: 64)
                .background(Color.App.color1.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .padding(.trailing, 16)

            Text(verbatim: user?.name ?? "")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansSubheadline)
            Spacer()

            Button {
                AppState.shared.objectsContainer.navVM.appendEditProfile()
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
        .onReceive(NotificationCenter.default.publisher(for: .user)) { notification in
            let event = notification.object as? UserEventTypes
            if imageLoader?.isImageReady == false, case let .user(response) = event, let user = response.result {
                let config = ImageLoaderConfig(url: user.image ?? "", size: .LARG, userName: user.name)
                imageLoader = .init(config: config)
                imageLoader?.fetch()
            }
        }
        .onAppear {
            let config = ImageLoaderConfig(url: user?.image ?? "", size: .LARG, userName: user?.name)
            imageLoader = .init(config: config)
            imageLoader?.fetch()
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
