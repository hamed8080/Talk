//
//  StartThreadContactPickerView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import Combine
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct StartThreadContactPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ConversationBuilderViewModel

    var body: some View {
        NavigationStack {
            List {
                if viewModel.searchedContacts.count == 0 {
                    NavigationLink {
                        ConversationBuilder()
                            .navigationBarBackButtonHidden(true)
                            .onAppear {
                                Task {
                                    await viewModel.show(type: .privateGroup)
                                }
                            }

                    } label: {
                        Label("Contacts.createGroup".bundleLocalized(), systemImage: "person.2")
                            .foregroundStyle(Color.App.accent)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)
                    .font(Font.fBody)

                    NavigationLink {
                        ConversationBuilder()
                            .navigationBarBackButtonHidden(true)
                            .onAppear {
                                Task {
                                    await viewModel.show(type: .privateChannel)
                                }
                            }
                    } label: {
                        Label("Contacts.createChannel".bundleLocalized(), systemImage: "megaphone")
                            .foregroundStyle(Color.App.accent)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparator(.hidden)
                    .font(Font.fBody)
                }

                if viewModel.searchedContacts.count > 0 {
                    StickyHeaderSection(header: "Contacts.searched")
                        .listRowInsets(.zero)
                    ForEach(viewModel.searchedContacts) { contact in
                        BuilderContactRowContainer(contact: contact, isSearchRow: true)
                    }
                } else if viewModel.searchContactString.count > 0, viewModel.searchedContacts.isEmpty {
                    if viewModel.isTypinginSearchString {
                        ListLoadingView(isLoading: .constant(true))
                    } else if !viewModel.lazyList.isLoading {
                        Text("General.noResult")
                            .font(Font.fBody)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.App.textSecondary)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .listRowBackground(Color.App.bgPrimary)
                            .listRowSeparator(.hidden)
                            .id("General.noResult")
                    }
                }

                StickyHeaderSection(header: "Contacts.sortLabel")
                    .listRowInsets(.zero)
                ForEach(viewModel.contacts) { contact in
                    BuilderContactRowContainer(contact: contact, isSearchRow: false) {
                        /// On Tap
                        dismiss()
                    }
                }
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchContactString)
                        .frame(height: 48)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .submitLabel(.done)
                        .font(Font.fBody)
                }
                .frame(height: 48)
                .background(.ultraThinMaterial)
            }
            .overlay(alignment: .bottom) {
                ListLoadingView(isLoading: $viewModel.lazyList.isLoading)
                    .id(UUID())
            }
        }
        .environmentObject(viewModel)
        .environment(\.defaultMinListRowHeight, 24)
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.lazyList.isLoading)
        .onChange(of: viewModel.dismiss) { newValue in
            if newValue == true {
                dismiss()
            }
        }
        .onAppear {
            Task {
                viewModel.dismiss = false
                if viewModel.contacts.isEmpty {
                    await viewModel.getContacts()
                }
            }
        }
    }
}


struct StartThreadContactPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let contactVM = ContactsViewModel()
        StartThreadContactPickerView()
            .environmentObject(contactVM)
            .preferredColorScheme(.dark)
    }
}
