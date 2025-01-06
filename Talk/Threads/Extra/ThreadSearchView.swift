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
    @EnvironmentObject var viewModel: ThreadsSearchViewModel

    var body: some View {
        if viewModel.isInSearchMode {
            List {
                StickyHeaderSection(header: "Tab.chats", height: 4)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.zero)
                if viewModel.searchedConversations.isEmpty {
                    noResulTextView
                }

                ForEach(viewModel.searchedConversations) { thread in
                    ThreadRow() {
                        AppState.shared.objectsContainer.navVM.append(thread: thread)
                    }
                    .environmentObject(thread.toClass())
                    .listRowInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
                    .listRowSeparatorTint(Color.App.dividerSecondary)
                    .listRowBackground(thread.pin == true ? Color.App.bgSecondary : Color.App.bgPrimary)
                    .onAppear {
                        Task {
                            if self.viewModel.searchedConversations.last == thread {
                                await viewModel.loadMore()
                            }
                        }
                    }
                }

                StickyHeaderSection(header: "Contacts.searched", height: 4)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.zero)
                if viewModel.searchedContacts.isEmpty {
                    noResulTextView
                }

                ForEach(viewModel.searchedContacts.prefix(5)) { contact in
                    ContactRow(contact: contact, isInSelectionMode: .constant(false))
                        .environment(\.showInviteButton, true)
                        .listRowInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 8)) /// We usre 16 leading due to in ThreadRow we have a yellow bar and it causes spacing in VStack to add 16 pixels, so we have to keep Contacts and Threads row in same alignmen.
                        .listRowBackground(Color.App.bgPrimary)
                        .onTapGesture {
                            AppState.shared.openThread(contact: contact)
                        }
                }
            }
            .listStyle(.plain)
            .background(MixMaterialBackground())
            .environment(\.defaultMinListRowHeight, 24)
            .animation(.easeInOut, value: viewModel.searchedContacts.count)
            .animation(.easeInOut, value: viewModel.searchedConversations.count)
            .gesture(dragToHideKeyboardGesture)
        }
    }
    
    private var dragToHideKeyboardGesture: some Gesture {
        DragGesture()
            .onChanged{ _ in
            hideKeyboard()
        }
    }

    private var noResulTextView: some View {
        HStack {
            Spacer()
            Text("General.noResult")
                .font(.iransansCaption2)
                .fontWeight(.light)
                .foregroundColor(Color.App.textSecondary)
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

struct ThreadSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSearchView()
    }
}
