//
//  AdaptiveStackContentView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkViewModels

struct AdaptiveStackContentView<Content: View>: View {
    let sidebarView: Content
    @EnvironmentObject var navVM: NavigationModel
    let container: ObjectsContainer
    @State var showSideBar: Bool = true
    let ipadSidebarWidth: CGFloat = 400
    var maxWidth: CGFloat { sizeClassObserver.horizontalSizeClass == .compact || !isIpad ? .infinity : ipadSidebarWidth }
    var maxComputed: CGFloat { min(maxWidth, ipadSidebarWidth) }
    var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @EnvironmentObject var sizeClassObserver: SizeClassObserver
    
    var useSplitLayout: Bool {
        isIpad && sizeClassObserver.horizontalSizeClass == .regular
    }
    
    var body: some View {
        Group {
            if useSplitLayout {
                HStack(spacing: 0) {
                    sidebarView
                        .toolbar(.hidden)
                        .frame(width: showSideBar ? maxComputed : 0)
                    ipadNavigationStack
                }
            } else {
                iphoneNavigationStack
            }
        }
        .onReceive(NotificationCenter.closeSideBar.publisher(for: .closeSideBar)) { _ in
            showSideBar.toggle()
        }
        .onReceive(navVM.$paths) { newValue in
            if useSplitLayout && newValue.isEmpty {
                showSideBar = true
            }
        }
        .onAppear {
            if let appMode = AppSettingsModel.restore().isDarkModeEnabled {
                self.statusBarStyle.currentStyle = appMode == true ? .lightContent : .darkContent
            } else {
                self.statusBarStyle.currentStyle = colorScheme == .dark ? .lightContent : .darkContent
            }
        }
    }
    
    @ViewBuilder
    private var ipadNavigationStack: some View {
        NavigationStack(path: $navVM.paths) {
            NothingHasBeenSelectedView(contactsVM: container.contactsVM)
                .navigationDestination(for: NavigationType.self) { value in
                    NavigationTypeView(type: value, container: container)
                }
        }
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: showSideBar)
    }
    
    @ViewBuilder
    private var iphoneNavigationStack: some View {
        NavigationStack(path: $navVM.paths) {
            sidebarView
                .toolbar(.hidden)
                .navigationDestination(for: NavigationType.self) { value in
                    NavigationTypeView(type: value, container: container)
                }
        }
    }
}

struct NavigationTypeView: View {
    let type: NavigationType
    let container: ObjectsContainer
    
    var body: some View {
        switch type {
        case .threadViewModel(let viewModel):
            UIKitThreadViewWrapper(threadVM: viewModel.viewModel)
                .id(viewModel.threadId) ///
                .ignoresSafeArea(.all)
                .navigationBarHidden(true)
        case .preference(_):
            PreferenceView()
                .environmentObject(container.appOverlayVM)
        case .assistant(_):
            AssistantView()
                .environmentObject(container.appOverlayVM)
        case .log(_):
            LogView()
                .environmentObject(container.appOverlayVM)
        case .blockedContacts(_):
            BlockedContacts()
                .environmentObject(container.appOverlayVM)
        case .notificationSettings(_):
            NotificationSettings()
        case .automaticDownloadsSettings(_):
            AutomaticDownloadSettings()
        case .support(_):
            SupportView()
        case .archives(_):
            ArchivesView()
                .environmentObject(container.archivesVM)
        case .messageParticipantsSeen(let model):
            MessageParticipantsSeen(message: model.message)
            //                .environmentObject(model.threadVM)
        case .language(_):
            LanguageView(container: container)
        case .editProfile(_):
            EditProfileView()
        case .loadTests(_):
            LoadTestsView()
        case .manageConnection(_):
            ManuallyConnectionManagerView()
        case .threadDetail(let model):
            ThreadDetailView()
                .id(model.viewModel.thread?.id)
                .environmentObject(model.viewModel)
        case .manageSessions(_):
            ManageSessionsView()
        case .doubleTapSetting(_):
            DoubleTapSettingView()
        case .doubleTapEmojiPicker(_):
            DoubleTapEmojiPickerView()
        }
    }
}

struct ContainerSplitView_Previews: PreviewProvider {
    
    struct Preview: View {
        @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
        
        var body: some View {
            AdaptiveStackContentView(sidebarView: Image("gear"), container: container)
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
