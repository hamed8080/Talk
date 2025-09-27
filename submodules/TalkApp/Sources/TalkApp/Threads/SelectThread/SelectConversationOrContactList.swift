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
    @StateObject var viewModel: ThreadOrContactPickerViewModel = .init()
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
            .environmentObject(viewModel)
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
            .background(Color.App.bgPrimary)
            .environment(\.colorScheme, isDarkModeEnable ? .dark : .light)
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchInSelectConversationOrContact()
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
            .init(title: "Tab.chats", view: AnyView(SelectConversationTab(onSelect: onSelect))),
            .init(title: "Tab.contacts", view: AnyView(SelectContactTab(onSelect: onSelect)))
        ]
    }
}

struct SearchInSelectConversationOrContact: View {
    @EnvironmentObject var viewModel: ThreadOrContactPickerViewModel

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
    @EnvironmentObject var viewModel: ThreadOrContactPickerViewModel
    var onSelect: (Conversation?, Contact?) -> Void
    @Environment(\.dismiss) var dismiss
    private var conversations: [CalculatedConversation] { viewModel.conversations.sorted(by: {$0.type == .selfThread && $1.type != .selfThread }) }

    var body: some View {
        ForwardConversationTableViewControllerWrapper(viewModel: viewModel, onSelect: onSelect)
    }
    
    var swiftUI: some View {
        List {
            ForEach(conversations) { conversation in
                ThreadRow(enableSwipeAction: false) {
                    onSelect(conversation.toStruct(), nil)
                    dismiss()
                }
                .environmentObject(conversation)
                .listRowBackground(Color.App.bgPrimary)
                .onAppear {
                    Task {
                        if conversation == conversations.last {
                            await viewModel.loadMore()
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if viewModel.conversationsLazyList.isLoading {
                SwingLoadingIndicator()
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.conversations.count)
        .animation(.easeInOut, value: viewModel.conversationsLazyList.isLoading)
    }
}

struct SelectContactTab: View {
    @EnvironmentObject var viewModel: ThreadOrContactPickerViewModel
    var onSelect: (Conversation?, Contact?) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var contactsVM = ContactsViewModel()

    var body: some View {
        List {
            ForEach(viewModel.contacts) { contact in
                ContactRow(contact: contact, isInSelectionMode: .constant(false), isInSearchMode: false)
                    .environment(\.showInviteButton, true)
                    .onTapGesture {
                        onSelect(nil, contact)
                        dismiss()
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .onAppear {
                        Task {
                            if contact == viewModel.contacts.last {
                                await viewModel.loadMoreContacts()
                            }
                        }
                    }
            }
        }
        .environmentObject(contactsVM)
        .safeAreaInset(edge: .top) {
            if viewModel.contactsLazyList.isLoading {
                SwingLoadingIndicator()
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.contacts.count)
        .animation(.easeInOut, value: viewModel.contactsLazyList.isLoading)
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
