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
import Combine

struct ContactContentList: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @State private var type: StrictThreadTypeCreation = .p2p
    @State private var showBuilder = false
    @EnvironmentObject var builderVM: ConversationBuilderViewModel

    var body: some View {
        ContactsViewControllerWrapper(viewModel: viewModel)
            .safeAreaInset(edge: .top, spacing: 0) {
                ContactListToolbar()
            }
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
                    Task {
                        try await AppState.shared.objectsContainer.navVM.openThread(contact: contact)
                    }
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
