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
                    .environmentObject(container.userConfigsVM)
                    .listRowBackground(Color.App.bgPrimary)
            }
            .listRowSeparator(.hidden)

            UserInformationSection()
                .listRowSeparator(.hidden)

            Group {
                StickyHeaderSection(header: "", height: 0.5)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                SavedMessageSection()
                SettingArchivesSection()
                SettingNotificationSection()
                    .listRowSeparator(.hidden)
                SettingSettingSection()
                SettingLanguageSection()
            }

            Group {
                SupportSection()

                VersionNumberView()
                if EnvironmentValues.isTalkTest {
                    TokenExpireTimeSection()
                        .sandboxLabel()
                    LoadTestsSection()
                        .sandboxLabel()
                    ManualConnectionManagementSection()
                        .sandboxLabel()
                    
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
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .padding(.bottom, ConstantSizes.bottomToolbarSize)
        .background(Color.App.bgPrimary.ignoresSafeArea())
        .environment(\.defaultMinListRowHeight, 0.5)
        .font(Font.normal(.subheadline))
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
        ListSectionButton(imageName: "gearshape.fill", title: "Settings.title", showDivider: false) {
            navModel.wrapAndPush(view: PreferenceView())
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
            StickyHeaderSection(header: "", height: 0.5)
                .listRowInsets(.zero)
        }

        if !userName.isEmpty {
            HStack {
                Image(systemName: "person")
                    .fontWeight(.semibold)
                    .font(Font.normal(.title))
                    .foregroundStyle(Color.App.textSecondary)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading) {
                    Text("Settings.userName")
                        .foregroundColor(Color.App.textSecondary)
                        .font(Font.normal(.caption))
                    TextField("", text: $userName)
                        .foregroundColor(Color.App.textPrimary)
                        .font(Font.normal(.subheadline))
                        .disabled(true)
                }
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
            .contentShape(Rectangle())
            .onTapGesture {
                let imageView = UIImageView(image: UIImage(systemName: "person"))
                let key = "Settings.userNameCopied".bundleLocalized()
                AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: imageView,
                                                                    message: key,
                                                                    messageColor: Color.App.textPrimaryUIColor!)
                UIPasteboard.general.string = userName
            }
        }

        if !phone.isEmpty {
            HStack {
                Image(systemName: "phone")
                    .fontWeight(.semibold)
                    .font(Font.normal(.title))
                    .foregroundStyle(Color.App.textSecondary)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading) {
                    Text("Settings.phoneNumber")
                        .foregroundColor(Color.App.textSecondary)
                        .font(Font.normal(.caption))
                    TextField("", text: $phone)
                        .foregroundColor(Color.App.textPrimary)
                        .font(Font.normal(.subheadline))
                        .disabled(true)
                }
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }

        if !bio.isEmpty {
            HStack {
                Image(systemName: "note.text")
                    .fontWeight(.semibold)
                    .font(Font.normal(.title))
                    .foregroundStyle(Color.App.textSecondary)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading) {
                    Text("Settings.bio")
                        .foregroundColor(Color.App.textSecondary)
                        .font(Font.normal(.caption))
                    Text(bio)
                        .foregroundColor(Color.App.textPrimary)
                        .font(Font.normal(.subheadline))
                        .disabled(true)
                        .lineLimit(20)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.clear)
        }
        Rectangle()
            .frame(width: 0, height: 0)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
            .listRowSeparatorTint(Color.clear)
            .listRowBackground(Color.clear)
            .onAppear {
                updateUI(user: AppState.shared.user)
            }
            .onReceive(NotificationCenter.user.publisher(for: .user)) { notif in
                let event = notif.object as? UserEventTypes
                if case let .user(response) = event, response.result != nil {
                    updateUI(user: response.result)
                }

                if case .setProfile(let updatedUser) = event {
                    AppState.shared.setUserBio(bio: updatedUser.result?.bio)
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
        ListSectionButton(imageName: "doc.text.fill", title: "Settings.logs", showDivider: false) {
            navModel.wrapAndPush(view: LogView())
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct SettingArchivesSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "archivebox.fill", title: "Tab.archives", showDivider: false) {
            navModel.wrapAndPush(view: ArchivesView(viewModel: AppState.shared.objectsContainer.archivesVM))
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct SettingLanguageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "globe", title: "Settings.language", showDivider: false, trailingView: selectedLanguage) {
            navModel.wrapAndPush(view: LanguageView(container: AppState.shared.objectsContainer))
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }

    var selectedLanguage: AnyView {
        let selectedLanguage = Language.languages.first(where: {$0.language == Locale.preferredLanguages[0]})?.text ?? ""
        let view = Text(selectedLanguage)
            .foregroundStyle(Color.App.accent)
            .font(Font.bold(.body))
        return AnyView(view)
    }
}

struct SavedMessageSection: View {

    var body: some View {
        ListSectionButton(imageName: "bookmark.fill", title: "Settings.savedMessage", showDivider: false) {
            Task {
                do {
                    let conversation = try await create()
                    storeInUserDefaults(conversation)
                    
                    let vc = ThreadViewController()
                    vc.viewModel = ThreadViewModel(thread: conversation)
                    
                    AppState.shared.objectsContainer.navVM.appendUIKit(vc: vc, conversation: conversation)
                } catch {
                    
                }
            }
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
    
    private func create() async throws -> Conversation {
        let title = "Thread.selfThread".bundleLocalized()
        let req = CreateThreadRequest(title: title, type: StrictThreadTypeCreation.selfThread.threadType)
        let conversation = try await CreateConversationRequester().create(req)
        
        return conversation
    }
    
    private func storeInUserDefaults(_ conversation: Conversation) {
        UserDefaults.standard.setValue(codable: conversation, forKey: "SELF_THREAD")
        UserDefaults.standard.synchronize()
    }
}

struct BlockedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "hand.raised.slash", title: "General.blocked", showDivider: false) {
            withAnimation {
                navModel.wrapAndPush(view: BlockedContacts())
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
        ListSectionButton(imageName: "exclamationmark.bubble.fill", title: "Settings.about", showDivider: false) {
            navModel.wrapAndPush(view: SupportView())
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)

        ListSectionButton(imageName: "arrow.backward.circle", title: "Settings.logout", showDivider: false) {
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
        ListSectionButton(imageName: "key.fill", title: "The token will expire in \(secondToExpire) seconds", showDivider: false, shownavigationButton: false)
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
        ListSectionButton(imageName: "person.fill", title: "Settings.assistants", showDivider: false) {
            navModel.wrapAndPush(view: AssistantView())
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct ManualConnectionManagementSection: View {
    @EnvironmentObject var navModel: NavigationModel
    
    var body: some View {
        ListSectionButton(imageName: "rectangle.connected.to.line.below", title: "Settings.manageConnection", showDivider: false) {
            navModel.wrapAndPush(view: ManuallyConnectionManagerView())
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct UserProfileView: View {
    @EnvironmentObject var container: ObjectsContainer
    @EnvironmentObject var userConfigsVM: UserConfigManagerVM
    var userConfig: UserConfig? { userConfigsVM.currentUserConfig }
    var user: User? { userConfig?.user }
    @EnvironmentObject var viewModel: SettingViewModel
    @EnvironmentObject var imageLoader: ImageLoaderViewModel

    var body: some View {
        HStack(spacing: 0) {
            Image(uiImage: imageLoader.image)
                .resizable()
                .id("\(user?.image ?? "")\(user?.id ?? 0)")
                .scaledToFill()
                .frame(width: 64, height: 64)
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: AppState.shared.user?.name ?? "")))
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .padding(.trailing, 16)

            Text(verbatim: user?.name ?? "")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.normal(.subheadline))
            Spacer()

            Button {
                AppState.shared.objectsContainer.navVM.wrapAndPush(view: EditProfileView())
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
            ListSectionButton(imageName: "testtube.2", title: "Load Tests", showDivider: false) {
                navModel.wrapAndPush(view: LoadTestsView())
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
            Text(String(format: "Support.version".bundleLocalized(), localVersionNumber))
            Spacer()
        }
        .foregroundStyle(Color.App.textSecondary)
        .font(Font.normal(.caption2))
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

struct SettingsTabWrapper: View {
    private var container: ObjectsContainer { AppState.shared.objectsContainer }
    
    var body: some View {
        SettingsView(container: container)
            .injectAllObjects()
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
