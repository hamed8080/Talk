//
//  ContactContentList.swift
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

struct ContactContentList: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @State private var type: StrictThreadTypeCreation = .p2p
    @State private var showBuilder = false
    @EnvironmentObject var builderVM: ConversationBuilderViewModel

    var body: some View {
        List {
            totalContactCountView
            syncView
                .sandboxLabel()
            creationButtons
            if viewModel.searchedContacts.count > 0 || !viewModel.searchContactString.isEmpty {
                searchViews
            } else {
                normalStateContacts
            }
        }
        .listEmptyBackgroundColor(show: viewModel.contacts.isEmpty)
        .environment(\.defaultMinListRowHeight, 0)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.lazyList.isLoading)
        .listStyle(.plain)
        .gesture(dragToHideKeyboardGesture)
        .safeAreaInset(edge: .top, spacing: 0) {
           ContactListToolbar()
        }
        .sheet(isPresented: $viewModel.showAddOrEditContactSheet, onDismiss: onAddOrEditDisappeared) {
            if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                AddOrEditContactView()
                    .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                    .environmentObject(viewModel)
                    .onDisappear {
                        onAddOrEditDisappeared()
                    }
            }
        }
        .onReceive(builderVM.$dismiss) { newValue in
            if newValue == true {
                showBuilder = false
            }
        }
        .sheet(isPresented: $showBuilder, onDismiss: onDismissBuilder){
            ConversationBuilder()
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .environmentObject(builderVM)
                .onAppear {
                    Task {
                        await builderVM.show(type: type)
                    }
                }
        }
    }

    private func onDismissBuilder() {
        Task {
            await builderVM.clear()
        }
    }

    private var dragToHideKeyboardGesture: some Gesture {
        DragGesture()
            .onChanged{ _ in
                hideKeyboard()
            }
    }

    @ViewBuilder
    private var searchViews: some View {
        StickyHeaderSection(header: "Contacts.searched")
            .listRowInsets(.zero)
        ForEach(viewModel.searchedContacts) { contact in
            ContactRowContainer(contact: .constant(contact), isSearchRow: true, enableSwipeAction: false)
                .id("SEARCH-ROW-IN-CONTACT-LIST\(contact.id ?? -1)")
                .environment(\.showInviteButton, true)
        }
        .padding()
        ListLoadingView(isLoading: $viewModel.lazyList.isLoading)
            .id(UUID())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
    }

    @ViewBuilder
    private var normalStateContacts: some View {
        ForEach(viewModel.contacts) { contact in
            ContactRowContainer(contact: .constant(contact), isSearchRow: false)
                .id("NORMAL-ROW-IN-CONTACT-LIST\(contact.id ?? -1)")
                .environment(\.showInviteButton, true)
        }
        .padding()
        .listRowInsets(.zero)
        ListLoadingView(isLoading: $viewModel.lazyList.isLoading)
            .id(UUID())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
    }

    @ViewBuilder
    private var creationButtons: some View {
        Button {
            type = .privateGroup
            showBuilder.toggle()
        } label: {
            Label("Contacts.createGroup".bundleLocalized(), systemImage: "person.2")
                .foregroundStyle(Color.App.accent)
        }
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)

        Button {
            type = .privateChannel
            showBuilder.toggle()
        } label: {
            Label("Contacts.createChannel".bundleLocalized(), systemImage: "megaphone")
                .foregroundStyle(Color.App.accent)
        }
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)

        Button {
            viewModel.showAddOrEditContactSheet.toggle()
            viewModel.animateObjectWillChange()
        } label: {
            Label("Contacts.addContact".bundleLocalized(), systemImage: "person.badge.plus")
                .foregroundStyle(Color.App.accent)
        }
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var syncView: some View {
        if EnvironmentValues.isTalkTest {
            SyncView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var totalContactCountView: some View {
        if viewModel.maxContactsCountInServer > 0, EnvironmentValues.isTalkTest {
            HStack(spacing: 4) {
                Spacer()
                Text("Contacts.total")
                    .font(.fBody)
                    .foregroundColor(.gray)
                Text("\(viewModel.maxContactsCountInServer)")
                    .font(.fBoldBody)
                Spacer()
            }
            .listRowBackground(Color.clear)
            .noSeparators()
            .sandboxLabel()
        }
    }

    private func onAddOrEditDisappeared() {
        /// Clearing the view for when the user cancels the sheet by dropping it down.
        viewModel.successAdded = false
        viewModel.showAddOrEditContactSheet = false
        viewModel.addContact = nil
        viewModel.editContact = nil
    }
}

struct ContactRowContainer: View {
    @Binding var contact: Contact
    @EnvironmentObject var viewModel: ContactsViewModel
    let isSearchRow: Bool
    var enableSwipeAction = true
    var separatorColor: Color {
        if !isSearchRow {
           return viewModel.contacts.last == contact ? Color.clear : Color.App.dividerPrimary
        } else {
            return viewModel.searchedContacts.last == contact ? Color.clear : Color.App.dividerPrimary
        }
    }

    var body: some View {
        ContactRow(contact: contact, isInSelectionMode: $viewModel.isInSelectionMode, isInSearchMode: isSearchRow)
            .animation(.spring(), value: viewModel.isInSelectionMode)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(separatorColor)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !enableSwipeAction {
                    EmptyView()
                } else if !viewModel.isInSelectionMode {
                    Button {
                        viewModel.editContact = contact
                        viewModel.showAddOrEditContactSheet.toggle()
                        viewModel.animateObjectWillChange()
                    } label: {
                        Label("General.edit", systemImage: "pencil")
                    }
                    .tint(Color.App.textSecondary)

                    let isBlocked = contact.blocked == true
                    Button {
                        if isBlocked, let contactId = contact.id {
                            viewModel.unblockWith(contactId)
                        } else {
                            viewModel.block(contact)
                        }
                    } label: {
                        Label(isBlocked ? "General.unblock" : "General.block", systemImage: isBlocked ? "hand.raised.slash.fill" : "hand.raised.fill")
                    }
                    .tint(Color.App.red)

                    Button {
                        viewModel.addToSelctedContacts(contact)
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                            DeleteContactView()
                                .environmentObject(viewModel)
                                .onDisappear {
                                    viewModel.removeToSelctedContacts(contact)
                                }
                        )
                    } label: {
                        Label("General.delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadMore(id: contact.id)
                }
            }
            .onTapGesture {
                if viewModel.isInSelectionMode {
                    viewModel.toggleSelectedContact(contact: contact)
                } else if contact.hasUser == true {
                    AppState.shared.openThread(contact: contact)
                }
            }
    }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        ContactContentList()
            .environmentObject(vm)
            .environmentObject(AppState.shared)
    }
}
