//
//  ContainerSplitView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkViewModels

struct ContainerSplitView<SidebarView: View>: View {
    let sidebarView: SidebarView
    @Environment(\.horizontalSizeClass) var sizeClass
    let container: ObjectsContainer

    var body: some View {
        if sizeClass == .regular, UIDevice.current.userInterfaceIdiom == .pad {
            iPadStackContentView(sidebarView: sidebarView, container: container)
                .environmentObject(container.navVM)
        } else {
            iPhoneStackContentView(sidebarView: sidebarView, container: container)
                .environmentObject(container.navVM)
        }
    }
}

struct iPadStackContentView<Content: View>: View {
    let sidebarView: Content
    @EnvironmentObject var navVM: NavigationModel
    let container: ObjectsContainer
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var showSideBar: Bool = true
    let ipadSidebarWidth: CGFloat = 400
    let isIpad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    var maxWidth: CGFloat { sizeClass == .compact || !isIpad ? .infinity : ipadSidebarWidth }
    var maxComputed: CGFloat { min(maxWidth, ipadSidebarWidth) }

    var body: some View {
        HStack(spacing: 0) {
            sidebarView
                .toolbar(.hidden)
                .frame(width: showSideBar ? maxComputed : 0)

            NavigationStack(path: $navVM.paths) {
                NothingHasBeenSelectedView(contactsVM: container.contactsVM)
                    .navigationDestination(for: NavigationType.self) { value in
                        NavigationTypeView(type: value, container: container)
                    }
            }
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: showSideBar)
            .onReceive(NotificationCenter.closeSideBar.publisher(for: .closeSideBar)) { newVlaue in
                showSideBar.toggle()
            }
            .onReceive(navVM.$paths) { newValue in
                if UIDevice.current.userInterfaceIdiom == .pad, newValue.count == 0 {
                    showSideBar = true
                }
            }
        }
    }
}

struct iPhoneStackContentView<Content: View>: View {
    let sidebarView: Content
    @EnvironmentObject var navVM: NavigationModel
    let container: ObjectsContainer

    var body: some View {
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
                .ignoresSafeArea(.all)
                .navigationBarHidden(true)
//                ThreadView(viewModel: viewModel, threadsVM: container.threadsVM)
//                    .id(conversation.id) /// Needs to set here not inside the ThreadView to force Stack call onAppear when user clicks on another thread on ThreadRow
//                    .environmentObject(container.appOverlayVM)
//                    .environmentObject(viewModel)
//                    .environmentObject(container.threadsVM)
//                    .environmentObject(viewModel.audioRecoderVM)
//                    .environmentObject(viewModel.sendContainerViewModel)
//                    .environmentObject(viewModel.attachmentsViewModel)
//                    .environmentObject(viewModel.searchedMessagesViewModel)
//                    .environmentObject(viewModel.scrollVM)
//                    .environmentObject(viewModel.historyVM)
//                    .environmentObject(viewModel.uploadMessagesViewModel)
//                    .environmentObject(viewModel.unssetMessagesViewModel)
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
            ArchivesView(container: container)
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
        case .threadDetail(let model):
            ThreadDetailView()
                .id(model.viewModel.thread?.id)
                .environmentObject(model.viewModel)
        }
    }
}

struct ContainerSplitView_Previews: PreviewProvider {

    struct Preview: View {
        @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)

        var body: some View {
            ContainerSplitView(sidebarView: Image("gear"), container: container)
        }
    }

    static var previews: some View {
        Preview()
    }
}
