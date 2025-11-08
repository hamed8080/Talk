//
//  SelectConversationOrContactList.swift
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

struct SelectConversationOrContactList: View {
    let viewModel: ThreadOrContactPickerViewModel = .init()
    var onSelect: (Conversation?, Contact?) -> Void
    @Environment(\.dismiss) var dismiss
    @State var selectedTabId: Int = 0
    @State private var tabs: [TalkUI.Tab] = []
    @Environment(\.colorScheme) private var colorScheme

    init(onSelect: @escaping (Conversation?, Contact?) -> Void) {
        self.onSelect = onSelect
    }

    var body: some View {
        CustomTabView(selectedTabIndex: $selectedTabId, tabs: tabs)
            .frame(minWidth: 300, maxWidth: .infinity)/// We have to use a fixed minimum width for a bug tabs goes to the end.
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
            .background(Color.App.bgPrimary)
            .environment(\.colorScheme, isDarkModeEnable ? .dark : .light)
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchInSelectConversationOrContact(viewModel: viewModel)
                    .environment(\.colorScheme, isDarkModeEnable ? .dark : .light)
                    .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                    .environmentObject(viewModel)
            }
            .onAppear {
                makeTabs()
            }
            .onDisappear {
                viewModel.cancelObservers()
            }
    }
    
    private var isDarkModeEnable: Bool {
        AppSettingsModel.restore().isDarkModeEnabled ?? false || colorScheme == .dark
    }

    private func makeTabs() {
        tabs = [
            .init(title: "Tab.chats", view: AnyView(SelectConversationTab(viewModel: viewModel, onSelect: onSelect))),
            .init(title: "Tab.contacts", view: AnyView(SelectContactTab(viewModel: viewModel, onSelect: onSelect)))
        ]
    }
}

struct SearchInSelectConversationOrContact: View {
    @StateObject var viewModel: ThreadOrContactPickerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchText)
                .frame(height: 48)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .font(.fSubheadline)
                .submitLabel(.done)
        }
        .background(.ultraThinMaterial)
    }
}

struct SelectConversationTab: View {
    let viewModel: ThreadOrContactPickerViewModel
    var onSelect: (Conversation?, Contact?) -> Void

    var body: some View {
        ForwardConversationTableViewControllerWrapper(viewModel: viewModel, onSelect: onSelect)
            .ignoresSafeArea(.all)
    }
}

struct SelectContactTab: View {
    let viewModel: ThreadOrContactPickerViewModel
    var onSelect: (Conversation?, Contact?) -> Void

    var body: some View {
        ForwardContactTableViewControllerWrapper(viewModel: viewModel, onSelect: onSelect)
            .ignoresSafeArea(.all)
    }
}

struct SelectThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = ThreadsViewModel()
        SelectConversationOrContactList { (conversation, contact) in
        }
        .onAppear {}
        .environmentObject(vm)
        .environmentObject(appState)
    }
}
