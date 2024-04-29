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
import ChatModels
import TalkModels

struct ContactContentList: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @State private var type: StrictThreadTypeCreation = .p2p
    @State private var showBuilder = false
    @EnvironmentObject var builderVM: ConversationBuilderViewModel

    var body: some View {
        List {
            if viewModel.maxContactsCountInServer > 0, EnvironmentValues.isTalkTest {
                HStack(spacing: 4) {
                    Spacer()
                    Text("Contacts.total")
                        .font(.iransansBody)
                        .foregroundColor(.gray)
                    Text("\(viewModel.maxContactsCountInServer)")
                        .font(.iransansBoldBody)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .noSeparators()
            }

            if EnvironmentValues.isTalkTest {
                SyncView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

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

            if viewModel.searchedContacts.count > 0 || !viewModel.searchContactString.isEmpty {
                StickyHeaderSection(header: "Contacts.searched")
                    .listRowInsets(.zero)
                ForEach(viewModel.searchedContacts) { contact in
                    ContactRowContainer(isSearchRow: true)
                        .environmentObject(contact)
                }
                .padding()
            } else {
                ForEach(viewModel.contacts) { contact in
                    ContactRowContainer(isSearchRow: false)
                        .environmentObject(contact)
                }
                .padding()
                .listRowInsets(.zero)
            }
        }
        .listEmptyBackgroundColor(show: viewModel.contacts.isEmpty)
        .environment(\.defaultMinListRowHeight, 24)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.lazyList.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
           ContactListToolbar()
        }
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.lazyList.isLoading)
                .id(UUID())
        }
        .sheet(isPresented: $viewModel.showAddOrEditContactSheet) {
            AddOrEditContactView()
                .environmentObject(viewModel)
                .onDisappear {
                    /// Clearing the view for when the user cancels the sheet by dropping it down.
                    viewModel.successAdded = false
                    viewModel.showAddOrEditContactSheet = false
                    viewModel.addContact = nil
                    viewModel.editContact = nil
                }
        }
        .onReceive(builderVM.$dismiss) { newValue in
            if newValue == true {
                showBuilder = false
            }
        }
        .sheet(isPresented: $showBuilder, onDismiss: onDismissBuilder){
            ConversationBuilder()
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
}

struct ContactRowContainer: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @EnvironmentObject var contact: Contact
    let isSearchRow: Bool
    var separatorColor: Color {
        if !isSearchRow {
           return viewModel.contacts.last == contact ? Color.clear : Color.App.dividerPrimary
        } else {
            return viewModel.searchedContacts.last == contact ? Color.clear : Color.App.dividerPrimary
        }
    }

    var body: some View {
        ContactRow(isInSelectionMode: $viewModel.isInSelectionMode)
//            .id("\(isSearchRow ? "SearchRow" : "Normal")\(contact.id ?? 0)\(contact.blocked == true ? "Blocked" : "UnBlocked")")
            .animation(.spring(), value: viewModel.isInSelectionMode)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(separatorColor)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !viewModel.isInSelectionMode {
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
                    if viewModel.contacts.last == contact {
                        await viewModel.loadMore()
                    }
                }
            }
            .onTapGesture {
                if viewModel.isInSelectionMode {
                    viewModel.toggleSelectedContact(contact: contact)
                } else {
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
