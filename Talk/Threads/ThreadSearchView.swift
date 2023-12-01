//
//  ThreadSearchView.swift
//  Talk
//
//  Created by hamed on 11/11/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct ThreadSearchView: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @EnvironmentObject var contactsVM: ContactsViewModel

    var body: some View {
        if threadsVM.searchText.count > 0 {
            List {
                if contactsVM.searchedContacts.count > 0 {
                    StickyHeaderSection(header: "Contacts.searched", height: 4)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zero)
                }

                ForEach(contactsVM.searchedContacts.prefix(5)) { contact in
                    ContactRow(isInSelectionMode: .constant(false), contact: contact)
                        .listRowBackground(Color.App.bgPrimary)
                        .onTapGesture {
                            AppState.shared.openThread(contact: contact)
                        }
                }

                if threadsVM.searchedConversations.count > 0 {
                    StickyHeaderSection(header: "Tab.chats", height: 4)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zero)
                }

                ForEach(threadsVM.searchedConversations) { thread in
                    Button {
                        AppState.shared.objectsContainer.navVM.append(thread: thread)
                    } label: {
                        ThreadRow(isSelected: false, thread: thread)
                            .onAppear {
                                if self.threadsVM.searchedConversations.last == thread {
                                    threadsVM.loadMore()
                                }
                            }
                    }
                    .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
                    .listRowSeparatorTint(Color.App.separator)
                    .listRowBackground(thread.pin == true ? Color.App.bgTertiary : Color.App.bgPrimary)
                }
            }
            .background(MixMaterialBackground())
            .environment(\.defaultMinListRowHeight, 24)
            .animation(.easeInOut, value: AppState.shared.objectsContainer.contactsVM.searchedContacts.count)           
        }
    }
}

struct ThreadSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSearchView()
    }
}