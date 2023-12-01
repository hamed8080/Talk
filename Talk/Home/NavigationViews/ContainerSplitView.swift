//
//  ContainerSplitView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkViewModels
import ChatModels

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
                .frame(width: showSideBar ? maxComputed : 0)

            NavigationStack(path: $navVM.paths) {
                NothingHasBeenSelectedView(contactsVM: container.contactsVM)
                    .navigationDestination(for: NavigationType.self) { value in
                        NavigationTypeView(type: value, container: container)
                    }
            }
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: showSideBar)
            .onReceive(NotificationCenter.default.publisher(for: .closeSideBar)) { newVlaue in
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
        case .conversation(let conversation):
            if let viewModel = container.navVM.threadViewModel(threadId: conversation.id ?? 0) {
                ThreadView(viewModel: viewModel, threadsVM: container.threadsVM)
                    .environmentObject(container.appOverlayVM)
                    .environmentObject(viewModel)
            }
        case .contact(let contact):
            Text(contact.firstName ?? "")
                .environmentObject(container.appOverlayVM)
        case .detail(let detailViewModel):
            DetailView()
                .environmentObject(container.appOverlayVM)
                .environmentObject(detailViewModel)
                .environmentObject(container.threadsVM)
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
                .environmentObject(container.threadsVM)
        case .messageParticipantsSeen(let model):
            MessageParticipantsSeen(message: model.message)
        case .language(_):
            LanguageView(container: container)
        case .editProfile(_):
            EditProfileView()
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
