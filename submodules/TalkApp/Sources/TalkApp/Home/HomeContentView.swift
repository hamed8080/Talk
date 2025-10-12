//
//  HomeContentView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels
import ActionableContextMenu

public struct HomeContentView: View {
    let container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
    
    public init() {}

    public var body: some View {
        ZStack {
            LoginHomeView(container: container)
                .environmentObject(container.loginVM)
                .environmentObject(container.tokenVM)
                .environmentObject(AppState.shared)
            SplitView(container: container)
                .environmentObject(AppState.shared)
                .environmentObject(container)
                .environmentObject(container.navVM)
                .environmentObject(container.settingsVM)
                .environmentObject(container.contactsVM)
                .environmentObject(container.threadsVM)
                .environmentObject(container.loginVM)
                .environmentObject(container.tokenVM)
                .environmentObject(container.tagsVM)
                .environmentObject(container.userConfigsVM)
                .environmentObject(container.logVM)
                .environmentObject(container.audioPlayerVM)
                .environmentObject(container.conversationBuilderVM)
                .environmentObject(container.userProfileImageVM)
                .environmentObject(container.banVM)
                .environmentObject(container.sizeClassObserver)
        }
        .modifier(ColorSchemeModifier())
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        .contextMenuContainer()
    }
}

struct LoginHomeView: View {
    let container: ObjectsContainer
    @EnvironmentObject var tokenManager: TokenManager

    var body: some View {
        if tokenManager.isLoggedIn == false {
            LoginNavigationContainerView()
        }
    }
}

struct SplitView: View {
    let container: ObjectsContainer
    @State private var isLoggedIn: Bool = TokenManager.shared.isLoggedIn

    @ViewBuilder var body: some View {
        Group {
            if isLoggedIn {
                SplitViewContent(container: container)
            }
        }
        .animation(.easeInOut, value: isLoggedIn)
        .addURLViewModifier()
        .overlay {
            let appOverlayVM = container.appOverlayVM
            AppOverlayView(onDismiss: onDismiss) {
                AppOverlayFactory()
            }
            .environmentObject(appOverlayVM)
        }
        .overlay {
            BanOverlayView()
        }
        .onReceive(TokenManager.shared.$isLoggedIn) { isLoggedIn in
            if self.isLoggedIn != isLoggedIn {
                self.isLoggedIn = isLoggedIn
            }
        }
    }

    private func onDismiss() {
        container.appOverlayVM.clear()
    }
}

struct SplitViewContent: View {
    let container: ObjectsContainer
    var body: some View {
        AdaptiveStackContentView(sidebarView: sidebarViews, container: container)
                }

    var sidebarViews: some View {
        TabContainerView(
            iPadMaxAllowedWidth: 400,
            selectedId: "Tab.chats",
            tabs: [
                .init(
                    tabContent: ContactContentList(),
                    contextMenus: Button("Contact Context Menu") {},
                    title: "Tab.contacts",
                    iconName: "person.crop.circle"
                ),
                .init(
                    tabContent: EmptyView(),
                    contextMenus: Button("Thread Context Menu") {},
                    title: "Tab.chats",
                    iconName: "ellipsis.message.fill"
                ),
                .init(
                    tabContent: SettingsView(container: container),
                    tabImageView: SettingProfileButton(),
                    contextMenus: Button("Setting Context Menu") {},
                    title: "Tab.settings"
                )
            ],
            config: .init(alignment: .bottom, scrollable: false), onSelectedTab: { selectedTabId in
                if selectedTabId != "Tab.chats", !AppState.shared.objectsContainer.searchVM.searchText.isEmpty {                    
                    /// We call closedSearchUI because the searchText = "" sink will be called on a New Task,
                    /// So, we have to call it synchronosly to froce the tab wait until all searches are clear and then computed property
                    /// isInSearchMode turn into false then the new tab if its a contact tab it will see this value as false.
                    AppState.shared.objectsContainer.searchVM.closedSearchUI()
                    AppState.shared.objectsContainer.searchVM.searchText = ""
                    AppState.shared.objectsContainer.contactsVM.searchContactString = ""
                    NotificationCenter.cancelSearch.post(name: .cancelSearch, object: true)
                }
            }
        )
        .background(Color.App.bgPrimary)
    }
}

#if DEBUG
struct HomePreview: View {
    @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
    var body: some View {
        HomeContentView()
            .task {
                AppState.shared.connectionStatus = .connected
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
                for thread in MockData.generateThreads(count: 10) {
                    await container.threadsVM.calculateAppendSortAnimate(thread)
                }
                container.animateObjectWillChange()
            }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomePreview()
    }
}
#endif
