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

struct StartThreadContactPickerView: View {
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List {
            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
            if viewModel.searchedContacts.count == 0 {
                Button {
                    withAnimation {
                        viewModel.createConversationType = .normal
                        viewModel.showConversaitonBuilder.toggle()
                    }

                } label: {
                    Label("Contacts.createGroup", systemImage: "person.2")
                        .foregroundStyle(Color.main)
                }
                .listRowBackground(Color.bgColor)
                .listRowSeparatorTint(Color.dividerDarkerColor)

                Button {
                    viewModel.createConversationType = .channel
                    viewModel.showConversaitonBuilder.toggle()
                } label: {
                    Label("Contacts.createChannel", systemImage: "megaphone")
                        .foregroundStyle(Color.main)
                }
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
            }

            if viewModel.searchedContacts.count > 0 {
                StickyHeaderSection(header: "Contacts.searched")
                    .listRowInsets(.zero)
                ForEach(viewModel.searchedContacts) { contact in
                    ContactRowContainer(contact: contact, isSearchRow: true)
                }
            }

            StickyHeaderSection(header: "Contacts.sortLabel")
                .listRowInsets(.zero)
            ForEach(viewModel.contacts) { contact in
                ContactRowContainer(contact: contact, isSearchRow: false)
            }

            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 24)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 40)
        }
        .overlay(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("General.searchHere", text: $viewModel.searchContactString)
                    .frame(height: 48)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .frame(height: 48)
            .background(.ultraThinMaterial)
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
